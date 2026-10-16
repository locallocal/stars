import 'dart:io';

import 'package:stars/domain/models/models.dart';

typedef SkillCatalogDnsLookup =
    Future<List<InternetAddress>> Function(String host);

final class SkillCatalogEndpointPolicy {
  SkillCatalogEndpointPolicy({SkillCatalogDnsLookup? dnsLookup})
    : _dnsLookup = dnsLookup ?? InternetAddress.lookup;

  final SkillCatalogDnsLookup _dnsLookup;

  Future<void> validate(Uri uri) async {
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw const SkillInstallException('Skill 在线目录和下载地址必须是无凭据的 HTTPS URL。');
    }
    final normalized = uri.host.toLowerCase();
    if (normalized == 'localhost' || normalized.endsWith('.localhost')) {
      throw const SkillInstallException('Skill 在线目录不能指向本机地址。');
    }
    List<InternetAddress> addresses;
    try {
      addresses = await _dnsLookup(
        uri.host,
      ).timeout(const Duration(seconds: 10));
    } on Object {
      throw const SkillInstallException('无法解析 Skill 在线目录主机。');
    }
    if (addresses.isEmpty || addresses.any(_isNonPublic)) {
      throw const SkillInstallException('Skill 在线目录不能指向非公网地址。');
    }
  }

  bool _isNonPublic(InternetAddress address) {
    final bytes = address.rawAddress;
    if (address.type == InternetAddressType.IPv4 && bytes.length == 4) {
      return _isNonPublicV4(bytes);
    }
    if (address.type == InternetAddressType.IPv6 && bytes.length == 16) {
      final allZero = bytes.every((byte) => byte == 0);
      final loopback =
          bytes.take(15).every((byte) => byte == 0) && bytes.last == 1;
      final uniqueLocal = (bytes[0] & 0xfe) == 0xfc;
      final linkLocal = bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0x80;
      final multicast = bytes[0] == 0xff;
      final documentation =
          bytes[0] == 0x20 &&
          bytes[1] == 0x01 &&
          bytes[2] == 0x0d &&
          bytes[3] == 0xb8;
      final ipv4Mapped =
          bytes.take(10).every((byte) => byte == 0) &&
          bytes[10] == 0xff &&
          bytes[11] == 0xff;
      return allZero ||
          loopback ||
          uniqueLocal ||
          linkLocal ||
          multicast ||
          documentation ||
          (ipv4Mapped && _isNonPublicV4(bytes.sublist(12)));
    }
    return true;
  }

  bool _isNonPublicV4(List<int> bytes) {
    final first = bytes[0];
    final second = bytes[1];
    final third = bytes[2];
    return first == 0 ||
        first == 10 ||
        first == 127 ||
        first >= 224 ||
        (first == 100 && second >= 64 && second <= 127) ||
        (first == 169 && second == 254) ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 &&
            (second == 168 || (second == 0 && (third == 0 || third == 2)))) ||
        (first == 198 &&
            (second == 18 || second == 19 || second == 51 && third == 100)) ||
        (first == 203 && second == 0 && third == 113);
  }
}
