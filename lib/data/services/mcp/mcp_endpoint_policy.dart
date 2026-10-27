import 'dart:io';

import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/services/mcp_configuration_policy.dart';

typedef McpHostResolver = Future<List<InternetAddress>> Function(String host);

final class McpEndpointPolicy {
  McpEndpointPolicy({McpHostResolver? resolver})
    : _resolver = resolver ?? InternetAddress.lookup;

  final McpHostResolver _resolver;

  Future<List<InternetAddress>> validate(Uri endpoint) async {
    if (endpoint.scheme.toLowerCase() != 'https') {
      throw const McpException(
        'mcp_https_required',
        message: 'Remote MCP endpoints must use HTTPS.',
      );
    }
    if (endpoint.host.isEmpty ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.fragment.isNotEmpty) {
      throw const McpException(
        'mcp_invalid_endpoint',
        message: 'The MCP endpoint URI is invalid.',
      );
    }

    if (McpConfigurationPolicy.endpointContainsCredentials(endpoint)) {
      throw const McpException('mcp_credentials_in_configuration');
    }
    final host = endpoint.host.toLowerCase();
    if (host == 'localhost' ||
        host.endsWith('.localhost') ||
        host.endsWith('.local')) {
      throw const McpException(
        'mcp_private_endpoint_blocked',
        message: 'Local MCP endpoints are disabled in this release.',
      );
    }

    final literal = InternetAddress.tryParse(host);
    if (literal != null) {
      _rejectNonPublicAddress(literal);
      return [literal];
    }

    final List<InternetAddress> addresses;
    try {
      addresses = await _resolver(host);
    } on SocketException {
      throw const McpException(
        'mcp_dns_failed',
        message: 'The MCP server host could not be resolved.',
      );
    }
    if (addresses.isEmpty) {
      throw const McpException(
        'mcp_dns_failed',
        message: 'The MCP server host did not resolve to an address.',
      );
    }
    for (final address in addresses) {
      _rejectNonPublicAddress(address);
    }
    return List<InternetAddress>.unmodifiable(addresses);
  }

  void _rejectNonPublicAddress(InternetAddress address) {
    if (!_isPublicAddress(address)) {
      throw const McpException(
        'mcp_private_endpoint_blocked',
        message: 'Private and local MCP endpoints are disabled.',
      );
    }
  }

  bool _isPublicAddress(InternetAddress address) {
    if (address.type == InternetAddressType.IPv4) {
      final bytes = address.rawAddress;
      final first = bytes[0];
      final second = bytes[1];
      if (first == 0 ||
          first == 10 ||
          first == 127 ||
          first >= 224 ||
          (first == 100 && second >= 64 && second <= 127) ||
          (first == 169 && second == 254) ||
          (first == 172 && second >= 16 && second <= 31) ||
          (first == 192 && second == 168) ||
          (first == 192 && second == 0) ||
          (first == 192 && second == 0 && bytes[2] == 2) ||
          (first == 198 && (second == 18 || second == 19)) ||
          (first == 198 && second == 51 && bytes[2] == 100) ||
          (first == 203 && second == 0 && bytes[2] == 113)) {
        return false;
      }
      return true;
    }

    final source = address.address.toLowerCase();
    if (source == '::' ||
        source == '::1' ||
        source.startsWith('fc') ||
        source.startsWith('fd') ||
        RegExp(r'^fe[89ab]').hasMatch(source) ||
        source.startsWith('ff') ||
        source.startsWith('2001:db8:')) {
      return false;
    }
    if (source.startsWith('::ffff:')) {
      final mapped = InternetAddress.tryParse(source.substring(7));
      return mapped != null && _isPublicAddress(mapped);
    }
    return true;
  }
}
