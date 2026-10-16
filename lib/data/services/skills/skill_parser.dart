import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;
import 'package:stars/domain/models/models.dart';
import 'package:yaml/yaml.dart';

final class ParsedSkillPackage {
  ParsedSkillPackage({
    required this.name,
    required this.description,
    required this.version,
    required this.compatibility,
    required this.instructions,
    required this.license,
    required this.requestedToolNames,
    required this.diagnostics,
    required this.files,
    required this.hasScripts,
    required this.hasReferences,
    required this.hasAssets,
  });

  final String name;
  final String description;
  final String version;
  final String compatibility;
  final String instructions;
  final String license;
  final Set<String> requestedToolNames;
  final List<SkillDiagnostic> diagnostics;
  final List<String> files;
  final bool hasScripts;
  final bool hasReferences;
  final bool hasAssets;

  SkillValidationStatus get validationStatus {
    if (diagnostics.any(
      (item) => item.severity == SkillDiagnosticSeverity.error,
    )) {
      return SkillValidationStatus.invalid;
    }
    return diagnostics.isEmpty
        ? SkillValidationStatus.valid
        : SkillValidationStatus.validWithWarnings;
  }
}

final class SkillParser {
  const SkillParser();

  Future<ParsedSkillPackage> parse(
    Directory root, {
    bool validateDirectoryName = true,
  }) {
    final rootPath = root.path;
    return Isolate.run(
      () => const SkillParser()._parse(
        Directory(rootPath),
        validateDirectoryName: validateDirectoryName,
      ),
    );
  }

  Future<ParsedSkillPackage> _parse(
    Directory root, {
    required bool validateDirectoryName,
  }) async {
    final skillFile = File(path.join(root.path, 'SKILL.md'));
    if (!await skillFile.exists()) {
      throw const SkillInstallException('Skill 包缺少 SKILL.md。');
    }
    String source;
    try {
      source = await utf8.decoder.bind(skillFile.openRead()).join();
    } on FormatException {
      throw const SkillInstallException('SKILL.md 必须是有效的 UTF-8 文本。');
    }
    if (source.startsWith('\ufeff')) source = source.substring(1);
    source = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = source.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') {
      throw const SkillInstallException('SKILL.md 必须以 YAML frontmatter 开始。');
    }

    var closingIndex = -1;
    for (var index = 1; index < lines.length; index++) {
      if (lines[index].trim() == '---') {
        closingIndex = index;
        break;
      }
    }
    if (closingIndex < 0) {
      throw const SkillInstallException('SKILL.md 的 YAML frontmatter 未闭合。');
    }

    final frontmatter = lines.sublist(1, closingIndex).join('\n');
    final Object? yaml;
    try {
      yaml = loadYaml(frontmatter, sourceUrl: skillFile.uri);
    } on YamlException catch (error) {
      throw SkillInstallException('SKILL.md YAML 无法解析：${error.message}');
    }
    if (yaml is! Map) {
      throw const SkillInstallException('SKILL.md frontmatter 必须是键值映射。');
    }

    final diagnostics = <SkillDiagnostic>[];
    final name = _stringValue(yaml['name']);
    final description = _stringValue(yaml['description']);
    final compatibility = _stringValue(yaml['compatibility']);
    final license = _stringValue(yaml['license']);
    final metadata = yaml['metadata'];
    final metadataVersion =
        metadata is Map ? _stringValue(metadata['version']) : '';
    final version =
        metadataVersion.isNotEmpty
            ? metadataVersion
            : _stringValue(yaml['version']);
    final allowedTools = yaml['allowed-tools'];
    final requestedToolNames =
        allowedTools is String
            ? allowedTools
                .split(RegExp(r'\s+'))
                .where((value) => value.isNotEmpty)
                .toSet()
            : <String>{};
    final instructions = lines.sublist(closingIndex + 1).join('\n').trim();
    final directoryName = path.basename(root.path);

    if (name.isEmpty) {
      diagnostics.add(_error('missing_name', 'name 不能为空。'));
    } else {
      if (name.length > 64 ||
          !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(name)) {
        diagnostics.add(
          _error('invalid_name', 'name 必须为不超过 64 个字符的小写字母、数字和连字符。'),
        );
      }
      if (validateDirectoryName && name != directoryName) {
        diagnostics.add(
          _error('directory_mismatch', 'name 必须与 Skill 根目录名称一致。'),
        );
      }
    }

    if (description.isEmpty) {
      diagnostics.add(_error('missing_description', 'description 不能为空。'));
    } else if (description.length > 1024) {
      diagnostics.add(
        _error('description_too_long', 'description 不能超过 1024 个字符。'),
      );
    }
    if (compatibility.length > 500) {
      diagnostics.add(
        _error('compatibility_too_long', 'compatibility 不能超过 500 个字符。'),
      );
    }
    if (metadata != null && metadata is! Map) {
      diagnostics.add(_warning('invalid_metadata', 'metadata 应为字符串键值映射。'));
    } else if (metadata is Map &&
        metadata.entries.any(
          (entry) => entry.key is! String || entry.value is! String,
        )) {
      diagnostics.add(
        _warning('invalid_metadata_value', 'metadata 的键和值应为字符串。'),
      );
    }
    if (allowedTools != null && allowedTools is! String) {
      diagnostics.add(
        _warning('invalid_allowed_tools', 'allowed-tools 应为空格分隔的字符串。'),
      );
    }
    if (instructions.isEmpty) {
      diagnostics.add(_warning('empty_body', 'SKILL.md 没有指令正文。'));
    }
    if (lines.length > 500) {
      diagnostics.add(_warning('large_skill_file', 'SKILL.md 超过建议的 500 行。'));
    }

    final files = await _listRelativeFiles(root);
    final hasScripts = files.any((file) => _isInDirectory(file, 'scripts'));
    final hasReferences = files.any(
      (file) => _isInDirectory(file, 'references'),
    );
    final hasAssets = files.any((file) => _isInDirectory(file, 'assets'));
    if (hasScripts) {
      diagnostics.add(
        _warning(
          'scripts_require_sandbox_approval',
          '包含 scripts/；仅在桌面隔离环境可用且用户明确授权后执行。',
        ),
      );
    }

    return ParsedSkillPackage(
      name: name,
      description: description,
      version: version,
      compatibility: compatibility,
      instructions: instructions,
      license: license,
      requestedToolNames: requestedToolNames,
      diagnostics: diagnostics,
      files: files,
      hasScripts: hasScripts,
      hasReferences: hasReferences,
      hasAssets: hasAssets,
    );
  }

  Future<List<String>> _listRelativeFiles(Directory root) async {
    final files = <String>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      files.add(
        path.posix.joinAll(
          path.relative(entity.path, from: root.path).split(path.separator),
        ),
      );
    }
    files.sort();
    return List<String>.unmodifiable(files);
  }

  bool _isInDirectory(String relativePath, String directory) =>
      relativePath == directory || relativePath.startsWith('$directory/');

  String _stringValue(Object? value) => value is String ? value.trim() : '';

  SkillDiagnostic _error(String code, String message) => SkillDiagnostic(
    code: code,
    message: message,
    severity: SkillDiagnosticSeverity.error,
  );

  SkillDiagnostic _warning(String code, String message) => SkillDiagnostic(
    code: code,
    message: message,
    severity: SkillDiagnosticSeverity.warning,
  );
}
