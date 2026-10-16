import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stars/data/services/skills/skill_catalog_endpoint_policy.dart';
import 'package:stars/data/services/skills/skill_package_downloader.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/skill_repository.dart';

export 'skill_package_downloader.dart'
    show SkillPackageFetcher, SkillPackageHttpClientFactory;

enum SkillInstallSourceType { github, zipUrl, localZip, localDirectory }

final class SkillInstallationRequest {
  const SkillInstallationRequest({
    required this.sourceType,
    required this.source,
    this.ref = '',
    this.subdirectory = '',
    this.archiveSha256 = '',
  });

  final SkillInstallSourceType sourceType;
  final String source;
  final String ref;
  final String subdirectory;
  final String archiveSha256;
}

abstract interface class SkillInstallationGateway {
  Future<SkillDescriptor> install(
    SkillInstallationRequest request,
    AgentCancellationToken cancellationToken,
  );
}

typedef SkillTemporaryDirectoryProvider = Future<Directory> Function();

final class SkillInstallationService implements SkillInstallationGateway {
  SkillInstallationService({
    required SkillRepository skillRepository,
    required SkillCatalogEndpointPolicy endpointPolicy,
    SkillPackageHttpClientFactory? httpClientFactory,
    SkillPackageFetcher? fetcher,
    SkillTemporaryDirectoryProvider? temporaryDirectoryProvider,
  }) : _skillRepository = skillRepository,
       _downloader = SkillPackageDownloader(
         endpointPolicy: endpointPolicy,
         httpClientFactory: httpClientFactory,
         fetcher: fetcher,
       ),
       _temporaryDirectoryProvider =
           temporaryDirectoryProvider ??
           (() => Directory.systemTemp.createTemp('stars-skill-install-'));

  final SkillRepository _skillRepository;
  final SkillPackageDownloader _downloader;
  final SkillTemporaryDirectoryProvider _temporaryDirectoryProvider;

  @override
  Future<SkillDescriptor> install(
    SkillInstallationRequest request,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final source = request.source.trim();
    if (source.isEmpty || source.contains('\u0000')) {
      throw const SkillInstallException('Skill 安装来源不能为空。');
    }
    final archiveSha256 = _validateArchiveDigest(request.archiveSha256);
    final subdirectory = request.subdirectory.trim();

    return switch (request.sourceType) {
      SkillInstallSourceType.localDirectory => _installLocal(
        kind: SkillImportKind.directory,
        source: source,
        subdirectory: subdirectory,
        archiveSha256: archiveSha256,
        ref: request.ref,
        cancellationToken: cancellationToken,
      ),
      SkillInstallSourceType.localZip => _installLocal(
        kind: SkillImportKind.zipArchive,
        source: source,
        subdirectory: subdirectory,
        archiveSha256: archiveSha256,
        ref: request.ref,
        cancellationToken: cancellationToken,
      ),
      SkillInstallSourceType.zipUrl => _installRemoteZip(
        sourceUri: _parseHttpsUri(source),
        subdirectory: subdirectory,
        archiveSha256: archiveSha256,
        ref: request.ref,
        cancellationToken: cancellationToken,
      ),
      SkillInstallSourceType.github => _installFromGitHub(
        source: source,
        ref: request.ref.trim(),
        subdirectory: subdirectory,
        archiveSha256: archiveSha256,
        cancellationToken: cancellationToken,
      ),
    };
  }

  Future<SkillDescriptor> _installLocal({
    required SkillImportKind kind,
    required String source,
    required String subdirectory,
    required String archiveSha256,
    required String ref,
    required AgentCancellationToken cancellationToken,
  }) async {
    if (ref.trim().isNotEmpty) {
      throw const SkillInstallException('只有 GitHub 来源可以指定 ref。');
    }
    if (kind == SkillImportKind.directory && archiveSha256.isNotEmpty) {
      throw const SkillInstallException('本地目录来源不能指定 ZIP 摘要。');
    }
    if (!path.isAbsolute(source)) {
      throw const SkillInstallException('本地 Skill 来源必须使用绝对路径。');
    }
    cancellationToken.throwIfCancelled();
    return _skillRepository.install(
      SkillImportSource(
        kind: kind,
        path: path.normalize(source),
        expectedArchiveDigest: archiveSha256,
        subdirectory: subdirectory,
      ),
    );
  }

  Future<SkillDescriptor> _installFromGitHub({
    required String source,
    required String ref,
    required String subdirectory,
    required String archiveSha256,
    required AgentCancellationToken cancellationToken,
  }) async {
    final repository = _parseGitHubRepository(source);
    final resolvedRef = ref.isEmpty ? 'HEAD' : _validateGitHubRef(ref);
    final archiveUri = Uri(
      scheme: 'https',
      host: 'codeload.github.com',
      path: '/${repository.owner}/${repository.name}/zip/$resolvedRef',
    );
    return _downloadAndInstall(
      archiveUri: archiveUri,
      sourceUri: source,
      subdirectory: subdirectory,
      archiveSha256: archiveSha256,
      cancellationToken: cancellationToken,
    );
  }

  Future<SkillDescriptor> _installRemoteZip({
    required Uri sourceUri,
    required String subdirectory,
    required String archiveSha256,
    required String ref,
    required AgentCancellationToken cancellationToken,
  }) async {
    if (ref.trim().isNotEmpty) {
      throw const SkillInstallException('只有 GitHub 来源可以指定 ref。');
    }
    return _downloadAndInstall(
      archiveUri: sourceUri,
      sourceUri: sourceUri.toString(),
      subdirectory: subdirectory,
      archiveSha256: archiveSha256,
      cancellationToken: cancellationToken,
    );
  }

  Future<SkillDescriptor> _downloadAndInstall({
    required Uri archiveUri,
    required String sourceUri,
    required String subdirectory,
    required String archiveSha256,
    required AgentCancellationToken cancellationToken,
  }) async {
    cancellationToken.throwIfCancelled();
    final temporary = await _temporaryDirectoryProvider();
    final archive = File(path.join(temporary.path, 'skill.zip'));
    try {
      await _downloader.downloadToFile(archiveUri, archive, cancellationToken);
      cancellationToken.throwIfCancelled();
      return await _skillRepository.install(
        SkillImportSource(
          kind: SkillImportKind.zipArchive,
          path: archive.path,
          sourceUri: sourceUri,
          expectedArchiveDigest: archiveSha256,
          subdirectory: subdirectory,
        ),
      );
    } finally {
      await _deleteTemporaryBestEffort(temporary);
    }
  }

  Future<void> _deleteTemporaryBestEffort(Directory temporary) async {
    try {
      if (await temporary.exists()) {
        await temporary.delete(recursive: true);
      }
    } on FileSystemException {
      // Installation has already reached a durable outcome. A temporary-file
      // cleanup failure must not turn that outcome into a misleading failure.
    }
  }

  Uri _parseHttpsUri(String source) {
    final uri = Uri.tryParse(source);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw const SkillInstallException('远程 ZIP 来源必须是无凭据的 HTTPS URL。');
    }
    return uri;
  }

  _GitHubRepository _parseGitHubRepository(String source) {
    final uri = _parseHttpsUri(source);
    final segments =
        uri.pathSegments.where((value) => value.isNotEmpty).toList();
    if (uri.host.toLowerCase() != 'github.com' ||
        uri.query.isNotEmpty ||
        segments.length != 2) {
      throw const SkillInstallException(
        'GitHub 来源必须是 https://github.com/owner/repository。',
      );
    }
    final owner = segments[0];
    final name =
        segments[1].endsWith('.git')
            ? segments[1].substring(0, segments[1].length - 4)
            : segments[1];
    final componentPattern = RegExp(r'^[A-Za-z0-9_.-]+$');
    if (!componentPattern.hasMatch(owner) ||
        !componentPattern.hasMatch(name) ||
        owner == '.' ||
        owner == '..' ||
        name == '.' ||
        name == '..') {
      throw const SkillInstallException('GitHub 仓库所有者或名称无效。');
    }
    return _GitHubRepository(owner, name);
  }

  String _validateGitHubRef(String value) {
    if (value.length > 255 ||
        value.startsWith('/') ||
        value.endsWith('/') ||
        value.contains('..') ||
        value.contains('//') ||
        value.contains('@{') ||
        !RegExp(r'^[A-Za-z0-9._/+\-]+$').hasMatch(value)) {
      throw const SkillInstallException('GitHub ref 格式无效。');
    }
    return value;
  }

  String _validateArchiveDigest(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isNotEmpty &&
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(normalized)) {
      throw const SkillInstallException('ZIP SHA-256 必须是 64 位十六进制字符串。');
    }
    return normalized;
  }
}

final class _GitHubRepository {
  const _GitHubRepository(this.owner, this.name);

  final String owner;
  final String name;
}
