import 'dart:convert';

import 'package:stars/domain/models/models.dart';

final class SkillRecord {
  const SkillRecord(this.values);

  factory SkillRecord.fromDomain(SkillDescriptor skill) {
    return SkillRecord({
      'id': skill.id,
      'name': skill.name,
      'description': skill.description,
      'version': skill.version,
      'scope': skill.scope.name,
      'source_uri': skill.sourceUri,
      'root_path': skill.rootPath,
      'content_digest': skill.contentDigest,
      'trust_state': skill.trustState.name,
      'validation_status': skill.validationStatus.name,
      'compatibility': skill.compatibility,
      'requested_tools_json': jsonEncode(
        skill.requestedToolNames.toList()..sort(),
      ),
      'diagnostics_json': jsonEncode(
        skill.diagnostics.map((item) => item.toMap()).toList(),
      ),
      'has_scripts': skill.hasScripts ? 1 : 0,
      'has_references': skill.hasReferences ? 1 : 0,
      'has_assets': skill.hasAssets ? 1 : 0,
      'publisher_id': skill.publisherId,
      'publisher_name': skill.publisherName,
      'signature_status': skill.signatureStatus.name,
      'catalog_id': skill.catalogId,
      'catalog_entry_id': skill.catalogEntryId,
      'update_policy': skill.updatePolicy.name,
      'installed_at': skill.installedAt.millisecondsSinceEpoch,
      'updated_at': skill.updatedAt.millisecondsSinceEpoch,
    });
  }

  final Map<String, Object?> values;

  SkillDescriptor toDomain() {
    return SkillDescriptor(
      id: _text('id'),
      name: _text('name'),
      description: _text('description'),
      version: _text('version'),
      scope: _enumValue(SkillScope.values, _text('scope'), 'scope'),
      sourceUri: _text('source_uri'),
      rootPath: _text('root_path'),
      contentDigest: _text('content_digest'),
      trustState: _enumValue(
        SkillTrustState.values,
        _text('trust_state'),
        'trust_state',
      ),
      validationStatus: _enumValue(
        SkillValidationStatus.values,
        _text('validation_status'),
        'validation_status',
      ),
      compatibility: _text('compatibility'),
      requestedToolNames: _decodeStringSet(_text('requested_tools_json')),
      diagnostics: _decodeDiagnostics(_text('diagnostics_json')),
      hasScripts: _bool(values['has_scripts'], 'has_scripts'),
      hasReferences: _bool(values['has_references'], 'has_references'),
      hasAssets: _bool(values['has_assets'], 'has_assets'),
      publisherId: _text('publisher_id'),
      publisherName: _text('publisher_name'),
      signatureStatus: _enumValue(
        SkillSignatureStatus.values,
        _text('signature_status'),
        'signature_status',
      ),
      catalogId: _text('catalog_id'),
      catalogEntryId: _text('catalog_entry_id'),
      updatePolicy: _enumValue(
        SkillUpdatePolicy.values,
        _text('update_policy'),
        'update_policy',
      ),
      installedAt: DateTime.fromMillisecondsSinceEpoch(
        _integer('installed_at'),
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(_integer('updated_at')),
    );
  }

  String _text(String key) => _requiredText(values[key], key);

  int _integer(String key) {
    final value = values[key];
    return _requiredInteger(value, key);
  }
}

final class BotSkillBindingRecord {
  const BotSkillBindingRecord(this.values);

  factory BotSkillBindingRecord.fromDomain(BotSkillBinding binding) {
    return BotSkillBindingRecord({
      'bot_id': binding.botId,
      'skill_id': binding.skillId,
      'enabled': binding.enabled ? 1 : 0,
      'requires_approval': binding.requiresApproval ? 1 : 0,
      'activation_mode': binding.activationMode.name,
      'priority': binding.priority,
      'created_at': binding.createdAt.millisecondsSinceEpoch,
      'updated_at': binding.updatedAt.millisecondsSinceEpoch,
    });
  }

  final Map<String, Object?> values;

  BotSkillBinding toDomain() {
    return BotSkillBinding(
      botId: _requiredText(values['bot_id'], 'bot_id'),
      skillId: _requiredText(values['skill_id'], 'skill_id'),
      enabled: _bool(values['enabled'], 'enabled'),
      requiresApproval: _bool(values['requires_approval'], 'requires_approval'),
      activationMode: _enumValue(
        SkillActivationMode.values,
        _requiredText(values['activation_mode'], 'activation_mode'),
        'activation_mode',
      ),
      priority: _requiredInteger(values['priority'], 'priority'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        _requiredInteger(values['created_at'], 'created_at'),
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        _requiredInteger(values['updated_at'], 'updated_at'),
      ),
    );
  }
}

final class SkillActivationDbRecord {
  const SkillActivationDbRecord(this.values);

  factory SkillActivationDbRecord.fromDomain(SkillActivationRecord record) {
    return SkillActivationDbRecord({
      'id': record.id,
      'run_id': record.runId,
      'chat_id': record.chatId,
      'message_id': record.messageId,
      'skill_id': record.skillId,
      'skill_name': record.skillName,
      'content_digest': record.contentDigest,
      'trigger_type': record.trigger.name,
      'status': record.status.name,
      'duration_ms': record.durationMs,
      'error_code': record.errorCode,
      'started_at': record.startedAt.millisecondsSinceEpoch,
      'completed_at': record.completedAt?.millisecondsSinceEpoch,
    });
  }

  final Map<String, Object?> values;

  SkillActivationRecord toDomain() {
    final completedAt = _nullableInteger(
      values['completed_at'],
      'completed_at',
    );
    return SkillActivationRecord(
      id: _requiredText(values['id'], 'id'),
      runId: _requiredText(values['run_id'], 'run_id'),
      chatId: _requiredText(values['chat_id'], 'chat_id'),
      messageId: _requiredText(values['message_id'], 'message_id'),
      skillId: _requiredText(values['skill_id'], 'skill_id'),
      skillName: _requiredText(values['skill_name'], 'skill_name'),
      contentDigest: _requiredText(values['content_digest'], 'content_digest'),
      trigger: _enumValue(
        SkillActivationTrigger.values,
        _requiredText(values['trigger_type'], 'trigger_type'),
        'trigger_type',
      ),
      status: _enumValue(
        SkillActivationStatus.values,
        _requiredText(values['status'], 'status'),
        'status',
      ),
      durationMs: _nullableInteger(values['duration_ms'], 'duration_ms'),
      errorCode: _requiredText(values['error_code'], 'error_code'),
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        _requiredInteger(values['started_at'], 'started_at'),
      ),
      completedAt:
          completedAt == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(completedAt),
    );
  }
}

final class ConversationSkillPinRecord {
  const ConversationSkillPinRecord(this.values);

  factory ConversationSkillPinRecord.fromDomain(ConversationSkillPin pin) {
    return ConversationSkillPinRecord({
      'chat_id': pin.chatId,
      'skill_id': pin.skillId,
      'created_at': pin.createdAt.millisecondsSinceEpoch,
    });
  }

  final Map<String, Object?> values;

  ConversationSkillPin toDomain() {
    return ConversationSkillPin(
      chatId: _requiredText(values['chat_id'], 'chat_id'),
      skillId: _requiredText(values['skill_id'], 'skill_id'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        _requiredInteger(values['created_at'], 'created_at'),
      ),
    );
  }
}

T _enumValue<T extends Enum>(List<T> values, String name, String field) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Skill record field "$field" has an unknown value.');
}

String _requiredText(Object? value, String field) {
  if (value is String) return value;
  throw FormatException('Skill record field "$field" must be a string.');
}

int _requiredInteger(Object? value, String field) {
  if (value is int) return value;
  throw FormatException('Skill record field "$field" must be an integer.');
}

int? _nullableInteger(Object? value, String field) {
  if (value == null || value is int) return value as int?;
  throw FormatException(
    'Skill record field "$field" must be an integer or null.',
  );
}

bool _bool(Object? value, String field) {
  return switch (value) {
    0 => false,
    1 => true,
    _ => throw FormatException('Skill record field "$field" must be 0 or 1.'),
  };
}

Set<String> _decodeStringSet(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List<Object?> || decoded.any((item) => item is! String)) {
    throw const FormatException(
      'Skill requested_tools_json must contain a string list.',
    );
  }
  return decoded.cast<String>().toSet();
}

List<SkillDiagnostic> _decodeDiagnostics(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List<Object?> ||
      decoded.any(
        (item) =>
            item is! Map<Object?, Object?> ||
            item.keys.any((key) => key is! String),
      )) {
    throw const FormatException(
      'Skill diagnostics_json must contain an object list.',
    );
  }
  return decoded
      .cast<Map<Object?, Object?>>()
      .map(
        (item) => SkillDiagnostic.fromMap(
          item.map((key, value) => MapEntry(key! as String, value)),
        ),
      )
      .toList(growable: false);
}
