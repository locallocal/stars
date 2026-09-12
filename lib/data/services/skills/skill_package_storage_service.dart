import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:stars/domain/models/models.dart';

typedef ApplicationSupportDirectoryProvider = Future<Directory> Function();

final class StagedSkillPackage {
  const StagedSkillPackage({
    required this.stagingDirectory,
    required this.skillRoot,
    required this.sourceUri,
  });

  final Directory stagingDirectory;
  final Directory skillRoot;
  final String sourceUri;
}

final class StoredSkillPackage {
  const StoredSkillPackage({
    required this.rootPath,
    required this.contentDigest,
  });

  final String rootPath;
  final String contentDigest;
}

final class SkillPackageStorageService {
  SkillPackageStorageService({
    ApplicationSupportDirectoryProvider? applicationSupportDirectoryProvider,
  }) : _applicationSupportDirectoryProvider =
           applicationSupportDirectoryProvider ??
           getApplicationSupportDirectory;

  static const int maxFileCount = 256;
  static const int maxDirectoryCount = 512;
  static const int maxSingleFileBytes = 2 * 1024 * 1024;
  static const int maxPackageBytes = 20 * 1024 * 1024;
  static const int maxArchiveBytes = 20 * 1024 * 1024;
  static const int maxPathDepth = 12;
  static const int maxReferenceBytes = 256 * 1024;

  final ApplicationSupportDirectoryProvider
  _applicationSupportDirectoryProvider;

  Future<StagedSkillPackage> stage(SkillImportSource source) async {
    final stagingBase = await _stagingBase();
    final staging = await stagingBase.createTemp('skill-import-');
    try {
      switch (source.kind) {
        case SkillImportKind.directory:
          await _copyDirectory(Directory(source.path), staging);
          break;
        case SkillImportKind.zipArchive:
          if (source.expectedArchiveDigest.isNotEmpty) {
            final archive = File(source.path);
            if (!await archive.exists()) {
              throw const SkillInstallException('选择的 ZIP 文件不存在。');
            }
            if (await archive.length() > maxArchiveBytes) {
              throw const SkillInstallException('ZIP 文件超过 20 MB 限制。');
            }
            final actual =
                sha256.convert(await archive.readAsBytes()).toString();
            if (actual != source.expectedArchiveDigest.toLowerCase()) {
              throw const SkillInstallException('Skill 下载包摘要不匹配。');
            }
          }
          await _extractZip(File(source.path), staging);
          break;
      }
      final skillRoot = await _locateSkillRoot(
        staging,
        subdirectory: source.subdirectory,
      );
      return StagedSkillPackage(
        stagingDirectory: staging,
        skillRoot: skillRoot,
        sourceUri:
            source.sourceUri.isEmpty
                ? Uri.file(source.path).toString()
                : source.sourceUri,
      );
    } catch (_) {
      await _deleteIfExists(staging);
      rethrow;
    }
  }

  Future<StoredSkillPackage> commit(
    StagedSkillPackage staged, {
    required String scope,
    required String skillName,
  }) async {
    final digest = await computeContentDigest(staged.skillRoot);
    final bundles = await _bundlesBase();
    final target = Directory(path.join(bundles.path, scope, skillName, digest));
    if (await target.exists()) {
      await cleanup(staged);
      return StoredSkillPackage(rootPath: target.path, contentDigest: digest);
    }

    await target.parent.create(recursive: true);
    await staged.skillRoot.rename(target.path);
    await _deleteIfExists(staged.stagingDirectory);
    return StoredSkillPackage(rootPath: target.path, contentDigest: digest);
  }

  Future<void> cleanup(StagedSkillPackage staged) =>
      _deleteIfExists(staged.stagingDirectory);

  /// Computes the immutable signed payload digest. The detached signature
  /// sidecar is excluded to avoid a circular signature dependency.
  Future<String> computeContentDigest(Directory root) async {
    final files = <File>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File &&
          path.relative(entity.path, from: root.path) != 'SIGNATURE.json') {
        files.add(entity);
      }
    }
    files.sort((left, right) => left.path.compareTo(right.path));
    final builder = BytesBuilder(copy: false);
    for (final file in files) {
      final relative = path.posix.joinAll(
        path.relative(file.path, from: root.path).split(path.separator),
      );
      builder
        ..add(utf8.encode(relative))
        ..addByte(0)
        ..add(await file.readAsBytes())
        ..addByte(0);
    }
    return sha256.convert(builder.takeBytes()).toString();
  }

  Future<void> verifyImmutableInstallation(
    String rootPath,
    String expectedContentDigest,
  ) async {
    final root = await _verifiedBundleRoot(rootPath);
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      final type = await FileSystemEntity.type(entity.path, followLinks: false);
      if (type != FileSystemEntityType.file &&
          type != FileSystemEntityType.directory) {
        throw const SkillInstallException('已安装 Skill 包含不允许的特殊文件或符号链接。');
      }
    }
    final actual = await computeContentDigest(root);
    if (actual != expectedContentDigest) {
      throw const SkillInstallException('Skill 安装内容已被修改，脚本授权失效。');
    }
  }

  Future<String> readInstructions(String rootPath) async {
    final root = await _verifiedBundleRoot(rootPath);
    final skillFile = File(path.join(root.path, 'SKILL.md'));
    final source = await skillFile.readAsString();
    final normalized = source
        .replaceFirst('\ufeff', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    var closingIndex = -1;
    for (var index = 1; index < lines.length; index++) {
      if (lines[index].trim() == '---') {
        closingIndex = index;
        break;
      }
    }
    if (closingIndex < 0) {
      throw const SkillInstallException('已安装 Skill 的 frontmatter 已损坏。');
    }
    return lines.sublist(closingIndex + 1).join('\n').trim();
  }

  Future<List<String>> listFiles(String rootPath) async {
    final root = await _verifiedBundleRoot(rootPath);
    final files = <String>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is Link) {
        throw const SkillInstallException('已安装 Skill 包含不允许的符号链接。');
      }
      if (entity is File) {
        files.add(
          path.posix.joinAll(
            path.relative(entity.path, from: root.path).split(path.separator),
          ),
        );
      }
    }
    files.sort();
    return List<String>.unmodifiable(files);
  }

  Future<String> readReference(String rootPath, String relativePath) async {
    final normalized = path.posix.normalize(
      relativePath.trim().replaceAll('\\', '/'),
    );
    final segments = normalized.split('/');
    if (relativePath.contains('\u0000') ||
        path.posix.isAbsolute(normalized) ||
        normalized == 'references' ||
        !normalized.startsWith('references/') ||
        segments.any((segment) => segment.isEmpty || segment == '..')) {
      throw const SkillInstallException(
        '只能读取 Skill references 目录中的相对路径。',
        code: 'invalid_skill_reference_path',
      );
    }

    final root = await _verifiedBundleRoot(rootPath);
    final references = Directory(path.join(root.path, 'references'));
    final file = File(path.joinAll([root.path, ...segments]));
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.file) {
      throw const SkillInstallException(
        '请求的 Skill 参考资料不存在或不是普通文件。',
        code: 'skill_reference_not_found',
      );
    }

    final canonicalRoot = await root.resolveSymbolicLinks();
    final canonicalReferences = await references.resolveSymbolicLinks();
    final canonicalFile = await file.resolveSymbolicLinks();
    if (!_isWithin(canonicalRoot, canonicalFile) ||
        !_isWithin(canonicalReferences, canonicalFile)) {
      throw const SkillInstallException(
        '拒绝读取 Skill 根目录以外的参考资料。',
        code: 'skill_reference_outside_root',
      );
    }
    final length = await file.length();
    if (length > maxReferenceBytes) {
      throw const SkillInstallException(
        'Skill 参考资料超过 256 KB 读取限制。',
        code: 'skill_reference_too_large',
      );
    }
    try {
      return utf8.decode(await file.readAsBytes());
    } on FormatException {
      throw const SkillInstallException(
        '当前版本只能读取 UTF-8 文本参考资料。',
        code: 'skill_reference_not_utf8',
      );
    }
  }

  Future<void> removeInstallation(SkillDescriptor descriptor) async {
    final bundles = await _bundlesBase();
    final installation = Directory(
      path.join(bundles.path, descriptor.scope.name, descriptor.name),
    );
    if (!_isWithin(bundles.path, installation.path)) {
      throw const SkillInstallException('拒绝删除 Skill 根目录以外的路径。');
    }
    await _deleteIfExists(installation);
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    if (!await source.exists()) {
      throw const SkillInstallException('选择的 Skill 目录不存在。');
    }
    var fileCount = 0;
    var directoryCount = 0;
    var totalBytes = 0;
    final destinationRoot = Directory(
      path.join(target.path, path.basename(path.normalize(source.path))),
    );
    await destinationRoot.create(recursive: true);
    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {
      final type = await FileSystemEntity.type(entity.path, followLinks: false);
      if (type == FileSystemEntityType.link) {
        throw const SkillInstallException('Skill 目录不能包含符号链接。');
      }
      final relative = path.relative(entity.path, from: source.path);
      _validateRelativePath(relative);
      final destination = path.join(destinationRoot.path, relative);
      if (type == FileSystemEntityType.directory) {
        directoryCount += 1;
        if (directoryCount > maxDirectoryCount) {
          throw const SkillInstallException('Skill 目录数量超过限制。');
        }
        await Directory(destination).create(recursive: true);
      } else if (type == FileSystemEntityType.file) {
        fileCount += 1;
        if (fileCount > maxFileCount) {
          throw const SkillInstallException('Skill 文件数量超过限制。');
        }
        final length = await File(entity.path).length();
        _validateFileSize(length);
        totalBytes += length;
        if (totalBytes > maxPackageBytes) {
          throw const SkillInstallException('Skill 总大小超过 20 MB 限制。');
        }
        await File(destination).parent.create(recursive: true);
        await File(entity.path).copy(destination);
      }
    }
  }

  Future<void> _extractZip(File archiveFile, Directory target) async {
    if (!await archiveFile.exists()) {
      throw const SkillInstallException('选择的 ZIP 文件不存在。');
    }
    if (await archiveFile.length() > maxArchiveBytes) {
      throw const SkillInstallException('ZIP 文件超过 20 MB 限制。');
    }
    final archive = ZipDecoder().decodeBytes(
      await archiveFile.readAsBytes(),
      verify: true,
    );
    var fileCount = 0;
    var directoryCount = 0;
    var totalBytes = 0;
    for (final entry in archive) {
      final relative = entry.name.replaceAll('\\', '/');
      _validateRelativePath(relative);
      if (entry.isSymbolicLink) {
        throw const SkillInstallException('ZIP 不能包含符号链接。');
      }
      if (entry.isDirectory) {
        directoryCount += 1;
        if (directoryCount > maxDirectoryCount) {
          throw const SkillInstallException('Skill 目录数量超过限制。');
        }
        await Directory(
          path.joinAll([target.path, ...relative.split('/')]),
        ).create(recursive: true);
        continue;
      }
      fileCount += 1;
      if (fileCount > maxFileCount) {
        throw const SkillInstallException('Skill 文件数量超过限制。');
      }
      _validateFileSize(entry.size);
      totalBytes += entry.size;
      if (totalBytes > maxPackageBytes) {
        throw const SkillInstallException('Skill 解压后总大小超过 20 MB 限制。');
      }
      final bytes = entry.readBytes();
      if (bytes == null || bytes.length != entry.size) {
        throw const SkillInstallException('ZIP 中的文件内容不完整。');
      }
      final output = File(path.joinAll([target.path, ...relative.split('/')]));
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes, flush: true);
    }
  }

  Future<Directory> _locateSkillRoot(
    Directory staging, {
    required String subdirectory,
  }) async {
    final matches = <File>[];
    await for (final entity in staging.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && path.basename(entity.path) == 'SKILL.md') {
        matches.add(entity);
      }
    }
    if (matches.isEmpty) {
      throw const SkillInstallException('导入内容中没有 SKILL.md。');
    }
    final selectedSubdirectory = _normalizeSubdirectory(subdirectory);
    if (selectedSubdirectory.isNotEmpty) {
      final selected =
          matches.where((match) {
            final relative = path.posix.joinAll(
              path
                  .relative(match.parent.path, from: staging.path)
                  .split(path.separator),
            );
            if (relative == selectedSubdirectory) return true;
            final segments = relative.split('/');
            return segments.length > 1 &&
                segments.skip(1).join('/') == selectedSubdirectory;
          }).toList();
      if (selected.isEmpty) {
        throw const SkillInstallException('指定的 Skill 子目录中没有 SKILL.md。');
      }
      if (selected.length > 1) {
        throw const SkillInstallException('指定的 Skill 子目录不唯一。');
      }
      return selected.single.parent;
    }
    if (matches.length > 1) {
      throw const SkillInstallException('一次只能导入一个 Skill。');
    }
    final root = matches.single.parent;
    final relative = path.relative(root.path, from: staging.path);
    final depth =
        relative == '.'
            ? 0
            : relative
                .split(path.separator)
                .where((part) => part.isNotEmpty)
                .length;
    if (depth > 1) {
      throw const SkillInstallException('SKILL.md 必须位于导入根目录或单一顶层目录中。');
    }
    return root;
  }

  String _normalizeSubdirectory(String value) {
    final trimmed = value.trim().replaceAll('\\', '/');
    if (trimmed.isEmpty) return '';
    final normalized = path.posix.normalize(trimmed);
    final segments = normalized.split('/');
    if (value.contains('\u0000') ||
        path.posix.isAbsolute(normalized) ||
        normalized == '.' ||
        normalized == '..' ||
        normalized.startsWith('../') ||
        segments.any((segment) => segment.isEmpty || segment == '..') ||
        segments.length > maxPathDepth ||
        RegExp(r'^[a-zA-Z]:').hasMatch(normalized)) {
      throw const SkillInstallException('Skill 子目录必须是安全的包内相对路径。');
    }
    return normalized;
  }

  Future<Directory> _verifiedBundleRoot(String rootPath) async {
    final bundles = await _bundlesBase();
    final root = Directory(path.normalize(rootPath));
    if (!_isWithin(bundles.path, root.path) || !await root.exists()) {
      throw const SkillInstallException('Skill 安装目录不存在或已越界。');
    }
    final canonicalBundles = await bundles.resolveSymbolicLinks();
    final canonicalRoot = await root.resolveSymbolicLinks();
    if (!_isWithin(canonicalBundles, canonicalRoot)) {
      throw const SkillInstallException('Skill 安装目录的真实路径已越界。');
    }
    return root;
  }

  void _validateRelativePath(String value) {
    final normalized = path.posix.normalize(value.replaceAll('\\', '/'));
    final segments = normalized.split('/');
    if (value.contains('\u0000') ||
        normalized.isEmpty ||
        normalized == '.' ||
        path.posix.isAbsolute(normalized) ||
        normalized == '..' ||
        normalized.startsWith('../') ||
        segments.any((segment) => segment.isEmpty || segment == '..') ||
        segments.length > maxPathDepth ||
        RegExp(r'^[a-zA-Z]:').hasMatch(normalized)) {
      throw const SkillInstallException('Skill 包含不安全或过深的文件路径。');
    }
  }

  void _validateFileSize(int length) {
    if (length < 0 || length > maxSingleFileBytes) {
      throw const SkillInstallException('Skill 中存在超过 2 MB 的单个文件。');
    }
  }

  bool _isWithin(String parent, String child) {
    final normalizedParent = path.normalize(path.absolute(parent));
    final normalizedChild = path.normalize(path.absolute(child));
    return path.isWithin(normalizedParent, normalizedChild);
  }

  Future<Directory> _stagingBase() async {
    final support = await _applicationSupportDirectoryProvider();
    return Directory(path.join(support.path, 'skills', 'staging'))
      ..createSync(recursive: true);
  }

  Future<Directory> _bundlesBase() async {
    final support = await _applicationSupportDirectoryProvider();
    return Directory(path.join(support.path, 'skills', 'bundles'))
      ..createSync(recursive: true);
  }

  Future<void> _deleteIfExists(Directory directory) async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
