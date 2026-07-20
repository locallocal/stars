import 'package:flutter/foundation.dart';
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
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';

class AiProviderRepositoryImpl implements AiProviderRepository {
  const AiProviderRepositoryImpl();

  @override
  AiProvider create(Bot bot) {
    return switch (bot.apiType) {
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
  }

  @override
  Future<List<String>> listModels(Bot bot) => create(bot).listModels();

  @override
  Future<List<String>> generateImage({
    required Bot bot,
    required String prompt,
    required String size,
    required String outputDirectory,
    required List<String> referenceImages,
    required String style,
  }) => compute(
    _generateImage,
    _ImageGenerationRequest(
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
  }) => compute(
    _generateSpeech,
    _SpeechGenerationRequest(
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
  }) => compute(
    _generateMusic,
    _MusicGenerationRequest(
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
  }) => compute(
    _generateVideo,
    _VideoGenerationRequest(
      bot: bot,
      prompt: prompt,
      ratio: ratio,
      outputDirectory: outputDirectory,
      referenceImages: referenceImages,
    ),
  );
}

Future<List<String>> _generateImage(_ImageGenerationRequest request) =>
    const AiProviderRepositoryImpl()
        .create(request.bot)
        .generateImage(
          request.prompt,
          request.size,
          request.outputDirectory,
          referenceImages: request.referenceImages,
          style: request.style,
        );

Future<String> _generateSpeech(_SpeechGenerationRequest request) =>
    const AiProviderRepositoryImpl()
        .create(request.bot)
        .generateSpeech(
          request.prompt,
          request.voiceType,
          request.outputDirectory,
        );

Future<String> _generateMusic(_MusicGenerationRequest request) =>
    const AiProviderRepositoryImpl()
        .create(request.bot)
        .generateMusic(
          request.prompt,
          request.outputDirectory,
          request.referenceMusic,
        );

Future<String> _generateVideo(_VideoGenerationRequest request) =>
    const AiProviderRepositoryImpl()
        .create(request.bot)
        .generateVideo(
          request.prompt,
          request.ratio,
          request.outputDirectory,
          request.referenceImages,
        );

class _ImageGenerationRequest {
  const _ImageGenerationRequest({
    required this.bot,
    required this.prompt,
    required this.size,
    required this.outputDirectory,
    required this.referenceImages,
    required this.style,
  });

  final Bot bot;
  final String prompt;
  final String size;
  final String outputDirectory;
  final List<String> referenceImages;
  final String style;
}

class _SpeechGenerationRequest {
  const _SpeechGenerationRequest({
    required this.bot,
    required this.prompt,
    required this.voiceType,
    required this.outputDirectory,
  });

  final Bot bot;
  final String prompt;
  final String voiceType;
  final String outputDirectory;
}

class _MusicGenerationRequest {
  const _MusicGenerationRequest({
    required this.bot,
    required this.prompt,
    required this.outputDirectory,
    required this.referenceMusic,
  });

  final Bot bot;
  final String prompt;
  final String outputDirectory;
  final String referenceMusic;
}

class _VideoGenerationRequest {
  const _VideoGenerationRequest({
    required this.bot,
    required this.prompt,
    required this.ratio,
    required this.outputDirectory,
    required this.referenceImages,
  });

  final Bot bot;
  final String prompt;
  final String ratio;
  final String outputDirectory;
  final List<String> referenceImages;
}
