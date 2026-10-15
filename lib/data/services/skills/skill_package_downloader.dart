import 'dart:async';
import 'dart:io';

import 'package:stars/data/services/skills/skill_catalog_endpoint_policy.dart';
import 'package:stars/domain/models/models.dart';

typedef SkillPackageHttpClientFactory = HttpClient Function();
typedef SkillPackageFetcher =
    Future<List<int>> Function(
      Uri uri,
      int maxBytes,
      AgentCancellationToken cancellationToken,
    );

/// Bounded HTTPS reads shared by source discovery and package installation.
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
    final bytes = await (_fetcher ?? _fetch)(uri, maxBytes, cancellationToken);
    cancellationToken.throwIfCancelled();
    if (bytes.length > maxBytes) {
      throw const SkillInstallException('Skill 下载内容超过大小限制。');
    }
    return bytes;
  }

  Future<List<int>> _fetch(
    Uri initialUri,
    int maxBytes,
    AgentCancellationToken cancellationToken,
  ) async {
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
        if (response.contentLength > maxBytes) {
          throw const SkillInstallException('Skill 下载内容超过大小限制。');
        }
        final bytes = <int>[];
        await for (final chunk in response.timeout(_timeout)) {
          cancellationToken.throwIfCancelled();
          if (bytes.length + chunk.length > maxBytes) {
            throw const SkillInstallException('Skill 下载内容超过大小限制。');
          }
          bytes.addAll(chunk);
        }
        return bytes;
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
