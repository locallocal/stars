import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:stars/domain/models/models.dart';
import 'package:yaml/yaml.dart';

/// Loads one integrity-pinned system Skill from the Flutter asset bundle.
///
/// The descriptor is application-owned, while the frontmatter is checked
/// against it so changing a bundled `SKILL.md` cannot silently leave runtime
/// metadata out of sync.
abstract base class BundledSystemSkill {
  BundledSystemSkill({
    required this.bundledAssetRoot,
    required this.bundledAssetPath,
    required this.expectedDigest,
    required this.promptVersion,
    required this.skillId,
    required this.name,
    required this.description,
    required this.compatibility,
    required Set<String> requestedToolNames,
    required this.integrityError,
    Map<String, String> referenceDigests = const {},
  }) : requestedToolNames = Set<String>.unmodifiable(requestedToolNames),
       referenceDigests = Map<String, String>.unmodifiable(referenceDigests);

  final String bundledAssetRoot;
  final String bundledAssetPath;
  final String expectedDigest;
  final int promptVersion;
  final String skillId;
  final String name;
  final String description;
  final String compatibility;
  final Set<String> requestedToolNames;
  final String integrityError;
  final Map<String, String> referenceDigests;

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
    if (!forceRefresh && bundle == null) {
      final cached = _content;
      if (cached != null) {
        _isValid = true;
        return cached;
      }
    }

    _isValid = false;
    final assetBundle = bundle ?? rootBundle;
    final source = await assetBundle.loadString(bundledAssetPath, cache: false);
    final digest = sha256.convert(utf8.encode(source)).toString();
    if (digest != expectedDigest) {
      throw FormatException(integrityError);
    }

    final parsed = _parse(source);
    _validateFrontmatter(parsed.frontmatter);
    final resources = <String, String>{};
    for (final entry in referenceDigests.entries) {
      final relativePath = _validatedReferencePath(entry.key);
      final reference = await assetBundle.loadString(
        '$bundledAssetRoot/$relativePath',
        cache: false,
      );
      final referenceDigest = sha256.convert(utf8.encode(reference)).toString();
      if (referenceDigest != entry.value) {
        throw FormatException(
          '$integrityError Bundled reference integrity validation failed.',
        );
      }
      resources[relativePath] = reference;
    }
    final timestamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final content = SkillContent(
      descriptor: SkillDescriptor(
        id: skillId,
        name: name,
        description: description,
        version: '$promptVersion',
        scope: SkillScope.bundled,
        sourceUri: 'asset:///$bundledAssetPath',
        rootPath: bundledAssetRoot,
        contentDigest: expectedDigest,
        trustState: SkillTrustState.bundledTrusted,
        validationStatus: SkillValidationStatus.valid,
        compatibility: compatibility,
        requestedToolNames: requestedToolNames,
        hasReferences: resources.isNotEmpty,
        publisherId: 'stars',
        publisherName: 'Stars',
        installedAt: timestamp,
        updatedAt: timestamp,
      ),
      instructions: parsed.instructions,
      files: ['SKILL.md', ...resources.keys],
      resources: resources,
    );
    if (bundle == null) _content = content;
    _isValid = true;
    return content;
  }

  String _validatedReferencePath(String source) {
    final normalized = source.trim().replaceAll('\\', '/');
    final segments = normalized.split('/');
    if (normalized != source ||
        !normalized.startsWith('references/') ||
        segments.any(
          (segment) => segment.isEmpty || segment == '.' || segment == '..',
        )) {
      throw ArgumentError.value(
        source,
        'referenceDigests',
        'Bundled Skill references must be safe paths under references/.',
      );
    }
    return normalized;
  }

  ({YamlMap frontmatter, String instructions}) _parse(String source) {
    final normalized = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') {
      throw const FormatException('Built-in Skill frontmatter is missing.');
    }
    final closingIndex = lines.indexWhere((line) => line.trim() == '---', 1);
    if (closingIndex < 0) {
      throw const FormatException('Built-in Skill frontmatter is incomplete.');
    }

    final Object? frontmatter;
    try {
      frontmatter = loadYaml(lines.sublist(1, closingIndex).join('\n'));
    } on YamlException catch (error) {
      throw FormatException('Built-in Skill frontmatter is invalid: $error');
    }
    if (frontmatter is! YamlMap) {
      throw const FormatException(
        'Built-in Skill frontmatter must be a mapping.',
      );
    }
    return (
      frontmatter: frontmatter,
      instructions: lines.sublist(closingIndex + 1).join('\n').trim(),
    );
  }

  void _validateFrontmatter(YamlMap frontmatter) {
    final allowedTools = frontmatter['allowed-tools'];
    final metadata = frontmatter['metadata'];
    final frontmatterTools =
        allowedTools is String
            ? allowedTools
                .trim()
                .split(RegExp(r'\s+'))
                .where((value) => value.isNotEmpty)
                .toSet()
            : const <String>{};
    if (frontmatter['name'] != name ||
        frontmatter['description'] != description ||
        frontmatterTools.length != requestedToolNames.length ||
        !frontmatterTools.containsAll(requestedToolNames) ||
        metadata is! YamlMap ||
        metadata['scope'] != 'system' ||
        metadata['prompt-version'] != promptVersion) {
      throw const FormatException(
        'Built-in Skill frontmatter does not match its runtime descriptor.',
      );
    }
  }
}
