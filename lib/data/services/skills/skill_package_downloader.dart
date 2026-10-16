import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:stars/data/services/skills/skill_catalog_endpoint_policy.dart';
import 'package:stars/domain/models/models.dart';

typedef SkillPackageHttpClientFactory = HttpClient Function();
typedef SkillPackageFetcher =
    Future<List<int>> Function(
      Uri uri,
      int? maxBytes,
      AgentCancellationToken cancellationToken,
    );

/// HTTPS metadata reads and streamed package downloads.
///
/// Metadata reads are bounded; package downloads have no byte limit. Injected
/// fetchers receive a null limit for packages.
final class SkillPackageDownloader {
  SkillPackageDownloader({
    required SkillCatalogEndpointPolicy endpointPolicy,
    SkillPackageHttpClientFactory? httpClientFactory,
    SkillPackageFetcher? fetcher,
  }) : _endpointPolicy = endpointPolicy,
       _httpClientFactory = httpClientFactory ?? HttpClient.new,
       _fetcher = fetcher;

  static const int maxRedirects = 3;
  static const _timeout = Duration(seconds: 10);

  final SkillCatalogEndpointPolicy _endpointPolicy;
  final SkillPackageHttpClientFactory _httpClientFactory;
  final SkillPackageFetcher? _fetcher;

  Future<List<int>> fetch(
    Uri uri,
    int maxBytes,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    await _endpointPolicy.validate(uri);
    final fetcher = _fetcher;
    final List<int> bytes;
    if (fetcher != null) {
      bytes = await fetcher(uri, maxBytes, cancellationToken);
    } else {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in _read(uri, maxBytes, cancellationToken)) {
        builder.add(chunk);
      }
      bytes = builder.takeBytes();
    }
    cancellationToken.throwIfCancelled();
    if (bytes.length > maxBytes) {
      throw const SkillInstallException('Skill 下载内容超过大小限制。');
    }
    return bytes;
  }

  /// Writes a package directly to disk with stream backpressure.
  /// The caller owns the temporary file and its cleanup on failure.
  Future<void> downloadToFile(
    Uri uri,
    File destination,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    await _endpointPolicy.validate(uri);
    final fetcher = _fetcher;
    if (fetcher != null) {
      final bytes = await fetcher(uri, null, cancellationToken);
      cancellationToken.throwIfCancelled();
      await destination.writeAsBytes(bytes, flush: true);
    } else {
      final output = await destination.open(mode: FileMode.write);
      try {
        await for (final chunk in _read(uri, null, cancellationToken)) {
          await output.writeFrom(chunk);
        }
        await output.flush();
      } finally {
        await output.close();
      }
    }
    cancellationToken.throwIfCancelled();
  }

  Stream<List<int>> _read(
    Uri initialUri,
    int? maxBytes,
    AgentCancellationToken cancellationToken,
  ) async* {
    final client = _httpClientFactory();
    client.connectionTimeout = _timeout;
    var uri = initialUri;
    try {
      for (var redirectCount = 0; ; redirectCount += 1) {
        cancellationToken.throwIfCancelled();
        await _endpointPolicy.validate(uri);
        final request = await client.getUrl(uri).timeout(_timeout);
        request.followRedirects = false;
        final response = await request.close().timeout(_timeout);
        if (_isRedirect(response.statusCode)) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          await response.drain<void>().timeout(_timeout);
          if (location == null || redirectCount >= maxRedirects) {
            throw const SkillInstallException('Skill 下载重定向无效或次数过多。');
          }
          uri = uri.resolve(location);
          continue;
        }
        if (response.statusCode != HttpStatus.ok) {
          throw SkillInstallException(
            'Skill 下载失败（HTTP ${response.statusCode}）。',
          );
        }
        if (maxBytes != null && response.contentLength > maxBytes) {
          throw const SkillInstallException('Skill 下载内容超过大小限制。');
        }
        var receivedBytes = 0;
        await for (final chunk in response.timeout(_timeout)) {
          cancellationToken.throwIfCancelled();
          receivedBytes += chunk.length;
          if (maxBytes != null && receivedBytes > maxBytes) {
            throw const SkillInstallException('Skill 下载内容超过大小限制。');
          }
          yield chunk;
        }
        return;
      }
    } on TimeoutException {
      throw const SkillInstallException('Skill 下载超时。');
    } finally {
      client.close(force: true);
    }
  }

  bool _isRedirect(int statusCode) =>
      statusCode == HttpStatus.movedPermanently ||
      statusCode == HttpStatus.found ||
      statusCode == HttpStatus.seeOther ||
      statusCode == HttpStatus.temporaryRedirect ||
      statusCode == HttpStatus.permanentRedirect;
}
