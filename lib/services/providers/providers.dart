import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/providers/openai.dart';
import 'package:bubble/services/providers/ollama.dart';
import 'package:bubble/services/providers/deepseek.dart';
import 'package:bubble/services/providers/gemini.dart';
import 'package:bubble/services/providers/grok.dart';
import 'package:bubble/services/providers/hugging_face.dart';
import 'package:bubble/services/providers/anthropic.dart';
import 'package:bubble/services/providers/open_router.dart';
import 'package:bubble/services/providers/spark.dart';
import 'package:bubble/services/providers/tencent.dart';
import 'package:bubble/services/providers/volcano_engine.dart';
import 'package:bubble/services/providers/baidu.dart';
import 'package:bubble/services/providers/xing_he.dart';
import 'package:bubble/services/providers/zhipu.dart';
import 'package:bubble/services/providers/zero_one_ai.dart';
import 'package:bubble/services/providers/infini_gence.dart';
import 'package:bubble/services/providers/ppio.dart';
import 'package:bubble/services/providers/step_fun.dart';
import 'package:bubble/services/providers/bai_chuan.dart';
import 'package:bubble/services/providers/sense_nova.dart';
import 'package:bubble/services/providers/mistral.dart';
import 'package:bubble/services/providers/stability.dart';
import 'package:bubble/services/providers/fireworks.dart';
import 'package:bubble/services/providers/flux.dart';
import 'package:bubble/services/providers/kluster.dart';
import 'package:bubble/services/providers/intern_lm.dart';
import 'package:bubble/services/providers/jina.dart';
import 'package:bubble/services/providers/lambda.dart';
import 'package:bubble/services/providers/ai_hub_mix.dart';
import 'package:bubble/services/providers/ai_mass.dart';
import 'package:bubble/services/providers/deep_infra.dart';
import 'package:bubble/services/providers/cerebras.dart';
import 'package:bubble/services/providers/cohere.dart';
import 'package:bubble/services/providers/mini_max.dart';
import 'package:bubble/services/providers/model_scope.dart';
import 'package:bubble/services/providers/monica.dart';
import 'package:bubble/services/providers/nebius.dart';
import 'package:bubble/services/providers/novita.dart';
import 'package:bubble/services/providers/search1_api.dart';
import 'package:bubble/services/providers/samba_nova.dart';
import 'package:bubble/services/providers/perplexity.dart';
import 'package:bubble/services/providers/together_ai.dart';
import 'package:bubble/services/providers/alibaba_cloud.dart';
import 'package:bubble/services/providers/moonshot.dart';

void _defaultOnResponse(String text) {
  print(text);
}

// 定义消息类型
class ChatMessage {
  final String role;
  final String content;
  List<String> images;
  List<String> files;

  ChatMessage({
    required this.role,
    required this.content,
    this.images = const [],
    this.files = const [],
  });

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

// 定义流式响应回调
typedef StreamResponseCallback = void Function(String text);

// 聊天模型抽象类
abstract class Provider {
  final Bot bot;
  // 用于取消请求的控制器
  StreamController<bool>? cancelController;
  bool isCancelled = false;
  bool webSearch = false;
  bool deepThinking = false;
  // 回调函数
  StreamResponseCallback onResponse = _defaultOnResponse;
  StreamResponseCallback? onReasoningResponse;
  Function? onComplete;
  Function(String)? onError;

  Provider(this.bot);

  bool supportStreamResponse() {
    return true;
  }

  bool supportWebSearch() {
    return false;
  }

  bool supportDeepThinking() {
    return false;
  }

  bool supportDeepResearch() {
    return false;
  }

  void setWebSearch(bool enabled) {
    webSearch = enabled;
  }

  void setDeepThinking(bool enabled) {
    deepThinking = enabled;
  }

  bool getDeepThinking() {
    return deepThinking;
  }

  void setCallbacks({
    required StreamResponseCallback onResponse,
    StreamResponseCallback? onReasoningResponse,
    Function? onComplete,
    Function(String)? onError,
  }) {
    this.onResponse = onResponse;
    this.onReasoningResponse = onReasoningResponse;
    this.onComplete = onComplete;
    this.onError = onError;
  }

  List<InputModality> getInputModalites() {
    return [InputModality.text];
  }

  List<OutputModality> getOutputModalites() {
    return [OutputModality.text];
  }

  // 获取模型列表
  Future<List<String>> listModels() async {
    // 默认实现返回空列表，子类可以覆盖此方法
    return [];
  }

  // 发送消息并获取流式响应
  Future<void> generateText(List<ChatMessage> messages);

  List<String> getSupportImageStyles() {
    return [];
  }

  List<String> getSupportedImageSizes() {
    return [];
  }

  Future<List<String>> generateImage(
    String prompt,
    String size,
    String imageDirPath, {
    List<String> referenceImages = const [],
    String style = '',
  }) async {
    // 默认实现抛出异常，子类可以覆盖此方法
    throw UnsupportedError('${bot.apiType} Not support generate image');
  }

  List<String> getSupportVoicTypes() {
    return [];
  }

  Future<String> generateSpeech(
    String prompt,
    String voiceType,
    String outputDirPath,
  ) async {
    // 默认实现抛出异常，子类可以覆盖此方法
    throw UnsupportedError('${bot.apiType} Not support generate speech');
  }

  Future<String> generateMusic(
    String lyrics,
    String outputDirPath,
    String referMusic,
  ) async {
    // 默认实现抛出异常，子类可以覆盖此方法
    throw UnsupportedError('${bot.apiType} Not support generate music');
  }

  List<String> getSupportVideoResolutions() {
    return [];
  }

  List<String> getSupportVideoRatios() {
    return [];
  }

  Future<String> generateVideo(
    String prompt,
    String ratio,
    String outputDirPath,
    List<String> referImages,
  ) {
    // 默认实现抛出异常，子类可以覆盖此方法
    throw UnsupportedError('${bot.apiType} Not support generate video');
  }

  // 取消当前请求
  void cancelRequest() {
    isCancelled = true;
    cancelController?.add(true);
  }

  // 重置取消状态
  void resetCancelState() {
    isCancelled = false;
    cancelController = StreamController<bool>();
  }

  static Provider create(Bot bot) {
    switch (bot.apiType) {
      case Bot.apiTypeOpenAI:
        return OpenAI(bot);
      case Bot.apiTypeOllama:
        return Ollama(bot);
      case Bot.apiTypeDeepseek:
        return Deepseek(bot);
      case Bot.apiTypeGemini:
        return Gemini(bot);
      case Bot.apiTypeGrok:
        return Grok(bot);
      case Bot.apiTypeHuggingface:
        return HuggingFace(bot);
      case Bot.apiTypeAnthropic:
        return Anthropic(bot);
      case Bot.apiTypeVolcanoEngine:
        return VolcanoEngine(bot);
      case Bot.apiTypeTencent:
        return Tencent(bot);
      case Bot.apiTypeOpenRouter:
        return OpenRouter(bot);
      case Bot.apiTypeBaidu:
        return Baidu(bot);
      case Bot.apiTypeXingHe:
        return Xinghe(bot);
      case Bot.apiTypeZhipu:
        return Zhipu(bot);
      case Bot.apiTypeZeroOneAI:
        return ZeroOneAI(bot);
      case Bot.apiTypeInfiniGence:
        return InfiniAI(bot);
      case Bot.apiTypePPIO:
        return PPIO(bot);
      case Bot.apiTypeStepFun:
        return StepFun(bot);
      case Bot.apiTypeBaiChuan:
        return BaiChuan(bot);
      case Bot.apiTypeSpark:
        return Spark(bot);
      case Bot.apiTypeSenseNova:
        return SenseNova(bot);
      case Bot.apiTypeMistral:
        return Mistral(bot);
      case Bot.apiTypeStability:
        return Stability(bot);
      case Bot.apiTypeFireworks:
        return Fireworks(bot);
      case Bot.apiTypeFlux:
        return Flux(bot);
      case Bot.apiTypeKluster:
        return Kluster(bot);
      case Bot.apiTypeInternLM:
        return InternLM(bot);
      case Bot.apiTypeJina:
        return Jina(bot);
      case Bot.apiTypeLambda:
        return Lambda(bot);
      case Bot.apiTypeAiHubMix:
        return AiHubMix(bot);
      case Bot.apiTypeAiMass:
        return AiMass(bot);
      case Bot.apiTypeDeepInfra:
        return DeepInfra(bot);
      case Bot.apiTypeCerebras:
        return Cerebras(bot);
      case Bot.apiTypeCohere:
        return Cohere(bot);
      case Bot.apiTypeMiniMax:
        return MiniMax(bot);
      case Bot.apiTypeModelScope:
        return ModelScope(bot);
      case Bot.apiTypeMonica:
        return Monica(bot);
      case Bot.apiTypeNebius:
        return Nebius(bot);
      case Bot.apiTypeNovita:
        return Novita(bot);
      case Bot.apiTypeSearch1Api:
        return Search1Api(bot);
      case Bot.apiTypeSambaNova:
        return SambaNova(bot);
      case Bot.apiTypePerplexity:
        return Perplexity(bot);
      case Bot.apiTypeTogetherAI:
        return TogetherAI(bot);
      case Bot.apiTypeAlibabaCloud:
        return AlibabaCloud(bot);
      case Bot.apiTypeMoonshot:
        return Moonshot(bot);
      default:
        throw UnsupportedError('Not support api type: ${bot.apiType}');
    }
  }

  // 处理带有图片的消息
  List<Map<String, dynamic>> processMessagesWithImages(
    List<ChatMessage> messages,
  ) {
    return messages.map((message) {
      // 如果消息没有图片，直接返回原始消息
      if (message.images.isEmpty) {
        return message.toJson();
      }
      // 处理带有图片的消息
      final List<Map<String, dynamic>> content = [];
      // 添加文本内容（如果有）
      if (message.content.isNotEmpty) {
        content.add({'type': 'text', 'text': message.content});
      }

      // 添加图片内容
      for (final imagePath in message.images) {
        try {
          final file = File(imagePath);
          if (file.existsSync()) {
            final bytes = file.readAsBytesSync();
            final base64Image = base64Encode(bytes);

            content.add({
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
            });
          }
        } catch (e) {
          throw Exception('Process image $imagePath failed: $e');
        }
      }
      return {'role': message.role, 'content': content};
    }).toList();
  }

  String getImageMediaType(List<int> bytes) {
    if (bytes.length >= 3) {
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      } else if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'image/png';
      } else if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'image/gif';
      } else if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
        return 'image/bmp';
      } else if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46) {
        return 'image/webp';
      }
    }
    return 'application/octet-stream'; // 默认类型
  }

  // 将像素尺寸转换为比例字符串
  String transformRatio(int width, int height) {
    // 计算最大公约数
    int gcd = _calculateGCD(width, height);

    // 使用最大公约数简化比例
    int ratioWidth = width ~/ gcd;
    int ratioHeight = height ~/ gcd;

    // 返回标准比例格式
    return '$ratioWidth:$ratioHeight';
  }

  // 计算最大公约数的辅助函数
  int _calculateGCD(int a, int b) {
    while (b != 0) {
      int temp = b;
      b = a % b;
      a = temp;
    }
    return a;
  }
}
