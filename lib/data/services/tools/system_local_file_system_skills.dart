import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:stars/domain/models/models.dart';

final class SystemDirectoryOperationsSkill extends _SystemLocalFileSystemSkill {
  SystemDirectoryOperationsSkill()
    : super(
        assetRoot: 'assets/skills/system/directory-operations',
        assetPath: 'assets/skills/system/directory-operations/SKILL.md',
        expectedDigest: directoryOperationsSkillContentDigest,
        promptVersion: directoryOperationsSkillPromptVersion,
        skillId: directoryOperationsSkillId,
        name: 'directory-operations',
        description:
            'List, create, and delete local directories with native '
            'cross-platform file-system APIs.',
        requestedToolNames: directoryOperationsToolNames,
        integrityError:
            'Built-in directory operations Skill failed integrity validation.',
      );
}

final class SystemFileOperationsSkill extends _SystemLocalFileSystemSkill {
  SystemFileOperationsSkill()
    : super(
        assetRoot: 'assets/skills/system/file-operations',
        assetPath: 'assets/skills/system/file-operations/SKILL.md',
        expectedDigest: fileOperationsSkillContentDigest,
        promptVersion: fileOperationsSkillPromptVersion,
        skillId: fileOperationsSkillId,
        name: 'file-operations',
        description:
            'Read, write, copy, move, and delete local files with native '
            'cross-platform file-system APIs.',
        requestedToolNames: fileOperationsToolNames,
        integrityError:
            'Built-in file operations Skill failed integrity validation.',
      );
}

abstract base class _SystemLocalFileSystemSkill {
  _SystemLocalFileSystemSkill({
    required this.assetRoot,
    required this.assetPath,
    required this.expectedDigest,
    required this.promptVersion,
    required this.skillId,
    required this.name,
    required this.description,
    required this.requestedToolNames,
    required this.integrityError,
  });

  final String assetRoot;
  final String assetPath;
  final String expectedDigest;
  final int promptVersion;
  final String skillId;
  final String name;
  final String description;
  final Set<String> requestedToolNames;
  final String integrityError;

  bool _isValid = false;
  SkillContent? _content;

  bool get isValid => _isValid;
  String get contentDigest => expectedDigest;

  Future<void> validate({AssetBundle? bundle}) async {
    await loadContent(bundle: bundle, forceRefresh: true);
  }

  Future<SkillContent> loadContent({
    AssetBundle? bundle,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && bundle == null && _content != null) {
      return _content!;
    }
    _isValid = false;
    final source = await (bundle ?? rootBundle).loadString(
      assetPath,
      cache: false,
    );
    final digest = sha256.convert(utf8.encode(source)).toString();
    if (digest != expectedDigest) {
      throw FormatException(integrityError);
    }
    final timestamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final content = SkillContent(
      descriptor: SkillDescriptor(
        id: skillId,
        name: name,
        description: description,
        version: '$promptVersion',
        scope: SkillScope.bundled,
        sourceUri: 'asset:///$assetPath',
        rootPath: assetRoot,
        contentDigest: expectedDigest,
        trustState: SkillTrustState.bundledTrusted,
        validationStatus: SkillValidationStatus.valid,
        compatibility:
            'Stars native platforms (Android, iOS, Windows, macOS, Linux)',
        requestedToolNames: requestedToolNames,
        publisherId: 'stars',
        publisherName: 'Stars',
        installedAt: timestamp,
        updatedAt: timestamp,
      ),
      instructions: _instructions(source),
      files: const ['SKILL.md'],
    );
    if (bundle == null) _content = content;
    _isValid = true;
    return content;
  }

  String _instructions(String source) {
    final normalized = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') {
      throw const FormatException('Built-in Skill frontmatter is missing.');
    }
    final closingIndex = lines.indexWhere((line) => line.trim() == '---', 1);
    if (closingIndex < 0) {
      throw const FormatException('Built-in Skill frontmatter is incomplete.');
    }
    return lines.sublist(closingIndex + 1).join('\n').trim();
  }
}
