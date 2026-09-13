import 'package:stars/domain/models/bot.dart';
import 'package:stars/domain/models/mcp.dart';
import 'package:stars/domain/models/modalities.dart';

/// Versioned, secret-free representation of a Bot configuration.
final class BotExportDocument {
  BotExportDocument({
    required this.name,
    required this.provider,
    required this.baseUrl,
    required this.apiType,
    required this.model,
    required this.systemPrompt,
    this.supportsMcp,
    this.supportsAutomaticSkillActivation,
    this.supportsSkills,
    this.contextWindowTokens,
    List<InputModality>? inputModalities,
    List<OutputModality>? outputModalities,
    List<String> mcpServerIds = const [],
    List<McpToolConfiguration> mcpTools = const [],
  }) : inputModalities =
           inputModalities == null
               ? null
               : List<InputModality>.unmodifiable(inputModalities),
       outputModalities =
           outputModalities == null
               ? null
               : List<OutputModality>.unmodifiable(outputModalities),
       mcpServerIds = List<String>.unmodifiable(
         mcpServerIds.toSet().toList()..sort(),
       ),
       mcpTools = List<McpToolConfiguration>.unmodifiable(
         List<McpToolConfiguration>.of(mcpTools)
           ..sort((left, right) => left.key.compareTo(right.key)),
       ) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'cannot be empty');
    }
    final configuredContextWindowTokens = contextWindowTokens;
    if (configuredContextWindowTokens != null &&
        configuredContextWindowTokens <= 0) {
      throw ArgumentError.value(
        configuredContextWindowTokens,
        'contextWindowTokens',
        'must be positive',
      );
    }
    if (this.mcpServerIds.any((id) => id.trim().isEmpty)) {
      throw ArgumentError.value(mcpServerIds, 'mcpServerIds', 'contains empty');
    }
  }

  factory BotExportDocument.fromBot(Bot bot) {
    final serverIds = bot.mcpServerIds.toList()..sort();
    final tools =
        bot.mcpTools.toList()
          ..sort((left, right) => left.key.compareTo(right.key));
    return BotExportDocument(
      name: bot.name,
      provider: bot.provider,
      baseUrl: bot.baseURL,
      apiType: bot.apiType,
      model: bot.model,
      systemPrompt: bot.systemPrompt,
      supportsMcp: bot.configuredSupportsMcp,
      supportsAutomaticSkillActivation:
          bot.configuredSupportsAutomaticSkillActivation,
      supportsSkills: bot.configuredSupportsSkills,
      contextWindowTokens: bot.configuredContextWindowTokens,
      inputModalities: bot.configuredInputModalities,
      outputModalities: bot.configuredOutputModalities,
      mcpServerIds: serverIds,
      mcpTools: tools,
    );
  }

  factory BotExportDocument.fromJson(Map<String, Object?> json) {
    _requireExactKeys(json, const {'format', 'version', 'bot'}, 'document');
    if (json['format'] != format || json['version'] != currentVersion) {
      throw const FormatException('Unsupported Bot export format.');
    }

    final bot = _requiredMap(json, 'bot');
    _requireExactKeys(bot, const {
      'name',
      'provider',
      'base_url',
      'api_type',
      'model',
      'system_prompt',
      'capabilities',
      'mcp',
    }, 'bot');
    final capabilities = _requiredMap(bot, 'capabilities');
    _requireExactKeys(capabilities, const {
      'supports_mcp',
      'supports_automatic_skill_activation',
      'supports_skills',
      'context_window_tokens',
      'input_modalities',
      'output_modalities',
    }, 'capabilities');
    final mcp = _requiredMap(bot, 'mcp');
    _requireExactKeys(mcp, const {'server_ids', 'tools'}, 'mcp');

    final name = _requiredString(bot, 'name').trim();
    if (name.isEmpty) {
      throw const FormatException('Bot name cannot be empty.');
    }
    final contextWindowTokens = _optionalInt(
      capabilities,
      'context_window_tokens',
    );
    if (contextWindowTokens != null && contextWindowTokens <= 0) {
      throw const FormatException('Context window must be positive.');
    }

    return BotExportDocument(
      name: name,
      provider: _requiredString(bot, 'provider'),
      baseUrl: _requiredString(bot, 'base_url'),
      apiType: _requiredString(bot, 'api_type'),
      model: _requiredString(bot, 'model'),
      systemPrompt: _requiredString(bot, 'system_prompt'),
      supportsMcp: _optionalBool(capabilities, 'supports_mcp'),
      supportsAutomaticSkillActivation: _optionalBool(
        capabilities,
        'supports_automatic_skill_activation',
      ),
      supportsSkills: _optionalBool(capabilities, 'supports_skills'),
      contextWindowTokens: contextWindowTokens,
      inputModalities: _optionalInputModalities(capabilities),
      outputModalities: _optionalOutputModalities(capabilities),
      mcpServerIds: _requiredStringList(mcp, 'server_ids'),
      mcpTools: _requiredMapList(mcp, 'tools')
          .map((tool) {
            _requireExactKeys(tool, const {
              'server_id',
              'remote_name',
              'requires_approval',
            }, 'MCP tool');
            return McpToolConfiguration.fromMap(tool);
          })
          .toList(growable: false),
    );
  }

  static const String format = 'stars.bot';
  static const int currentVersion = 1;

  final String name;
  final String provider;
  final String baseUrl;
  final String apiType;
  final String model;
  final String systemPrompt;
  final bool? supportsMcp;
  final bool? supportsAutomaticSkillActivation;
  final bool? supportsSkills;
  final int? contextWindowTokens;
  final List<InputModality>? inputModalities;
  final List<OutputModality>? outputModalities;
  final List<String> mcpServerIds;
  final List<McpToolConfiguration> mcpTools;

  /// Creates a new local Bot. Secrets and device-local avatar paths are empty.
  Bot toImportedBot({required String id, required DateTime timestamp}) {
    return Bot(
      id: id,
      name: name.trim(),
      avatar: '',
      provider: provider.trim(),
      baseURL: baseUrl.trim(),
      apiKey: '',
      apiType: apiType.trim(),
      model: model.trim(),
      systemPrompt: systemPrompt,
      parameters: <String, Object?>{
        if (supportsMcp != null) Bot.parameterSupportsMcp: supportsMcp,
        if (supportsAutomaticSkillActivation != null)
          Bot.parameterSupportsAutomaticSkillActivation:
              supportsAutomaticSkillActivation,
        if (supportsSkills != null) Bot.parameterSupportsSkills: supportsSkills,
        if (contextWindowTokens != null)
          Bot.parameterContextWindowTokens: contextWindowTokens,
        if (inputModalities != null)
          Bot.parameterInputModalities: [
            for (final modality in inputModalities!) modality.value,
          ],
        if (outputModalities != null)
          Bot.parameterOutputModalities: [
            for (final modality in outputModalities!) modality.value,
          ],
        Bot.parameterMcpServers: mcpServerIds,
        Bot.parameterMcpTools: [for (final tool in mcpTools) tool.toMap()],
      },
      createTimestamp: timestamp,
      modifyTimestamp: timestamp,
    );
  }

  /// Converts this document to a JSON-compatible map without credentials.
  Map<String, Object?> toJson() => <String, Object?>{
    'format': format,
    'version': currentVersion,
    'bot': <String, Object?>{
      'name': name,
      'provider': provider,
      'base_url': baseUrl,
      'api_type': apiType,
      'model': model,
      'system_prompt': systemPrompt,
      'capabilities': <String, Object?>{
        'supports_mcp': supportsMcp,
        'supports_automatic_skill_activation': supportsAutomaticSkillActivation,
        'supports_skills': supportsSkills,
        'context_window_tokens': contextWindowTokens,
        'input_modalities':
            inputModalities == null
                ? null
                : [for (final modality in inputModalities!) modality.value],
        'output_modalities':
            outputModalities == null
                ? null
                : [for (final modality in outputModalities!) modality.value],
      },
      'mcp': <String, Object?>{
        'server_ids': mcpServerIds,
        'tools': [for (final tool in mcpTools) tool.toMap()],
      },
    },
  };
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  throw FormatException('Bot export field "$key" must be an object.');
}

List<Map<String, Object?>> _requiredMapList(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('Bot export field "$key" must be a list.');
  }
  return value
      .map((item) {
        if (item is! Map) {
          throw FormatException(
            'Bot export field "$key" must contain objects.',
          );
        }
        return item.map((key, value) => MapEntry(key.toString(), value));
      })
      .toList(growable: false);
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Bot export field "$key" must be text.');
}

bool? _optionalBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null || value is bool) return value as bool?;
  throw FormatException('Bot export field "$key" must be a boolean.');
}

int? _optionalInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null || value is int) return value as int?;
  throw FormatException('Bot export field "$key" must be an integer.');
}

List<String> _requiredStringList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('Bot export field "$key" must contain text.');
  }
  final items = value.cast<String>();
  if (items.any((item) => item.trim().isEmpty)) {
    throw FormatException('Bot export field "$key" contains empty text.');
  }
  return items.toSet().toList(growable: false)..sort();
}

List<InputModality>? _optionalInputModalities(Map<String, Object?> json) {
  final names = _optionalStringList(json, 'input_modalities');
  if (names == null) return null;
  return names
      .map((name) {
        return InputModality.values.firstWhere(
          (modality) => modality.value == name,
          orElse:
              () => throw FormatException('Unknown input modality "$name".'),
        );
      })
      .toList(growable: false);
}

List<OutputModality>? _optionalOutputModalities(Map<String, Object?> json) {
  final names = _optionalStringList(json, 'output_modalities');
  if (names == null) return null;
  return names
      .map((name) {
        return OutputModality.values.firstWhere(
          (modality) => modality.value == name,
          orElse:
              () => throw FormatException('Unknown output modality "$name".'),
        );
      })
      .toList(growable: false);
}

List<String>? _optionalStringList(Map<String, Object?> json, String key) {
  if (json[key] == null) return null;
  return _requiredStringList(json, key);
}

void _requireExactKeys(
  Map<String, Object?> json,
  Set<String> expected,
  String section,
) {
  if (json.length != expected.length || !expected.containsAll(json.keys)) {
    throw FormatException('Unexpected fields in Bot export $section.');
  }
}
