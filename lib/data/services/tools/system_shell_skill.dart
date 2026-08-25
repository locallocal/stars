import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:stars/domain/models/models.dart';

final class SystemShellSkill {
  static const assetRoot = 'assets/skills/system/shell-command';
  static const assetPath = 'assets/skills/system/shell-command/SKILL.md';

  bool _isValid = false;
  SkillContent? _content;

  bool get isValid => _isValid;
  String get contentDigest => shellCommandSkillContentDigest;
  int get promptVersion => shellCommandSkillPromptVersion;

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
    if (digest != shellCommandSkillContentDigest) {
      throw const FormatException(
        'Built-in shell command Skill failed integrity validation.',
      );
    }
    final timestamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final content = SkillContent(
      descriptor: SkillDescriptor(
        id: shellCommandSkillId,
        name: 'shell-command',
        description:
            'Run build, test, version-control, package-manager, diagnostic, '
            'or other process-oriented commands through the native desktop '
            'shell when no structured built-in Tool fits; do not use for '
            'ordinary file or directory operations.',
        version: '$shellCommandSkillPromptVersion',
        scope: SkillScope.bundled,
        sourceUri: 'asset:///$assetPath',
        rootPath: assetRoot,
        contentDigest: shellCommandSkillContentDigest,
        trustState: SkillTrustState.bundledTrusted,
        validationStatus: SkillValidationStatus.valid,
        compatibility: 'Stars desktop',
        requestedToolNames: shellCommandToolNames,
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
