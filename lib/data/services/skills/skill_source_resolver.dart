import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:stars/data/services/skills/skill_catalog_endpoint_policy.dart';
import 'package:stars/data/services/skills/skill_package_downloader.dart';
import 'package:stars/data/services/skills/skill_source_command_parser.dart';
import 'package:stars/domain/models/models.dart';

final class ResolvedSkillSource {
  const ResolvedSkillSource({
    required this.name,
    required this.sourceType,
    required this.source,
    this.ref = '',
    this.subdirectory = '',
  });

  /// A source hint, not a verified SKILL.md identity.
  final String name;
  final String sourceType;
  final String source;
  final String ref;
  final String subdirectory;

  Map<String, Object?> toJson() => {
    'name': name,
    'source_type': sourceType,
    'source': source,
    if (ref.isNotEmpty) 'ref': ref,
    if (subdirectory.isNotEmpty) 'subdirectory': subdirectory,
  };
}

/// Resolves public Skill links and CLI snippets into Stars installation inputs.
/// ModelScope collections are read completely before any installation starts.
final class SkillSourceResolver {
  SkillSourceResolver({
    required SkillCatalogEndpointPolicy endpointPolicy,
    SkillPackageFetcher? fetcher,
    SkillPackageHttpClientFactory? httpClientFactory,
  }) : _downloader = SkillPackageDownloader(
         endpointPolicy: endpointPolicy,
         fetcher: fetcher,
         httpClientFactory: httpClientFactory,
       );

  static const maxCollectionEntries = 200;
  static const maxMetadataBytes = 2 * 1024 * 1024;
  static const _pageSize = 10;

  final SkillPackageDownloader _downloader;

  Future<List<ResolvedSkillSource>> resolve(
    String input,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final sources = const SkillSourceCommandParser().parse(input);
    final resolved = <String, ResolvedSkillSource>{};
    for (final source in sources) {
      cancellationToken.throwIfCancelled();
      final entries = await _resolveSource(source, cancellationToken);
      for (final entry in entries) {
        resolved['${entry.source}|${entry.ref}|${entry.subdirectory}'] = entry;
      }
      if (resolved.length > maxCollectionEntries) {
        throw const SkillInstallException('一次最多解析 200 个 Skill。');
      }
    }
    return List.unmodifiable(resolved.values);
  }

  Future<List<ResolvedSkillSource>> _resolveSource(
    String source,
    AgentCancellationToken cancellationToken,
  ) async {
    if (path.isAbsolute(source)) {
      return [
        ResolvedSkillSource(
          name: path.basename(source),
          sourceType:
              source.toLowerCase().endsWith('.zip')
                  ? 'local_zip'
                  : 'local_directory',
          source: source,
        ),
      ];
    }
    if (RegExp(r'^@?[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(source)) {
      source =
          source.startsWith('@')
              ? 'https://www.modelscope.cn/skills/$source'
              : 'https://github.com/$source';
    }
    final uri = Uri.tryParse(source);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      throw const SkillInstallException('请提供 HTTPS Skill 来源或绝对本地路径。');
    }
    final segments = uri.pathSegments.toList();
    if (segments.isNotEmpty && segments.last.isEmpty) segments.removeLast();
    if ({'modelscope.cn', 'www.modelscope.cn'}.contains(uri.host)) {
      if (uri.port != 443 ||
          uri.hasQuery ||
          segments.length != 3 ||
          !{'skills', 'collections'}.contains(segments.first)) {
        // Already-resolved ZIP download URLs remain usable as direct sources.
        if (uri.port == 443 &&
            !uri.hasQuery &&
            segments.length == 6 &&
            segments.first == 'skills' &&
            segments[3] == 'archive' &&
            segments[4] == 'zip' &&
            segments[5] == 'master') {
          _validateComponent(segments[1], allowAt: true);
          _validateComponent(segments[2]);
          return [_modelScopeSkill(segments[1], segments[2])];
        }
        throw const SkillInstallException(
          'ModelScope 来源必须是 /skills/owner/name 或 /collections/owner/name。',
        );
      }
      _validateComponent(segments[1], allowAt: true);
      _validateComponent(segments[2]);
      return segments.first == 'collections'
          ? _resolveCollection(segments[1], segments[2], cancellationToken)
          : [_modelScopeSkill(segments[1], segments[2])];
    }
    if (uri.host == 'github.com') {
      if (uri.port != 443 || uri.hasQuery || segments.length < 2) {
        throw const SkillInstallException('GitHub Skill 来源无效。');
      }
      for (final segment in segments) {
        _validateComponent(segment);
      }
      if (segments.length != 2 &&
          (segments.length < 5 || segments[2] != 'tree')) {
        throw const SkillInstallException('请提供 GitHub 仓库或 Skill 子目录链接。');
      }
      return [
        ResolvedSkillSource(
          name: segments.last,
          sourceType: 'github',
          source: 'https://github.com/${segments[0]}/${segments[1]}',
          ref: segments.length > 2 ? segments[3] : '',
          subdirectory: segments.length > 2 ? segments.skip(4).join('/') : '',
        ),
      ];
    }
    if (uri.path.toLowerCase().endsWith('.zip')) {
      return [
        ResolvedSkillSource(
          name: segments.last,
          sourceType: 'zip_url',
          source: uri.toString(),
        ),
      ];
    }
    throw const SkillInstallException(
      '不支持此 Skill 来源；请提供 ModelScope、GitHub 或 ZIP 链接。',
    );
  }

  Future<List<ResolvedSkillSource>> _resolveCollection(
    String owner,
    String name,
    AgentCancellationToken cancellationToken,
  ) async {
    final skills = <String, ResolvedSkillSource>{};
    final seenEntries = <String>{};
    int? total;
    var received = 0;
    for (var page = 1; page <= maxCollectionEntries; page++) {
      final uri = Uri.https('www.modelscope.cn', '/api/v1/collections', {
        'Fid': '$owner/$name',
        'PageNumber': '$page',
        'PageSize': '$_pageSize',
      });
      final bytes = await _downloader.fetch(
        uri,
        maxMetadataBytes,
        cancellationToken,
      );
      final Object? document;
      try {
        document = jsonDecode(utf8.decode(bytes));
      } on FormatException {
        throw const SkillInstallException('ModelScope 合集响应不是有效 JSON。');
      }
      if (document is! Map<String, dynamic> ||
          document['Success'] != true ||
          document['Code'] != 200) {
        throw const SkillInstallException('无法读取 ModelScope 合集，请确认合集公开且链接有效。');
      }
      final data = document['Data'];
      final elements =
          data is Map<String, dynamic> ? data['CollectionElements'] : null;
      final entries =
          elements is Map<String, dynamic>
              ? elements['CollectionElementVoList']
              : null;
      final count = elements is Map<String, dynamic> ? elements['Total'] : null;
      if (entries is! List ||
          count is! int ||
          count < 0 ||
          count > maxCollectionEntries ||
          (total != null && total != count)) {
        throw const SkillInstallException('ModelScope 合集列表无效、发生变化或超过 200 项限制。');
      }
      total = count;
      if (entries.isEmpty && received < total) {
        throw const SkillInstallException('ModelScope 合集分页不完整，请稍后重试。');
      }
      final previousEntries = Set<String>.of(seenEntries);
      for (final entry in entries) {
        if (entry is! Map<String, dynamic> || entry['ElementType'] is! String) {
          throw const SkillInstallException('ModelScope 合集条目格式无效。');
        }
        final entryOwner = entry['ElementPath'];
        final entryName = entry['ElementName'];
        final identity = '${entry['ElementType']}/$entryOwner/$entryName';
        if (previousEntries.contains(identity)) {
          throw const SkillInstallException('ModelScope 合集分页重复，无法确认完整列表。');
        }
        seenEntries.add(identity);
        if (entry['ElementType'] != 'skill') continue;
        if (entryOwner is! String || entryName is! String) {
          throw const SkillInstallException('ModelScope 合集 Skill 标识无效。');
        }
        _validateComponent(entryOwner, allowAt: true);
        _validateComponent(entryName);
        final skill = _modelScopeSkill(entryOwner, entryName);
        skills[skill.source] = skill;
      }
      received += entries.length;
      if (received > total) {
        throw const SkillInstallException('ModelScope 合集数量与分页内容不符。');
      }
      if (received == total) {
        if (skills.isEmpty) {
          throw const SkillInstallException('ModelScope 合集中没有 Skill。');
        }
        return List.unmodifiable(skills.values);
      }
    }
    throw const SkillInstallException('ModelScope 合集分页超过限制。');
  }

  ResolvedSkillSource _modelScopeSkill(String owner, String name) =>
      ResolvedSkillSource(
        name: name,
        sourceType: 'zip_url',
        source:
            Uri.https(
              'www.modelscope.cn',
              '/skills/$owner/$name/archive/zip/master',
            ).toString(),
      );

  void _validateComponent(String value, {bool allowAt = false}) {
    final component =
        allowAt && value.startsWith('@') ? value.substring(1) : value;
    if (component.isEmpty ||
        component.length > 255 ||
        component == '.' ||
        component == '..' ||
        !RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(component)) {
      throw const SkillInstallException('Skill 来源包含无效的路径标识。');
    }
  }
}
