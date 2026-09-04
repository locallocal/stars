import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:stars/data/services/ai/built_in_model_catalog.dart';
import 'package:stars/data/services/ai/provider_transport.dart';
import 'package:stars/data/services/image_media_type.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';

export 'package:stars/domain/models/ai_models.dart';
export 'package:stars/domain/models/ai_model_info.dart';

extension ChatMessageJson on ChatMessage {
  Map<String, Object> toJson() => {'role': role, 'content': content};
}

/// Shared implementation helpers for vendor-specific AI service adapters.
abstract class Provider extends AiProvider {
  Provider(super.bot);

  ModelTokenUsage _capturedTokenUsage = ModelTokenUsage.empty;

  /// Decodes a provider response and extracts token usage when the response
  /// exposes one of the common OpenAI, Anthropic, Gemini, or Ollama shapes.
  dynamic decodeProviderResponse(String source) {
    final decoded = jsonDecode(source);
    _captureTokenUsage(decoded);
    return decoded;
  }

  /// Maps model metadata returned by a provider catalog endpoint.
  ///
  /// Missing fields remain unknown unless the exact first-party model ID is in
  /// [BuiltInModelCatalog]. This method never reads [Bot.parameters] or guesses
  /// capabilities from model-name patterns.
  AiModelInfo providerModelInfo(Map<String, dynamic> model, {String? modelId}) {
    final architecture = _stringMap(model['architecture']);
    final topProvider = _stringMap(model['top_provider']);
    final supportedParameters = _stringSet(model['supported_parameters']);
    final capabilities = _stringSet(model['capabilities']);

    final info = AiModelInfo(
      modelId:
          modelId ??
          _firstString(model, const ['id', 'name', 'baseModelId']) ??
          (throw const FormatException('Provider model is missing an id')),
      providerId: bot.apiType,
      inputModalities: _inputModalities(
        architecture?['input_modalities'] ??
            model['input_modalities'] ??
            model['supportedInputTypes'],
      ),
      outputModalities: _outputModalities(
        architecture?['output_modalities'] ??
            model['output_modalities'] ??
            model['supportedOutputTypes'],
      ),
      supportsWebSearch:
          _firstBool(model, const [
            'supports_web_search',
            'supportsWebSearch',
          ]) ??
          _setCapability(supportedParameters, const {
            'web_search',
            'web_search_options',
          }),
      supportsDeepThinking:
          _firstBool(model, const [
            'thinking',
            'supports_deep_thinking',
            'supportsDeepThinking',
          ]) ??
          _setCapability(supportedParameters, const {
            'reasoning',
            'include_reasoning',
          }),
      supportsDeepResearch: _firstBool(model, const [
        'supports_deep_research',
        'supportsDeepResearch',
      ]),
      supportsMcp:
          _firstBool(model, const ['supports_mcp', 'supportsMcp']) ??
          _setCapability(supportedParameters, const {'tools', 'tool_choice'}) ??
          _setCapability(capabilities, const {'tools', 'tool_calling'}),
      supportsSkills:
          _firstBool(model, const ['supports_skills', 'supportsSkills']) ??
          _setCapability(supportedParameters, const {'tools', 'tool_choice'}) ??
          _setCapability(capabilities, const {'tools', 'tool_calling'}),
      supportsAutomaticSkillActivation:
          _firstBool(model, const [
            'supports_automatic_skill_activation',
            'supportsAutomaticSkillActivation',
          ]) ??
          _setCapability(supportedParameters, const {'tools', 'tool_choice'}) ??
          _setCapability(capabilities, const {'tools', 'tool_calling'}),
      supportsHostedSkills: _firstBool(model, const [
        'supports_hosted_skills',
        'supportsHostedSkills',
      ]),
      taskType: _modelTaskType(
        _firstString(model, const ['task_type', 'taskType', 'type']),
      ),
      lifecycle: _modelLifecycle(
        _firstString(model, const ['lifecycle', 'status']),
      ),
      currentSnapshot: _firstString(model, const [
        'current_snapshot',
        'currentSnapshot',
      ]),
      contextWindowTokens:
          _firstPositiveInt(model, const [
            'context_length',
            'contextWindowTokens',
            'inputTokenLimit',
          ]) ??
          _firstPositiveInt(topProvider, const ['context_length']),
      maxInputTokens: _firstPositiveInt(model, const [
        'max_input_tokens',
        'maxInputTokens',
      ]),
      maxOutputTokens:
          _firstPositiveInt(model, const [
            'max_output_length',
            'maxOutputTokens',
            'outputTokenLimit',
          ]) ??
          _firstPositiveInt(topProvider, const ['max_completion_tokens']),
      knowledgeCutoff: _providerDate(
        model['knowledge_cutoff'] ?? model['knowledgeCutoff'],
      ),
      releaseDate: _providerDate(
        model['created'] ?? model['created_at'] ?? model['release_date'],
      ),
      supportedEndpoints: _modelEndpoints(
        model['supported_endpoints'] ?? model['supportedEndpoints'],
      ),
      reasoningEfforts: _stringList(
        model['reasoning_efforts'] ?? model['reasoningEfforts'],
      ),
      supportedFeatures:
          _stringSet(
            model['supported_features'] ?? model['supportedFeatures'],
          ) ??
          const {},
      nativeTools:
          _stringSet(model['native_tools'] ?? model['nativeTools']) ?? const {},
    );
    return _builtInProviderId == null ? info : BuiltInModelCatalog.enrich(info);
  }

  List<AiModelInfo> providerModelInfos(
    Object? source, {
    String? Function(Map<String, dynamic> model)? modelId,
  }) {
    if (source is! List) {
      throw const FormatException('Provider model catalog is not a list');
    }
    final models = source
        .whereType<Map>()
        .map((raw) {
          final model = Map<String, dynamic>.from(raw);
          return providerModelInfo(model, modelId: modelId?.call(model));
        })
        .toList(growable: false);
    final providerId = _builtInProviderId;
    return providerId == null ||
            BuiltInModelCatalog.modelsFor(providerId).isEmpty
        ? models
        : BuiltInModelCatalog.merge(providerId, models);
  }

  /// Returns curated metadata for the currently selected model, when known.
  AiModelInfo? builtInModelInfo() {
    final providerId = _builtInProviderId;
    return providerId == null
        ? null
        : BuiltInModelCatalog.find(providerId, bot.model);
  }

  @override
  bool supportMcp() {
    final configured = bot.configuredSupportsMcp;
    final modelSupportsMcp =
        configured ?? (builtInModelInfo()?.supportsMcp == true);
    return modelSupportsMcp && capabilities.supportsAgentLoop;
  }

  /// Several compatible services reuse the OpenAI adapter. Do not inject
  /// first-party OpenAI models into their catalogs.
  String? get _builtInProviderId {
    if (bot.apiType == Bot.apiTypeOpenAI &&
        bot.provider.toLowerCase() != Bot.apiTypeOpenAI) {
      return null;
    }
    return bot.apiType;
  }

  /// Sends a streaming request through an OpenAI-compatible Responses API.
  /// This is required for server-side tools such as first-party web search.
  Future<void> generateResponsesText({
    required String url,
    required Map<String, String> headers,
    required List<ChatMessage> messages,
    List<Map<String, dynamic>>? formattedInput,
    Map<String, Object>? reasoning,
    bool includeWebSearch = true,
    http.Client? client,
  }) async {
    final requestClient = client ?? http.Client();
    final closeClient = client == null;
    final uri = Uri.parse(url);
    final body = jsonEncode({
      'model': bot.model,
      'input': formattedInput ?? _responsesInput(messages),
      'stream': true,
      if (includeWebSearch)
        'tools': [
          {'type': 'web_search'},
        ],
      if (reasoning != null) 'reasoning': reasoning,
    });

    try {
      cancelController?.stream.listen((_) => requestClient.close());

      final streamedResponse = await sendProviderStreamRequest(
        send: () {
          final request =
              http.Request('POST', uri)
                ..headers.addAll(headers)
                ..body = body;
          return requestClient.send(request);
        },
        endpointKind: ProviderEndpointKind.responses,
        timeout: const Duration(seconds: 60),
      );

      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in stream) {
        if (isCancelled) return;
        if (!line.startsWith('data: ')) continue;

        final jsonSource = line.substring(6).trim();
        if (jsonSource.isEmpty || jsonSource == '[DONE]') continue;
        final data = decodeProviderResponse(jsonSource);
        switch (data['type']) {
          case 'response.output_text.delta':
            final delta = data['delta']?.toString() ?? '';
            if (delta.isNotEmpty) onResponse(delta);
          case 'response.reasoning_summary_text.delta':
            final delta = data['delta']?.toString() ?? '';
            if (deepThinking &&
                delta.isNotEmpty &&
                onReasoningResponse != null) {
              onReasoningResponse!(delta);
            }
          case 'response.failed':
          case 'error':
            throw ProviderFailure.invalidResponse(
              endpointKind: ProviderEndpointKind.responses,
              code: 'provider_stream_error',
            );
        }
      }
    } finally {
      if (closeClient) requestClient.close();
    }
  }

  List<Map<String, dynamic>> _responsesInput(List<ChatMessage> messages) {
    return messages
        .map((message) {
          if (message.images.isEmpty) return message.toJson();

          final content = <Map<String, dynamic>>[];
          if (message.content.isNotEmpty) {
            content.add({'type': 'input_text', 'text': message.content});
          }
          for (final imagePath in message.images) {
            final file = File(imagePath);
            if (!file.existsSync()) continue;
            final bytes = file.readAsBytesSync();
            content.add({
              'type': 'input_image',
              'image_url':
                  'data:${getImageMediaType(bytes)};base64,${base64Encode(bytes)}',
            });
          }
          return {'role': message.role, 'content': content};
        })
        .toList(growable: false);
  }

  @override
  void resetCancelState() {
    _capturedTokenUsage = ModelTokenUsage.empty;
    super.resetCancelState();
  }

  void _captureTokenUsage(Object? payload) {
    final usage = _findTokenUsage(payload);
    if (usage == null || !usage.hasData) return;
    _capturedTokenUsage = _capturedTokenUsage.merge(usage);
    onTokenUsage?.call(_capturedTokenUsage);
  }

  ModelTokenUsage? _findTokenUsage(Object? value) {
    if (value is List) {
      for (final item in value) {
        final usage = _findTokenUsage(item);
        if (usage != null) return usage;
      }
      return null;
    }
    if (value is! Map) return null;

    final map = value.cast<Object?, Object?>();
    final direct = _tokenUsageFromMap(map);
    if (direct != null) return direct;

    const preferredKeys = <String>[
      'usage',
      'usageMetadata',
      'usage_metadata',
      'token_usage',
      'message',
    ];
    for (final key in preferredKeys) {
      final usage = _findTokenUsage(map[key]);
      if (usage != null) return usage;
    }
    for (final nested in map.values) {
      final usage = _findTokenUsage(nested);
      if (usage != null) return usage;
    }
    return null;
  }

  ModelTokenUsage? _tokenUsageFromMap(Map<Object?, Object?> map) {
    final input = _firstCount(map, const <String>[
      'input_tokens',
      'inputTokens',
      'inputTokenCount',
      'prompt_tokens',
      'promptTokens',
      'promptTokenCount',
      'prompt_eval_count',
    ]);
    final output = _firstCount(map, const <String>[
      'output_tokens',
      'outputTokens',
      'outputTokenCount',
      'completion_tokens',
      'completionTokens',
      'completionTokenCount',
      'candidatesTokenCount',
      'eval_count',
    ]);
    final total = _firstCount(map, const <String>[
      'total_tokens',
      'totalTokens',
      'totalTokenCount',
    ]);
    if (input == null && output == null && total == null) return null;

    return ModelTokenUsage(
      model: bot.model,
      inputTokens: input ?? 0,
      outputTokens: output ?? 0,
      totalTokens: total ?? 0,
    );
  }

  int? _firstCount(Map<Object?, Object?> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      final count = switch (value) {
        final int count => count,
        final num count => count.toInt(),
        _ => int.tryParse(value?.toString() ?? ''),
      };
      if (count != null && count >= 0) return count;
    }
    return null;
  }

  List<Map<String, dynamic>> processMessagesWithImages(
    List<ChatMessage> messages,
  ) {
    return messages.map((message) {
      if (message.images.isEmpty) return message.toJson();

      final content = <Map<String, dynamic>>[];
      if (message.content.isNotEmpty) {
        content.add({'type': 'text', 'text': message.content});
      }

      for (final imagePath in message.images) {
        try {
          final file = File(imagePath);
          if (file.existsSync()) {
            final base64Image = base64Encode(file.readAsBytesSync());
            content.add({
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
            });
          }
        } catch (error) {
          throw Exception('Process image $imagePath failed: $error');
        }
      }
      return {'role': message.role, 'content': content};
    }).toList();
  }

  String getImageMediaType(List<int> bytes) {
    return detectImageMediaType(bytes) ?? 'application/octet-stream';
  }

  String transformRatio(int width, int height) {
    final divisor = _calculateGreatestCommonDivisor(width, height);
    return '${width ~/ divisor}:${height ~/ divisor}';
  }

  int _calculateGreatestCommonDivisor(int left, int right) {
    while (right != 0) {
      final remainder = left % right;
      left = right;
      right = remainder;
    }
    return left;
  }
}

Map<String, dynamic>? _stringMap(Object? value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}

String? _firstString(Map<String, dynamic> values, List<String> keys) {
  for (final key in keys) {
    final value = values[key];
    if (value is String && value.isNotEmpty) return value;
  }
  return null;
}

bool? _firstBool(Map<String, dynamic>? values, List<String> keys) {
  if (values == null) return null;
  for (final key in keys) {
    final value = values[key];
    if (value is bool) return value;
  }
  return null;
}

int? _firstPositiveInt(Map<String, dynamic>? values, List<String> keys) {
  if (values == null) return null;
  for (final key in keys) {
    final value = values[key];
    final parsed = switch (value) {
      int() => value,
      num() when value.isFinite && value == value.roundToDouble() =>
        value.toInt(),
      String() => int.tryParse(value),
      _ => null,
    };
    if (parsed != null && parsed > 0) return parsed;
  }
  return null;
}

Set<String>? _stringSet(Object? value) {
  if (value is! List) return null;
  return value.whereType<String>().map((item) => item.toLowerCase()).toSet();
}

List<String> _stringList(Object? value) =>
    value is List
        ? value.whereType<String>().toList(growable: false)
        : const [];

AiModelTaskType? _modelTaskType(String? value) {
  if (value == null) return null;
  final normalized = value.toLowerCase().replaceAll('-', '_');
  for (final taskType in AiModelTaskType.values) {
    if (taskType.value == normalized) return taskType;
  }
  return null;
}

AiModelLifecycle? _modelLifecycle(String? value) {
  if (value == null) return null;
  final normalized = value.toLowerCase();
  for (final lifecycle in AiModelLifecycle.values) {
    if (lifecycle.value == normalized) return lifecycle;
  }
  return null;
}

List<AiModelEndpoint> _modelEndpoints(Object? value) {
  final names = _stringSet(value) ?? const <String>{};
  return [
    for (final endpoint in AiModelEndpoint.values)
      if (names.contains(endpoint.value)) endpoint,
  ];
}

bool? _setCapability(Set<String>? values, Set<String> supportedValues) {
  if (values == null) return null;
  return values.any(supportedValues.contains);
}

List<InputModality> _inputModalities(Object? value) {
  final names = _stringSet(value) ?? const <String>{};
  return [
    for (final modality in InputModality.values)
      if (names.contains(modality.value)) modality,
  ];
}

List<OutputModality> _outputModalities(Object? value) {
  final names = _stringSet(value) ?? const <String>{};
  return [
    for (final modality in OutputModality.values)
      if (names.contains(modality.value)) modality,
  ];
}

DateTime? _providerDate(Object? value) {
  if (value is num) {
    final raw = value.toInt();
    final milliseconds = raw.abs() < 100000000000 ? raw * 1000 : raw;
    try {
      return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
    } on ArgumentError {
      return null;
    }
  }
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  return null;
}
