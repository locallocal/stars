import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:stars/data/models/skill_records.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/data/services/skills/skill_package_storage_service.dart';
import 'package:stars/data/services/skills/skill_parser.dart';
import 'package:stars/data/services/skills/skill_signature_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/skill_ecosystem_repository.dart';
import 'package:stars/domain/repositories/skill_repository.dart';

final class FileSkillRepository implements SkillRepository {
  FileSkillRepository({
    required LocalDatabaseService localDatabase,
    required SkillPackageStorageService storageService,
    required SkillParser parser,
    SkillEcosystemRepository? ecosystemRepository,
    SkillSignatureService? signatureService,
  }) : _localDatabase = localDatabase,
       _storageService = storageService,
       _parser = parser,
       _ecosystemRepository = ecosystemRepository,
       _signatureService = signatureService;

  final LocalDatabaseService _localDatabase;
  final SkillPackageStorageService _storageService;
  final SkillParser _parser;
  final SkillEcosystemRepository? _ecosystemRepository;
  final SkillSignatureService? _signatureService;
  final StreamController<List<SkillDescriptor>> _changes =
      StreamController<List<SkillDescriptor>>.broadcast();
  List<SkillDescriptor>? _cache;

  @override
  Stream<List<SkillDescriptor>> get changes => _changes.stream;

  @override
  Future<List<SkillDescriptor>> getInstalled({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache != null) return _snapshot;
    final records = await _localDatabase.loadSkills();
    _cache =
        records.map((record) => SkillRecord(record).toDomain()).toList()
          ..sort((left, right) => left.name.compareTo(right.name));
    return _snapshot;
  }

  @override
  Future<SkillDescriptor?> getById(String id) async {
    final cached = _cache?.where((item) => item.id == id).firstOrNull;
    if (cached != null) return cached;
    final records = await _localDatabase.loadSkill(id);
    return records.isEmpty ? null : SkillRecord(records.single).toDomain();
  }

  @override
  Future<SkillContent> load(String skillId, {String? contentDigest}) async {
    final descriptor = await getById(skillId);
    if (descriptor == null) {
      throw const SkillInstallException(
        'Skill 不存在或已卸载。',
        code: 'skill_not_installed',
      );
    }
    if (contentDigest != null && contentDigest != descriptor.contentDigest) {
      throw const SkillInstallException(
        '请求的 Skill 版本已不再安装。',
        code: 'skill_version_changed',
      );
    }
    return SkillContent(
      descriptor: descriptor,
      instructions: await _storageService.readInstructions(descriptor.rootPath),
      files: await _storageService.listFiles(descriptor.rootPath),
    );
  }

  @override
  Future<SkillResourceContent> readResource(
    String skillId,
    String relativePath, {
    String? contentDigest,
  }) async {
    final descriptor = await getById(skillId);
    if (descriptor == null) {
      throw const SkillInstallException(
        'Skill 不存在或已卸载。',
        code: 'skill_not_installed',
      );
    }
    if (contentDigest != null && contentDigest != descriptor.contentDigest) {
      throw const SkillInstallException(
        '请求的 Skill 版本已不再安装。',
        code: 'skill_version_changed',
      );
    }
    return SkillResourceContent(
      skillId: descriptor.id,
      path: relativePath,
      content: await _storageService.readReference(
        descriptor.rootPath,
        relativePath,
      ),
    );
  }

  @override
  Future<SkillDescriptor> install(SkillImportSource source) async {
    final staged = await _storageService.stage(source);
    var committed = false;
    try {
      final parsed = await _parser.parse(
        staged.skillRoot,
        validateDirectoryName:
            path.normalize(staged.skillRoot.path) !=
            path.normalize(staged.stagingDirectory.path),
      );
      if (parsed.validationStatus == SkillValidationStatus.invalid) {
        final errors = parsed.diagnostics
            .where((item) => item.severity == SkillDiagnosticSeverity.error)
            .map((item) => item.message)
            .join('；');
        throw SkillInstallException(errors);
      }
      if ((source.expectedName.isNotEmpty &&
              source.expectedName != parsed.name) ||
          (source.expectedVersion.isNotEmpty &&
              source.expectedVersion != parsed.version)) {
        throw const SkillInstallException('Skill 身份或版本与目录声明不匹配。');
      }

      final scope = SkillScope.user;
      final contentDigest = await _storageService.computeContentDigest(
        staged.skillRoot,
      );
      if (source.expectedContentDigest.isNotEmpty &&
          source.expectedContentDigest.toLowerCase() != contentDigest) {
        throw const SkillInstallException('Skill 内容摘要与目录声明不匹配。');
      }
      final verification =
          await _signatureService?.verify(
            skillRoot: staged.skillRoot,
            contentDigest: contentDigest,
            skillName: parsed.name,
            version: parsed.version,
            expectedPublisherId: source.publisherId,
          ) ??
          const SkillSignatureVerification(
            status: SkillSignatureStatus.unsigned,
          );
      final policy =
          await _ecosystemRepository?.getOrganizationPolicy() ??
          SkillOrganizationPolicy.defaults;
      final signatureError = switch (verification.status) {
        SkillSignatureStatus.invalid => 'Skill 签名无效，已拒绝安装。',
        SkillSignatureStatus.unsigned when !policy.allowUnsignedSkills =>
          '组织策略要求 Skill 必须包含可信签名。',
        SkillSignatureStatus.unknownPublisher
            when !policy.allowUnknownPublishers =>
          'Skill 发布者不在组织信任列表中。',
        SkillSignatureStatus.verified
            when policy.allowedPublisherIds.isNotEmpty &&
                !policy.allowedPublisherIds.contains(
                  verification.publisherId,
                ) =>
          'Skill 发布者不在组织允许列表中。',
        _ => '',
      };
      if (signatureError.isNotEmpty) {
        await _appendEvent(
          type: SkillComplianceEventType.signatureRejected,
          skillId: '${scope.name}:${parsed.name}',
          contentDigest: contentDigest,
          publisherId: verification.publisherId,
          decision: 'deny',
          reason: verification.reason,
        );
        throw SkillInstallException(signatureError);
      }
      final stored = await _storageService.commit(
        staged,
        scope: scope.name,
        skillName: parsed.name,
      );
      committed = true;
      final existingRecords = await _localDatabase.loadSkillByScopeAndName(
        scope.name,
        parsed.name,
      );
      final existing =
          existingRecords.isEmpty
              ? null
              : SkillRecord(existingRecords.single).toDomain();
      final now = DateTime.now();
      if (existing != null && existing.contentDigest != stored.contentDigest) {
        await _ecosystemRepository?.deleteScriptGrant(existing.id);
      }
      final descriptor = SkillDescriptor(
        id: '${scope.name}:${parsed.name}',
        name: parsed.name,
        description: parsed.description,
        version: parsed.version,
        scope: scope,
        sourceUri: staged.sourceUri,
        rootPath: stored.rootPath,
        contentDigest: stored.contentDigest,
        trustState: SkillTrustState.userReviewed,
        validationStatus: parsed.validationStatus,
        compatibility: parsed.compatibility,
        requestedToolNames: parsed.requestedToolNames,
        diagnostics: parsed.diagnostics,
        hasScripts: parsed.hasScripts,
        hasReferences: parsed.hasReferences,
        hasAssets: parsed.hasAssets,
        publisherId: verification.publisherId,
        publisherName: verification.publisherName,
        signatureStatus: verification.status,
        catalogId: source.catalogId,
        catalogEntryId: source.catalogEntryId,
        updatePolicy: existing?.updatePolicy ?? SkillUpdatePolicy.manual,
        installedAt: existing?.installedAt ?? now,
        updatedAt: now,
      );
      await _localDatabase.upsertSkill(
        SkillRecord.fromDomain(descriptor).values,
      );
      await _refreshAndEmit();
      await _appendEvent(
        type:
            existing == null
                ? SkillComplianceEventType.installed
                : SkillComplianceEventType.updated,
        skillId: descriptor.id,
        contentDigest: descriptor.contentDigest,
        publisherId: descriptor.publisherId,
        decision: 'allow',
        reason: descriptor.signatureStatus.name,
      );
      if (verification.status == SkillSignatureStatus.verified) {
        await _appendEvent(
          type: SkillComplianceEventType.signatureVerified,
          skillId: descriptor.id,
          contentDigest: descriptor.contentDigest,
          publisherId: descriptor.publisherId,
          decision: 'allow',
        );
      }
      return descriptor;
    } finally {
      if (!committed) await _storageService.cleanup(staged);
    }
  }

  @override
  Future<void> uninstall(String skillId) async {
    final descriptor = await getById(skillId);
    if (descriptor == null) return;
    await _localDatabase.deleteSkill(skillId);
    await _storageService.removeInstallation(descriptor);
    await _refreshAndEmit();
    await _appendEvent(
      type: SkillComplianceEventType.uninstalled,
      skillId: descriptor.id,
      contentDigest: descriptor.contentDigest,
      publisherId: descriptor.publisherId,
      decision: 'allow',
    );
  }

  Future<void> _appendEvent({
    required SkillComplianceEventType type,
    required String skillId,
    required String contentDigest,
    required String publisherId,
    required String decision,
    String reason = '',
  }) async {
    final repository = _ecosystemRepository;
    if (repository == null) return;
    final now = DateTime.now();
    try {
      await repository.appendComplianceEvent(
        SkillComplianceEvent(
          id: '${now.microsecondsSinceEpoch}:${type.name}:$skillId',
          type: type,
          skillId: skillId,
          contentDigest: contentDigest,
          publisherId: publisherId,
          decision: decision,
          reason: reason,
          timestamp: now,
        ),
      );
    } on Object {
      // Audit storage must not change an already determined security outcome.
    }
  }

  Future<void> _refreshAndEmit() async {
    await getInstalled(forceRefresh: true);
    if (!_changes.isClosed) _changes.add(_snapshot);
  }

  List<SkillDescriptor> get _snapshot =>
      List<SkillDescriptor>.unmodifiable(_cache ?? const []);

  Future<void> dispose() => _changes.close();
}
