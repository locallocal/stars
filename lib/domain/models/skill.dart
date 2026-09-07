import 'skill_ecosystem.dart';

enum SkillScope { bundled, user, project }

enum SkillTrustState {
  bundledTrusted,
  userReviewed,
  untrusted,
  blocked,
  modified,
}

enum SkillValidationStatus { valid, validWithWarnings, invalid }

enum SkillDiagnosticSeverity { warning, error }

enum SkillActivationMode { auto }

enum SkillActivationTrigger { model }

enum SkillActivationStatus { activated, failed, skipped }

enum SkillImportKind { directory, zipArchive }

final class SkillInstallException implements Exception {
  const SkillInstallException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class SkillDiagnostic {
  const SkillDiagnostic({
    required this.code,
    required this.message,
    required this.severity,
  });

  final String code;
  final String message;
  final SkillDiagnosticSeverity severity;

  Map<String, Object?> toMap() => {
    'code': code,
    'message': message,
    'severity': severity.name,
  };

  factory SkillDiagnostic.fromMap(Map<String, Object?> map) {
    return SkillDiagnostic(
      code: map['code']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      severity: SkillDiagnosticSeverity.values.firstWhere(
        (value) => value.name == map['severity'],
        orElse: () => SkillDiagnosticSeverity.warning,
      ),
    );
  }
}

final class SkillDescriptor {
  SkillDescriptor({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.scope,
    required this.sourceUri,
    required this.rootPath,
    required this.contentDigest,
    required this.trustState,
    required this.validationStatus,
    required this.compatibility,
    Set<String> requestedToolNames = const {},
    List<SkillDiagnostic> diagnostics = const [],
    this.hasScripts = false,
    this.hasReferences = false,
    this.hasAssets = false,
    this.publisherId = '',
    this.publisherName = '',
    this.signatureStatus = SkillSignatureStatus.unsigned,
    this.catalogId = '',
    this.catalogEntryId = '',
    this.updatePolicy = SkillUpdatePolicy.manual,
    required this.installedAt,
    required this.updatedAt,
  }) : requestedToolNames = Set<String>.unmodifiable(requestedToolNames),
       diagnostics = List<SkillDiagnostic>.unmodifiable(diagnostics);

  final String id;
  final String name;
  final String description;
  final String version;
  final SkillScope scope;
  final String sourceUri;
  final String rootPath;
  final String contentDigest;
  final SkillTrustState trustState;
  final SkillValidationStatus validationStatus;
  final String compatibility;
  final Set<String> requestedToolNames;
  final List<SkillDiagnostic> diagnostics;
  final bool hasScripts;
  final bool hasReferences;
  final bool hasAssets;
  final String publisherId;
  final String publisherName;
  final SkillSignatureStatus signatureStatus;
  final String catalogId;
  final String catalogEntryId;
  final SkillUpdatePolicy updatePolicy;
  final DateTime installedAt;
  final DateTime updatedAt;

  bool get isUsable =>
      validationStatus != SkillValidationStatus.invalid &&
      trustState != SkillTrustState.blocked &&
      trustState != SkillTrustState.untrusted;
}

final class SkillContent {
  SkillContent({
    required this.descriptor,
    required this.instructions,
    List<String> files = const [],
  }) : files = List<String>.unmodifiable(files);

  final SkillDescriptor descriptor;
  final String instructions;
  final List<String> files;
}

final class SkillResourceContent {
  const SkillResourceContent({
    required this.skillId,
    required this.path,
    required this.content,
  });

  final String skillId;
  final String path;
  final String content;
}

final class SkillCatalogEntry {
  const SkillCatalogEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.contentDigest,
    required this.priority,
  });

  final String id;
  final String name;
  final String description;
  final String contentDigest;
  final int priority;
}

final class SkillImportSource {
  const SkillImportSource({
    required this.kind,
    required this.path,
    this.sourceUri = '',
    this.catalogId = '',
    this.catalogEntryId = '',
    this.expectedContentDigest = '',
    this.expectedArchiveDigest = '',
    this.subdirectory = '',
    this.publisherId = '',
    this.expectedName = '',
    this.expectedVersion = '',
  });

  final SkillImportKind kind;
  final String path;
  final String sourceUri;
  final String catalogId;
  final String catalogEntryId;
  final String expectedContentDigest;
  final String expectedArchiveDigest;
  final String subdirectory;
  final String publisherId;
  final String expectedName;
  final String expectedVersion;
}

final class BotSkillBinding {
  const BotSkillBinding({
    required this.botId,
    required this.skillId,
    this.enabled = true,
    this.requiresApproval = true,
    this.activationMode = SkillActivationMode.auto,
    this.priority = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String botId;
  final String skillId;
  final bool enabled;
  final bool requiresApproval;
  final SkillActivationMode activationMode;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  BotSkillBinding copyWith({
    bool? enabled,
    bool? requiresApproval,
    SkillActivationMode? activationMode,
    int? priority,
    DateTime? updatedAt,
  }) {
    return BotSkillBinding(
      botId: botId,
      skillId: skillId,
      enabled: enabled ?? this.enabled,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      activationMode: activationMode ?? this.activationMode,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

final class ConversationSkillPin {
  const ConversationSkillPin({
    required this.chatId,
    required this.skillId,
    required this.createdAt,
  });

  final String chatId;
  final String skillId;
  final DateTime createdAt;
}

final class ActivatedSkill {
  const ActivatedSkill({
    required this.id,
    required this.name,
    required this.contentDigest,
    required this.trigger,
  });

  final String id;
  final String name;
  final String contentDigest;
  final SkillActivationTrigger trigger;
}

final class SkillActivationAttempt {
  const SkillActivationAttempt({
    required this.skillId,
    required this.skillName,
    required this.contentDigest,
    required this.trigger,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    this.durationMs,
    this.errorCode = '',
  });

  final String skillId;
  final String skillName;
  final String contentDigest;
  final SkillActivationTrigger trigger;
  final SkillActivationStatus status;
  final DateTime startedAt;
  final DateTime completedAt;
  final int? durationMs;
  final String errorCode;
}

final class SkillDescriptionTestCase {
  const SkillDescriptionTestCase({
    required this.input,
    required this.shouldActivate,
  });

  final String input;
  final bool shouldActivate;
}

final class SkillDescriptionTestResult {
  const SkillDescriptionTestResult({
    required this.testCase,
    required this.runs,
    required this.activations,
  });

  final SkillDescriptionTestCase testCase;
  final int runs;
  final int activations;

  double get activationRate => runs == 0 ? 0 : activations / runs;

  bool get passed =>
      testCase.shouldActivate
          ? activations > runs / 2
          : activations <= runs / 2;
}

final class SkillDescriptionTestReport {
  SkillDescriptionTestReport({
    required this.skill,
    required List<SkillDescriptionTestResult> results,
  }) : results = List<SkillDescriptionTestResult>.unmodifiable(results);

  final SkillDescriptor skill;
  final List<SkillDescriptionTestResult> results;

  int get passedCount => results.where((result) => result.passed).length;
  bool get passed => results.isNotEmpty && passedCount == results.length;
}

final class SkillActivationRecord {
  const SkillActivationRecord({
    required this.id,
    required this.runId,
    required this.chatId,
    required this.messageId,
    required this.skillId,
    required this.skillName,
    required this.contentDigest,
    required this.trigger,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.durationMs,
    this.errorCode = '',
  });

  final String id;
  final String runId;
  final String chatId;
  final String messageId;
  final String skillId;
  final String skillName;
  final String contentDigest;
  final SkillActivationTrigger trigger;
  final SkillActivationStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? durationMs;
  final String errorCode;
}
