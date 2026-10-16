import 'package:stars/data/services/skills/skill_source_resolver.dart';
import 'package:stars/domain/models/models.dart';

final class ResolveSkillSourceTool implements ExecutableTool {
  ResolveSkillSourceTool({required SkillSourceResolver resolver})
    : _resolver = resolver;

  final SkillSourceResolver _resolver;

  @override
  final ToolDefinition definition = ToolDefinition(
    name: resolveSkillSourceToolName,
    title: 'Resolve Skill Source',
    description:
        'Resolve ModelScope Skill/collection URLs, npx skills add commands, '
        'official ModelScope curl install.sh commands, GitHub sources, and '
        'ZIP/local paths into install_skill inputs for Stars. Reads all '
        'collection pages. Does not install packages or execute commands.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'source': {'type': 'string', 'minLength': 1, 'maxLength': 4096},
        'skill_names': {
          'type': 'array',
          'minItems': 1,
          'items': {'type': 'string', 'minLength': 1},
          'description':
              'Only when the user requests specific Skills. Omit to resolve the entire collection.',
        },
      },
      'required': ['source'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'destination': {
          'type': 'string',
          'enum': ['stars'],
        },
        'count': {'type': 'integer', 'minimum': 1},
        'skills': {
          'type': 'array',
          'minItems': 1,
          'items': {
            'type': 'object',
            'properties': {
              'name': {
                'type': 'string',
                'description': 'Unverified source name hint.',
              },
              'source_type': {
                'type': 'string',
                'enum': ['github', 'zip_url', 'local_zip', 'local_directory'],
              },
              'source': {'type': 'string', 'minLength': 1},
              'ref': {'type': 'string'},
              'subdirectory': {'type': 'string'},
            },
            'required': ['name', 'source_type', 'source'],
            'additionalProperties': false,
          },
        },
      },
      'required': ['destination', 'count', 'skills'],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.readOnly,
    capabilities: const {ToolCapability.network, ToolCapability.externalRead},
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final source = call.arguments['source'];
    final selection = call.arguments['skill_names'];
    if (source is! String ||
        call.arguments.keys.any(
          (key) => !{'source', 'skill_names'}.contains(key),
        ) ||
        (call.arguments.containsKey('skill_names') &&
            (selection is! List<Object?> ||
                selection.isEmpty ||
                selection.any(
                  (name) => name is! String || name.trim().isEmpty,
                )))) {
      return _error(call, 'Skill 来源参数无效。', 'invalid_skill_source');
    }
    try {
      final resolved = await _resolver.resolve(source, cancellationToken);
      final selectedNames =
          selection == null
              ? null
              : (selection as List<Object?>)
                  .cast<String>()
                  .map((name) => name.trim())
                  .toSet();
      if (selectedNames != null &&
          !resolved
              .map((skill) => skill.name)
              .toSet()
              .containsAll(selectedNames)) {
        return _error(
          call,
          '指定的 Skill 未全部出现在完整来源列表中。',
          'skill_source_rejected',
        );
      }
      final skills =
          selectedNames == null
              ? resolved
              : resolved
                  .where((skill) => selectedNames.contains(skill.name))
                  .toList();
      if (skills.isEmpty) {
        return _error(
          call,
          '未解析到可安装的 Skill。',
          'skill_source_resolution_failed',
        );
      }
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content:
            'Resolved ${skills.length} Skill source(s) for Stars. No Skills installed.',
        structuredContent: {
          'destination': 'stars',
          'count': skills.length,
          'skills': [for (final skill in skills) skill.toJson()],
        },
      );
    } on AgentRunCancelledException {
      rethrow;
    } on SkillInstallException catch (error) {
      return _error(call, error.message, 'skill_source_rejected');
    } on FormatException {
      return _error(call, 'Skill 来源格式无效。', 'invalid_skill_source');
    } on Object {
      return _error(call, 'Skill 来源解析失败。', 'skill_source_resolution_failed');
    }
  }

  ToolResult _error(ToolCallRequest call, String message, String code) =>
      ToolResult(
        callId: call.callId,
        name: call.name,
        content: message,
        isError: true,
        errorCode: code,
      );
}
