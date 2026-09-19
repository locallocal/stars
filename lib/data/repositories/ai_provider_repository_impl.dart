import 'dart:async';
import 'dart:isolate';
import 'package:stars/data/services/ai/provider_log_sink.dart';
import 'package:stars/data/services/ai/provider_service.dart' show Provider;
import 'package:stars/data/services/ai/ai_hub_mix.dart';
import 'package:stars/data/services/ai/ai_mass.dart';
import 'package:stars/data/services/ai/alibaba_cloud.dart';
import 'package:stars/data/services/ai/anthropic.dart';
import 'package:stars/data/services/ai/bai_chuan.dart';
import 'package:stars/data/services/ai/baidu.dart';
import 'package:stars/data/services/ai/cerebras.dart';
import 'package:stars/data/services/ai/cohere.dart';
import 'package:stars/data/services/ai/deep_infra.dart';
import 'package:stars/data/services/ai/deepseek.dart';
import 'package:stars/data/services/ai/fireworks.dart';
import 'package:stars/data/services/ai/flux.dart';
import 'package:stars/data/services/ai/gemini.dart';
import 'package:stars/data/services/ai/grok.dart';
import 'package:stars/data/services/ai/hugging_face.dart';
import 'package:stars/data/services/ai/infini_gence.dart';
import 'package:stars/data/services/ai/intern_lm.dart';
import 'package:stars/data/services/ai/jina.dart';
import 'package:stars/data/services/ai/kluster.dart';
import 'package:stars/data/services/ai/lambda.dart';
import 'package:stars/data/services/ai/mini_max.dart';
import 'package:stars/data/services/ai/mistral.dart';
import 'package:stars/data/services/ai/model_scope.dart';
import 'package:stars/data/services/ai/monica.dart';
import 'package:stars/data/services/ai/moonshot.dart';
import 'package:stars/data/services/ai/nebius.dart';
import 'package:stars/data/services/ai/novita.dart';
import 'package:stars/data/services/ai/ollama.dart';
import 'package:stars/data/services/ai/open_router.dart';
import 'package:stars/data/services/ai/openai.dart';
import 'package:stars/data/services/ai/perplexity.dart';
import 'package:stars/data/services/ai/ppio.dart';
import 'package:stars/data/services/ai/samba_nova.dart';
import 'package:stars/data/services/ai/search1_api.dart';
import 'package:stars/data/services/ai/sense_nova.dart';
import 'package:stars/data/services/ai/spark.dart';
import 'package:stars/data/services/ai/stability.dart';
import 'package:stars/data/services/ai/step_fun.dart';
import 'package:stars/data/services/ai/tencent.dart';
import 'package:stars/data/services/ai/together_ai.dart';
import 'package:stars/data/services/ai/volcano_engine.dart';
import 'package:stars/data/services/ai/xing_he.dart';
import 'package:stars/data/services/ai/zero_one_ai.dart';
import 'package:stars/data/services/ai/zhipu.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';

typedef AiMediaProviderFactory = AiProvider Function(Bot bot);

class AiProviderRepositoryImpl
    implements
        CancelableMediaRepository,
        ConversationScopedAiProviderRepository {
  const AiProviderRepositoryImpl({
    this.logSink,
    this.conversationLogSink,
    this.mediaTimeout = const Duration(minutes: 2),
    AiMediaProviderFactory? mediaProviderFactory,
  }) : _mediaProviderFactory = mediaProviderFactory;

  static final Map<String, _ActiveMediaRequest> _activeMediaRequests = {};

  final ProviderLogSink? logSink;
  final ProviderLogSink Function(String chatId)? conversationLogSink;
  final Duration mediaTimeout;
  final AiMediaProviderFactory? _mediaProviderFactory;

  @override
  AiProviderRepository forConversation(String chatId) =>
      AiProviderRepositoryImpl(
        mediaTimeout: mediaTimeout,
        mediaProviderFactory: _mediaProviderFactory,
        logSink: conversationLogSink?.call(chatId),
        conversationLogSink: conversationLogSink,
      );

  @override
  AiProvider create(Bot bot) {
    final Provider provider = switch (bot.apiType) {
      Bot.apiTypeOpenAI => OpenAI(bot),
      Bot.apiTypeOllama => Ollama(bot),
      Bot.apiTypeDeepseek => Deepseek(bot),
      Bot.apiTypeGemini => Gemini(bot),
      Bot.apiTypeGrok => Grok(bot),
      Bot.apiTypeHuggingface => HuggingFace(bot),
      Bot.apiTypeAnthropic => Anthropic(bot),
      Bot.apiTypeVolcanoEngine => VolcanoEngine(bot),
      Bot.apiTypeTencent => Tencent(bot),
      Bot.apiTypeOpenRouter => OpenRouter(bot),
      Bot.apiTypeBaidu => Baidu(bot),
      Bot.apiTypeXingHe => Xinghe(bot),
      Bot.apiTypeZhipu => Zhipu(bot),
      Bot.apiTypeZeroOneAI => ZeroOneAI(bot),
      Bot.apiTypeInfiniGence => InfiniAI(bot),
      Bot.apiTypePPIO => PPIO(bot),
      Bot.apiTypeStepFun => StepFun(bot),
      Bot.apiTypeBaiChuan => BaiChuan(bot),
      Bot.apiTypeSpark => Spark(bot),
      Bot.apiTypeSenseNova => SenseNova(bot),
      Bot.apiTypeMistral => Mistral(bot),
      Bot.apiTypeStability => Stability(bot),
      Bot.apiTypeFireworks => Fireworks(bot),
      Bot.apiTypeFlux => Flux(bot),
      Bot.apiTypeKluster => Kluster(bot),
      Bot.apiTypeInternLM => InternLM(bot),
      Bot.apiTypeJina => Jina(bot),
      Bot.apiTypeLambda => Lambda(bot),
      Bot.apiTypeAiHubMix => AiHubMix(bot),
      Bot.apiTypeAiMass => AiMass(bot),
      Bot.apiTypeDeepInfra => DeepInfra(bot),
      Bot.apiTypeCerebras => Cerebras(bot),
      Bot.apiTypeCohere => Cohere(bot),
      Bot.apiTypeMiniMax => MiniMax(bot),
      Bot.apiTypeModelScope => ModelScope(bot),
      Bot.apiTypeMonica => Monica(bot),
      Bot.apiTypeNebius => Nebius(bot),
      Bot.apiTypeNovita => Novita(bot),
      Bot.apiTypeSearch1Api => Search1Api(bot),
      Bot.apiTypeSambaNova => SambaNova(bot),
      Bot.apiTypePerplexity => Perplexity(bot),
      Bot.apiTypeTogetherAI => TogetherAI(bot),
      Bot.apiTypeAlibabaCloud => AlibabaCloud(bot),
      Bot.apiTypeMoonshot => Moonshot(bot),
      _ => throw UnsupportedError('Unsupported API type: ${bot.apiType}'),
    };
    provider.logSink = logSink;
    return provider;
  }

  @override
  Future<AiModelInfo?> getModelInfo(Bot bot) async {
    final models = await listModels(bot);
    for (final model in models) {
      if (model.modelId == bot.model) return model;
    }
    return null;
  }

  @override
  Future<List<AiModelInfo>> listModels(Bot bot) => create(bot).fetchModels();

  @override
  Future<List<String>> generateImage({
    required Bot bot,
    required String prompt,
    required String size,
    required String outputDirectory,
    required List<String> referenceImages,
    required String style,
  }) => _runMedia(
    bot,
    (provider) => provider.generateImage(
      prompt,
      size,
      outputDirectory,
      referenceImages: referenceImages,
      style: style,
    ),
    _ImageMediaRequest(
      bot: bot,
      prompt: prompt,
      size: size,
      outputDirectory: outputDirectory,
      referenceImages: referenceImages,
      style: style,
    ),
  );

  @override
  Future<String> generateSpeech({
    required Bot bot,
    required String prompt,
    required String voiceType,
    required String outputDirectory,
  }) => _runMedia(
    bot,
    (provider) => provider.generateSpeech(prompt, voiceType, outputDirectory),
    _SpeechMediaRequest(
      bot: bot,
      prompt: prompt,
      voiceType: voiceType,
      outputDirectory: outputDirectory,
    ),
  );

  @override
  Future<String> generateMusic({
    required Bot bot,
    required String prompt,
    required String outputDirectory,
    required String referenceMusic,
  }) => _runMedia(
    bot,
    (provider) =>
        provider.generateMusic(prompt, outputDirectory, referenceMusic),
    _MusicMediaRequest(
      bot: bot,
      prompt: prompt,
      outputDirectory: outputDirectory,
      referenceMusic: referenceMusic,
    ),
  );

  @override
  Future<String> generateVideo({
    required Bot bot,
    required String prompt,
    required String ratio,
    required String outputDirectory,
    required List<String> referenceImages,
  }) => _runMedia(
    bot,
    (provider) =>
        provider.generateVideo(prompt, ratio, outputDirectory, referenceImages),
    _VideoMediaRequest(
      bot: bot,
      prompt: prompt,
      ratio: ratio,
      outputDirectory: outputDirectory,
      referenceImages: referenceImages,
    ),
  );

  Future<T> _runMedia<T>(
    Bot bot,
    Future<T> Function(AiProvider provider) operation,
    _MediaRequest isolatedRequest,
  ) async {
    if (_activeMediaRequests.containsKey(bot.id)) {
      throw const AppFailure.validation('media_request_already_active');
    }
    if (_mediaProviderFactory == null) {
      return _runMediaIsolate<T>(bot, isolatedRequest);
    }
    final provider = _mediaProviderFactory(bot);
    provider.resetCancelState();
    final cancellation = Completer<void>();
    final active = _ActiveMediaRequest(
      cancellation: cancellation,
      cancelUnderlying: provider.cancelRequest,
    );
    _activeMediaRequests[bot.id] = active;
    try {
      return await Future.any<T>([
        operation(provider),
        cancellation.future.then<T>((_) => throw const AppFailure.cancelled()),
      ]).timeout(mediaTimeout);
    } on TimeoutException catch (error) {
      await provider.cancelRequest();
      throw AppFailure(
        kind: AppFailureKind.networkTimeout,
        code: 'media_request_timeout',
        retryable: true,
        debugCause: error,
      );
    } on AppFailure {
      rethrow;
    } on Object catch (error) {
      throw AppFailure.from(error, code: 'media_provider_failed');
    } finally {
      if (identical(_activeMediaRequests[bot.id], active)) {
        _activeMediaRequests.remove(bot.id);
      }
    }
  }

  Future<T> _runMediaIsolate<T>(Bot bot, _MediaRequest request) async {
    final responsePort = ReceivePort();
    final cancellation = Completer<void>();
    final pendingLogs = <String, Map<String, Object?>>{};
    var interruption = 'worker_terminated';
    Isolate? isolate;
    final active = _ActiveMediaRequest(
      cancellation: cancellation,
      cancelUnderlying: () async {
        isolate?.kill(priority: Isolate.immediate);
        return const ProviderCancellationResult(
          ProviderCancellationStatus.requested,
        );
      },
    );
    _activeMediaRequests[bot.id] = active;
    try {
      var loggingEnabled = false;
      try {
        loggingEnabled = await logSink?.enabled ?? false;
      } on Object {
        /* Optional diagnostics must not prevent media requests. */
      }
      isolate = await Isolate.spawn<(SendPort, _MediaRequest, bool)>(
        _runMediaWorker,
        (responsePort.sendPort, request, loggingEnabled),
        debugName: 'stars-media-${bot.id}',
      );
      if (cancellation.isCompleted) {
        isolate.kill(priority: Isolate.immediate);
        throw const AppFailure.cancelled();
      }
      final raw = await Future.any<Object?>([
        responsePort.firstWhere((event) {
          if (event is Map<String, Object?>) {
            try {
              final id = event['request_id'];
              if (id is String) {
                if (event['event'] == 'request') {
                  pendingLogs[id] = {
                    for (final key in [
                      'request_id',
                      'bot_id',
                      'provider',
                      'model',
                      'operation',
                    ])
                      key: event[key],
                  };
                } else if (event['event'] == 'response' ||
                    event['event'] == 'transport_error') {
                  pendingLogs.remove(id);
                }
              }
              logSink?.add(event);
            } on Object {
              /* Optional diagnostics. */
            }
            return false;
          }
          return true;
        }),
        cancellation.future.then<Object?>(
          (_) => throw const AppFailure.cancelled(),
        ),
      ]).timeout(mediaTimeout);
      if (raw is! List<Object?> || raw.length != 3) {
        throw const AppFailure.providerRejected('invalid_media_worker_result');
      }
      if (raw[0] == true) return raw[1] as T;
      throw AppFailure(
        kind: AppFailureKind.providerRejected,
        code: raw[1]?.toString() ?? 'media_provider_failed',
        retryable: raw[2] == true,
      );
    } on TimeoutException catch (error) {
      interruption = 'timeout';
      isolate?.kill(priority: Isolate.immediate);
      throw AppFailure(
        kind: AppFailureKind.networkTimeout,
        code: 'media_request_timeout',
        retryable: true,
        debugCause: error,
      );
    } on AppFailure {
      rethrow;
    } on Object catch (error) {
      throw AppFailure.from(error, code: 'media_provider_failed');
    } finally {
      isolate?.kill(priority: Isolate.immediate);
      responsePort.close();
      for (final metadata in pendingLogs.values) {
        try {
          logSink?.add({
            ...metadata,
            'event': 'request_interrupted',
            'timestamp': DateTime.now().toUtc().toIso8601String(),
            'outcome': cancellation.isCompleted ? 'cancelled' : interruption,
          });
        } on Object {
          /* Optional diagnostics. */
        }
      }
      if (identical(_activeMediaRequests[bot.id], active)) {
        _activeMediaRequests.remove(bot.id);
      }
    }
  }

  @override
  Future<bool> cancelMedia(String botId) async {
    final active = _activeMediaRequests[botId];
    if (active == null) return false;
    if (!active.cancellation.isCompleted) active.cancellation.complete();
    await active.cancelUnderlying();
    return true;
  }
}

final class _ActiveMediaRequest {
  const _ActiveMediaRequest({
    required this.cancellation,
    required this.cancelUnderlying,
  });

  final Completer<void> cancellation;
  final Future<ProviderCancellationResult> Function() cancelUnderlying;
}

sealed class _MediaRequest {
  const _MediaRequest({required this.bot});

  final Bot bot;
}

final class _ImageMediaRequest extends _MediaRequest {
  const _ImageMediaRequest({
    required super.bot,
    required this.prompt,
    required this.size,
    required this.outputDirectory,
    required this.referenceImages,
    required this.style,
  });

  final String prompt;
  final String size;
  final String outputDirectory;
  final List<String> referenceImages;
  final String style;
}

final class _SpeechMediaRequest extends _MediaRequest {
  const _SpeechMediaRequest({
    required super.bot,
    required this.prompt,
    required this.voiceType,
    required this.outputDirectory,
  });

  final String prompt;
  final String voiceType;
  final String outputDirectory;
}

final class _MusicMediaRequest extends _MediaRequest {
  const _MusicMediaRequest({
    required super.bot,
    required this.prompt,
    required this.outputDirectory,
    required this.referenceMusic,
  });

  final String prompt;
  final String outputDirectory;
  final String referenceMusic;
}

final class _VideoMediaRequest extends _MediaRequest {
  const _VideoMediaRequest({
    required super.bot,
    required this.prompt,
    required this.ratio,
    required this.outputDirectory,
    required this.referenceImages,
  });

  final String prompt;
  final String ratio;
  final String outputDirectory;
  final List<String> referenceImages;
}

Future<void> _runMediaWorker((SendPort, _MediaRequest, bool) message) async {
  final (sendPort, request, loggingEnabled) = message;
  try {
    final provider = AiProviderRepositoryImpl(
      logSink: loggingEnabled ? _MediaLogSink(sendPort) : null,
    ).create(request.bot);
    final Object result = switch (request) {
      _ImageMediaRequest() => await provider.generateImage(
        request.prompt,
        request.size,
        request.outputDirectory,
        referenceImages: request.referenceImages,
        style: request.style,
      ),
      _SpeechMediaRequest() => await provider.generateSpeech(
        request.prompt,
        request.voiceType,
        request.outputDirectory,
      ),
      _MusicMediaRequest() => await provider.generateMusic(
        request.prompt,
        request.outputDirectory,
        request.referenceMusic,
      ),
      _VideoMediaRequest() => await provider.generateVideo(
        request.prompt,
        request.ratio,
        request.outputDirectory,
        request.referenceImages,
      ),
    };
    sendPort.send(<Object?>[true, result, false]);
  } on Object catch (error) {
    final failure = AppFailure.from(error, code: 'media_provider_failed');
    sendPort.send(<Object?>[false, failure.code, failure.retryable]);
  }
}

/// Sends sanitized events to the owner isolate; only that isolate writes files.
final class _MediaLogSink implements ProviderLogSink {
  const _MediaLogSink(this.port);
  final SendPort port;
  @override
  Future<bool> get enabled async => true;
  @override
  void add(Map<String, Object?> event) => port.send(event);
}
