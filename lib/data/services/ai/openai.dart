import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:stars/data/services/ai/provider_service.dart';
import 'package:stars/data/services/ai/provider_transport.dart';
import 'package:stars/data/services/ai/skill_tool_sessions.dart';
import 'package:stars/domain/models/models.dart';

part 'openai_model_catalog.dart';
part 'openai_core_model_specs.dart';
part 'openai_specialized_model_specs.dart';

class OpenAI extends Provider {
  static const String defaultApiModelsUrl = 'https://api.openai.com/v1/models';
  static const String defaultApiChatUrl =
      'https://api.openai.com/v1/chat/completions';
  static const String defaultApiResponsesUrl =
      'https://api.openai.com/v1/responses';
  static const String defaultApiImageUrl =
      'https://api.openai.com/v1/images/generations';
  static const String defaultApiImageEditUrl =
      'https://api.openai.com/v1/images/edits';
  static const String defaultApiSpeechUrl =
      'https://api.openai.com/v1/audio/speech';
  static const String defaultApiVideosUrl = 'https://api.openai.com/v1/videos';

  OpenAI(super.bot, {http.Client? skillToolClient})
    : _skillToolClient = skillToolClient;

  final http.Client? _skillToolClient;

  static Set<String> get officialModelIds => Set<String>.unmodifiable(
    _openAiModelSpecs.values
        .where((spec) => spec.isOfficialModel)
        .map((spec) => spec.id),
  );

  static List<AiModelInfo> get documentedModels =>
      List<AiModelInfo>.unmodifiable(
        _openAiModelSpecs.values.map((spec) => spec.toModelInfo()),
      );

  @override
  AiProviderCapabilities get capabilities => AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
    supportsParallelToolCalls: true,
    supportsNativeToolEvidence: _usesResponsesApi,
  );

  @override
  AgentModelSession openModelSession(ModelRequest request) {
    if (_usesResponsesApi) {
      final uri = Uri.parse(_endpoint('responses', defaultApiResponsesUrl));
      final client = _skillToolClient ?? http.Client();
      return OpenAiResponsesAgentModelSession(
        bot: bot,
        request: request,
        formattedInput: _processMessagesForResponses(request.messages),
        uri: uri,
        headers: _headers,
        client: client,
        closeClient: _skillToolClient == null,
        decodeResponse: decodeProviderResponse,
        reasoningEffort: _selectedReasoningEffort,
      );
    }
    final uri = Uri.parse(_endpoint('chat/completions', defaultApiChatUrl));
    final client = _skillToolClient ?? http.Client();
    return OpenAiAgentModelSession(
      bot: bot,
      request: request,
      formattedMessages: processMessagesWithImages(request.messages),
      uri: uri,
      headers: _headers,
      client: client,
      closeClient: _skillToolClient == null,
      decodeResponse: decodeProviderResponse,
      reasoningEffort: _selectedReasoningEffort,
    );
  }

  @override
  SkillToolSession openSkillToolSession(SkillToolSessionRequest request) {
    if (_usesResponsesApi) {
      final uri = Uri.parse(_endpoint('responses', defaultApiResponsesUrl));
      final client = _skillToolClient ?? http.Client();
      return OpenAiResponsesSkillToolSession(
        bot: bot,
        request: request,
        formattedInput: _processMessagesForResponses(request.messages),
        uri: uri,
        headers: _headers,
        client: client,
        closeClient: _skillToolClient == null,
        decodeResponse: decodeProviderResponse,
      );
    }
    final uri = Uri.parse(_endpoint('chat/completions', defaultApiChatUrl));
    final client = _skillToolClient ?? http.Client();
    return OpenAiSkillToolSession(
      bot: bot,
      request: request,
      formattedMessages: processMessagesWithImages(request.messages),
      uri: uri,
      headers: _headers,
      client: client,
      closeClient: _skillToolClient == null,
      decodeResponse: decodeProviderResponse,
    );
  }

  @override
  bool supportWebSearch() {
    final documented = _selectedModelSpec?.supportsWebSearch;
    if (documented != null) return documented;
    return builtInModelInfo()?.supportsWebSearch ?? false;
  }

  @override
  bool supportDeepThinking() {
    final documented = _selectedModelSpec?.supportsDeepThinking;
    if (documented != null) return documented;
    return builtInModelInfo()?.supportsDeepThinking ?? false;
  }

  @override
  bool supportDeepResearch() =>
      _selectedModelSpec?.supportsDeepResearch ?? false;

  @override
  bool supportMcp() {
    final configured = bot.configuredSupportsMcp;
    final modelSupportsMcp =
        configured ??
        _selectedModelSpec?.supportsMcp ??
        builtInModelInfo()?.supportsMcp ??
        false;
    return modelSupportsMcp && capabilities.supportsAgentLoop;
  }

  @override
  List<InputModality> getInputModalites() {
    final documented = _selectedModelSpec?.inputModalities;
    if (documented != null) return documented;
    return builtInModelInfo()?.inputModalities ?? const [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    return _selectedModelSpec?.outputModalities ??
        builtInModelInfo()?.outputModalities ??
        const [OutputModality.text];
  }

  @override
  Future<List<AiModelInfo>> fetchModels() async {
    final client = _skillToolClient ?? http.Client();
    try {
      final response = await sendProviderRequest(
        send:
            () => client.get(
              Uri.parse(_endpoint('models', defaultApiModelsUrl)),
              headers: _authorizationHeaders,
            ),
        endpointKind: ProviderEndpointKind.models,
        timeout: const Duration(seconds: 10),
      );
      final data = decodeProviderResponse(utf8.decode(response.bodyBytes));
      final rawModels = data['data'];
      if (rawModels is! List) {
        throw const FormatException('OpenAI model catalog is not a list');
      }
      final liveModels = rawModels.whereType<Map>().map((raw) {
        final model = Map<String, dynamic>.from(raw);
        final live = providerModelInfo(model);
        final spec =
            _isFirstPartyOpenAi ? _findOpenAiModelSpec(live.modelId) : null;
        return spec == null ? live : spec.enrich(live);
      });

      final merged = <String, AiModelInfo>{
        for (final model in liveModels) model.modelId.toLowerCase(): model,
      };
      if (_isFirstPartyOpenAi) {
        for (final id in const [
          'gpt-5.6-sol',
          'gpt-5.6',
          'gpt-5.6-terra',
          'gpt-5.6-luna',
        ]) {
          merged.putIfAbsent(id, () => _openAiModelSpecs[id]!.toModelInfo());
        }
      }

      final selectable = merged.values
          .where((model) {
            if (!_isFirstPartyOpenAi) return true;
            final spec = _findOpenAiModelSpec(model.modelId);
            return spec == null || spec.isSelectableConversationModel;
          })
          .toList(growable: false);
      selectable.sort(_compareOpenAiModels);
      return selectable;
    } finally {
      if (_skillToolClient == null) client.close();
    }
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {
    final client = _skillToolClient ?? http.Client();
    try {
      resetCancelState();
      final spec = _selectedModelSpec;
      if (spec != null && !spec.supportsConversationGeneration) {
        throw UnsupportedError(
          'Model ${bot.model} uses ${spec.taskType.value} and cannot generate '
          'chat text.',
        );
      }

      if (_usesResponsesApi) {
        await generateResponsesText(
          url: _endpoint('responses', defaultApiResponsesUrl),
          headers: _headers,
          messages: messages,
          formattedInput: _processMessagesForResponses(messages),
          includeWebSearch: webSearch,
          reasoning:
              deepThinking && _selectedReasoningEffort != null
                  ? {'effort': _selectedReasoningEffort!, 'summary': 'auto'}
                  : null,
          client: client,
        );
        if (!isCancelled && onComplete != null) onComplete!();
        return;
      }

      final uri = Uri.parse(_endpoint('chat/completions', defaultApiChatUrl));
      final body = jsonEncode({
        'model': bot.model,
        'messages': processMessagesWithImages(messages),
        'response_format': {'type': 'text'},
        'stream': true,
        'stream_options': {'include_usage': true},
        if (webSearch && _isSearchPreviewModel)
          'web_search_options': <String, Object?>{},
        if (deepThinking && _selectedReasoningEffort != null)
          'reasoning_effort': _selectedReasoningEffort,
      });

      cancelController?.stream.listen((_) => client.close());
      final streamedResponse = await sendProviderStreamRequest(
        send: () {
          final request =
              http.Request('POST', uri)
                ..headers.addAll(_headers)
                ..body = body;
          return client.send(request);
        },
        endpointKind: ProviderEndpointKind.chatCompletions,
        timeout: const Duration(seconds: 60),
      );
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (isCancelled) break;
        if (!line.startsWith('data: ')) continue;
        final jsonSource = line.substring(6).trim();
        if (jsonSource == '[DONE]') {
          if (!isCancelled && onComplete != null) onComplete!();
          return;
        }
        if (jsonSource.isEmpty) continue;
        final data = decodeProviderResponse(jsonSource);
        final choices = data['choices'];
        if (choices is! List || choices.isEmpty || choices.first is! Map) {
          continue;
        }
        final choice = Map<String, dynamic>.from(choices.first as Map);
        final delta =
            choice['delta'] is Map
                ? Map<String, dynamic>.from(choice['delta'] as Map)
                : const <String, dynamic>{};
        final reasoning =
            delta['reasoning_content']?.toString() ??
            delta['reasoning']?.toString() ??
            '';
        if (deepThinking &&
            reasoning.isNotEmpty &&
            onReasoningResponse != null) {
          onReasoningResponse!(reasoning);
        }
        final content = delta['content']?.toString() ?? '';
        if (content.isNotEmpty) onResponse(content);
      }

      if (!isCancelled && onComplete != null) {
        onComplete!();
      } else if (isCancelled && onError != null) {
        onError!('Request cancelled');
      }
    } catch (e) {
      if (!isCancelled && onError != null) {
        onError!(AppFailure.from(e, code: 'provider_request_failed').code);
      }
    } finally {
      if (cancelController?.isClosed == false) cancelController?.close();
      cancelController = null;
      if (_skillToolClient == null) client.close();
    }
  }

  @override
  List<String> getSupportedImageSizes() {
    final model = bot.model.toLowerCase();
    if (model == 'dall-e-3') {
      return ['1024x1024', '1792x1024', '1024x1792'];
    }
    if (model == 'dall-e-2') {
      return ['256x256', '512x512', '1024x1024'];
    }
    if (_selectedModelSpec?.taskType == AiModelTaskType.imageGeneration) {
      return ['1024x1024', '1536x1024', '1024x1536', 'auto'];
    }
    return const [];
  }

  @override
  Future<List<String>> generateImage(
    String prompt,
    String size,
    String imageDirPath, {
    List<String> referenceImages = const [],
    String style = '',
  }) async {
    final spec = _selectedModelSpec;
    final isLegacyDallE = bot.model.toLowerCase().startsWith('dall-e-');
    if (spec?.taskType != AiModelTaskType.imageGeneration && !isLegacyDallE) {
      throw UnsupportedError(
        'Model ${bot.model} does not support the OpenAI Images API.',
      );
    }
    final client = _skillToolClient ?? http.Client();
    try {
      late http.Response response;
      if (referenceImages.isEmpty) {
        final requestBody = <String, Object?>{
          'model': bot.model,
          'prompt': prompt,
          'n': 1,
          if (size.isNotEmpty) 'size': size,
          if (isLegacyDallE) 'response_format': 'url',
          if (isLegacyDallE && style.isNotEmpty) 'style': style,
        };
        response = await sendProviderRequest(
          send:
              () => client.post(
                Uri.parse(_endpoint('images/generations', defaultApiImageUrl)),
                headers: _headers,
                body: jsonEncode(requestBody),
              ),
          endpointKind: ProviderEndpointKind.images,
          timeout: const Duration(seconds: 60),
        );
      } else {
        if (isLegacyDallE) {
          throw UnsupportedError(
            'Reference-image editing requires a GPT Image model.',
          );
        }
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(_endpoint('images/edits', defaultApiImageEditUrl)),
        )..headers.addAll(_authorizationHeaders);
        request.fields.addAll({
          'model': bot.model,
          'prompt': prompt,
          if (size.isNotEmpty) 'size': size,
        });
        for (final imagePath in referenceImages) {
          if (!File(imagePath).existsSync()) continue;
          request.files.add(
            await http.MultipartFile.fromPath('image[]', imagePath),
          );
        }
        if (request.files.isEmpty) {
          throw const FileSystemException('No readable reference images.');
        }
        response = await http.Response.fromStream(await client.send(request));
      }

      _ensureSuccess(response, ProviderEndpointKind.images);
      final data = decodeProviderResponse(utf8.decode(response.bodyBytes));
      return _persistImages(data, imageDirPath, client);
    } on ProviderFailure {
      rethrow;
    } catch (error) {
      throw AppFailure.from(error, code: 'generate_image_failed');
    } finally {
      if (_skillToolClient == null) client.close();
    }
  }

  @override
  List<String> getSupportVoicTypes() {
    if (_selectedModelSpec?.taskType != AiModelTaskType.speech) return const [];
    if (bot.model == 'tts-1' || bot.model == 'tts-1-hd') {
      return const [
        'alloy',
        'ash',
        'coral',
        'echo',
        'fable',
        'onyx',
        'nova',
        'sage',
        'shimmer',
      ];
    }
    return const [
      'alloy',
      'ash',
      'ballad',
      'coral',
      'echo',
      'fable',
      'nova',
      'onyx',
      'sage',
      'shimmer',
      'verse',
      'marin',
      'cedar',
    ];
  }

  @override
  Future<String> generateSpeech(
    String prompt,
    String voiceType,
    String outputDirPath,
  ) async {
    if (_selectedModelSpec?.taskType != AiModelTaskType.speech) {
      throw UnsupportedError(
        'Model ${bot.model} does not support the OpenAI Speech API.',
      );
    }
    final client = _skillToolClient ?? http.Client();
    try {
      final response = await sendProviderRequest(
        send:
            () => client.post(
              Uri.parse(_endpoint('audio/speech', defaultApiSpeechUrl)),
              headers: _headers,
              body: jsonEncode({
                'model': bot.model,
                'input': prompt,
                'voice': voiceType,
                'response_format': 'mp3',
              }),
            ),
        endpointKind: ProviderEndpointKind.speech,
        timeout: const Duration(seconds: 60),
      );
      await Directory(outputDirPath).create(recursive: true);
      final path =
          '$outputDirPath/openai_speech_${DateTime.now().millisecondsSinceEpoch}.mp3';
      await File(path).writeAsBytes(response.bodyBytes);
      return path;
    } finally {
      if (_skillToolClient == null) client.close();
    }
  }

  @override
  List<String> getSupportVideoResolutions() {
    if (_selectedModelSpec?.taskType != AiModelTaskType.videoGeneration) {
      return const [];
    }
    return bot.model.toLowerCase() == 'sora-2-pro'
        ? const ['1920x1080', '1080x1920']
        : const ['1280x720', '720x1280'];
  }

  @override
  List<String> getSupportVideoRatios() {
    if (_selectedModelSpec?.taskType != AiModelTaskType.videoGeneration) {
      return const [];
    }
    return const ['16:9', '9:16'];
  }

  @override
  Future<String> generateVideo(
    String prompt,
    String ratio,
    String outputDirPath,
    List<String> referImages,
  ) async {
    if (_selectedModelSpec?.taskType != AiModelTaskType.videoGeneration) {
      throw UnsupportedError(
        'Model ${bot.model} does not support the OpenAI Videos API.',
      );
    }
    final size = _videoSize(ratio);
    final client = _skillToolClient ?? http.Client();
    try {
      late http.Response createResponse;
      String? reference;
      for (final imagePath in referImages) {
        if (File(imagePath).existsSync()) {
          reference = imagePath;
          break;
        }
      }
      if (reference == null) {
        createResponse = await sendProviderRequest(
          send:
              () => client.post(
                Uri.parse(_endpoint('videos', defaultApiVideosUrl)),
                headers: _headers,
                body: jsonEncode({
                  'model': bot.model,
                  'prompt': prompt,
                  'size': size,
                }),
              ),
          endpointKind: ProviderEndpointKind.videos,
          timeout: const Duration(seconds: 60),
        );
      } else {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(_endpoint('videos', defaultApiVideosUrl)),
        )..headers.addAll(_authorizationHeaders);
        request.fields.addAll({
          'model': bot.model,
          'prompt': prompt,
          'size': size,
        });
        request.files.add(
          await http.MultipartFile.fromPath('input_reference', reference),
        );
        createResponse = await http.Response.fromStream(
          await client.send(request),
        );
      }
      _ensureSuccess(createResponse, ProviderEndpointKind.videos);
      var video = Map<String, dynamic>.from(
        decodeProviderResponse(utf8.decode(createResponse.bodyBytes)) as Map,
      );
      final videoId = video['id']?.toString() ?? '';
      if (videoId.isEmpty) {
        throw const FormatException('Video response is missing an id.');
      }

      for (var attempt = 0; attempt < 300; attempt++) {
        final status = video['status']?.toString();
        if (status == 'completed') break;
        if (status == 'failed' || status == 'expired') {
          throw ProviderFailure.invalidResponse(
            endpointKind: ProviderEndpointKind.videos,
            code: 'provider_video_failed',
          );
        }
        await Future<void>.delayed(const Duration(seconds: 2));
        final pollResponse = await sendProviderRequest(
          send:
              () => client.get(
                Uri.parse(
                  _endpoint('videos/$videoId', '$defaultApiVideosUrl/$videoId'),
                ),
                headers: _authorizationHeaders,
              ),
          endpointKind: ProviderEndpointKind.videos,
          timeout: const Duration(seconds: 60),
        );
        video = Map<String, dynamic>.from(
          decodeProviderResponse(utf8.decode(pollResponse.bodyBytes)) as Map,
        );
      }
      if (video['status'] != 'completed') {
        throw TimeoutException('Video generation timed out.');
      }

      final contentResponse = await sendProviderRequest(
        send:
            () => client.get(
              Uri.parse(
                _endpoint(
                  'videos/$videoId/content',
                  '$defaultApiVideosUrl/$videoId/content',
                ),
              ),
              headers: _authorizationHeaders,
            ),
        endpointKind: ProviderEndpointKind.videos,
        timeout: const Duration(seconds: 60),
      );
      await Directory(outputDirPath).create(recursive: true);
      final path = '$outputDirPath/openai_video_$videoId.mp4';
      await File(path).writeAsBytes(contentResponse.bodyBytes);
      return path;
    } finally {
      if (_skillToolClient == null) client.close();
    }
  }

  @override
  List<Map<String, dynamic>> processMessagesWithImages(
    List<ChatMessage> messages,
  ) {
    return messages
        .map((message) {
          final role = _normalizedMessageRole(message.role);
          if (message.images.isEmpty) {
            return {'role': role, 'content': message.content};
          }
          final content = <Map<String, dynamic>>[];
          if (message.content.isNotEmpty) {
            content.add({'type': 'text', 'text': message.content});
          }

          for (final imagePath in message.images) {
            try {
              final file = File(imagePath);
              if (file.existsSync()) {
                final bytes = file.readAsBytesSync();
                content.add({
                  'type': 'image_url',
                  'image_url': {
                    'url':
                        'data:${getImageMediaType(bytes)};base64,${base64Encode(bytes)}',
                  },
                });
              }
            } catch (_) {
              // Skip an unreadable optional image and continue the request.
            }
          }
          return {'role': role, 'content': content};
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _processMessagesForResponses(
    List<ChatMessage> messages,
  ) {
    return messages
        .map((message) {
          final content = <Map<String, dynamic>>[];
          if (message.content.isNotEmpty) {
            content.add({'type': 'input_text', 'text': message.content});
          }
          for (final imagePath in message.images) {
            try {
              final bytes = File(imagePath).readAsBytesSync();
              content.add({
                'type': 'input_image',
                'image_url':
                    'data:${getImageMediaType(bytes)};base64,${base64Encode(bytes)}',
              });
            } on FileSystemException {
              // Ignore an optional image that was removed before sending.
            }
          }
          return {
            'role': _normalizedMessageRole(message.role),
            'content': content,
          };
        })
        .toList(growable: false);
  }

  Future<List<String>> _persistImages(
    Object? decoded,
    String imageDirPath,
    http.Client client,
  ) async {
    if (decoded is! Map || decoded['data'] is! List) {
      throw const FormatException('Image response has no data array.');
    }
    await Directory(imageDirPath).create(recursive: true);
    final paths = <String>[];
    var index = 0;
    for (final rawImage in decoded['data'] as List) {
      if (rawImage is! Map) continue;
      final image = Map<String, dynamic>.from(rawImage);
      List<int>? bytes;
      final encoded = image['b64_json']?.toString();
      if (encoded != null && encoded.isNotEmpty) {
        bytes = base64Decode(encoded);
      } else {
        final url = image['url']?.toString();
        if (url != null && url.isNotEmpty) {
          final response = await client.get(Uri.parse(url));
          _ensureSuccess(response, ProviderEndpointKind.images);
          bytes = response.bodyBytes;
        }
      }
      if (bytes == null) continue;
      final path =
          '$imageDirPath/openai_image_${DateTime.now().microsecondsSinceEpoch}_$index.png';
      await File(path).writeAsBytes(bytes);
      paths.add(path);
      index += 1;
    }
    if (paths.isEmpty) {
      throw const FormatException('Image response contained no image output.');
    }
    return paths;
  }

  void _ensureSuccess(
    http.Response response,
    ProviderEndpointKind endpointKind,
  ) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderFailure.fromHttp(
        statusCode: response.statusCode,
        endpointKind: endpointKind,
        headers: response.headers,
        responseBody: response.body,
      );
    }
  }

  String _videoSize(String ratio) {
    final resolutions = getSupportVideoResolutions();
    if (resolutions.isEmpty) return '';
    return ratio == '9:16' ? resolutions.last : resolutions.first;
  }

  String _normalizedMessageRole(String role) {
    if (role == 'system' && supportDeepThinking()) return 'developer';
    return role;
  }

  String _endpoint(String path, String defaultUrl) {
    if (bot.baseURL.isEmpty) return defaultUrl;
    final configured = Uri.tryParse(bot.baseURL.trim());
    final endpointKind = _endpointKind(path);
    final host = configured?.host.toLowerCase() ?? '';
    final configuredPath = configured?.path.toLowerCase() ?? '';
    final isChatGptHost =
        host == 'chatgpt.com' || host.endsWith('.chatgpt.com');
    final isInternalCodexPath = configuredPath.contains('/backend-api/codex');
    if (configured == null ||
        !configured.hasScheme ||
        (configured.scheme != 'https' && configured.scheme != 'http') ||
        host.isEmpty ||
        configured.userInfo.isNotEmpty ||
        configured.hasQuery ||
        configured.hasFragment ||
        isChatGptHost ||
        isInternalCodexPath) {
      throw ProviderFailure.configuration(
        endpointKind: endpointKind,
        code: 'openai_invalid_base_url',
      );
    }
    final source = configured.toString();
    final base = source.endsWith('/') ? source : '$source/';
    final relative = path.startsWith('/') ? path.substring(1) : path;
    return '$base$relative';
  }

  ProviderEndpointKind _endpointKind(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    if (normalized == 'models') return ProviderEndpointKind.models;
    if (normalized.startsWith('chat/completions')) {
      return ProviderEndpointKind.chatCompletions;
    }
    if (normalized.startsWith('responses')) {
      return ProviderEndpointKind.responses;
    }
    if (normalized.startsWith('images/')) return ProviderEndpointKind.images;
    if (normalized.startsWith('audio/speech')) {
      return ProviderEndpointKind.speech;
    }
    if (normalized.startsWith('videos')) return ProviderEndpointKind.videos;
    return ProviderEndpointKind.unknown;
  }

  Map<String, String> get _authorizationHeaders => {
    'Authorization': 'Bearer ${bot.apiKey}',
  };

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    ..._authorizationHeaders,
  };

  bool get _isFirstPartyOpenAi =>
      bot.apiType == Bot.apiTypeOpenAI &&
      bot.provider.toLowerCase() == Bot.apiTypeOpenAI;

  _OpenAiModelSpec? get _selectedModelSpec =>
      _isFirstPartyOpenAi ? _findOpenAiModelSpec(bot.model) : null;

  bool get _usesResponsesApi =>
      _isFirstPartyOpenAi &&
      _selectedModelSpec?.preferredEndpoint == AiModelEndpoint.responses;

  bool get _isSearchPreviewModel =>
      _selectedModelSpec?.supportedFeatures.contains('built_in_web_search') ==
      true;

  String? get _selectedReasoningEffort {
    final spec = _selectedModelSpec;
    if (spec == null) return 'high';
    if (!spec.supportsDeepThinking) return null;
    for (final effort in const ['high', 'medium', 'low', 'xhigh', 'none']) {
      if (spec.reasoningEfforts.contains(effort)) return effort;
    }
    return null;
  }
}
