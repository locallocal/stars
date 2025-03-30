import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/models/openai.dart';
import 'package:bubble/services/models/ollama.dart';
import 'package:bubble/services/models/deepseek.dart';
import 'package:bubble/services/models/gemini.dart';
import 'package:bubble/services/models/grok.dart';
import 'package:bubble/services/models/huggingface.dart';
import 'package:bubble/services/models/anthropic.dart';
import 'package:bubble/services/models/openrouter.dart';
import 'package:bubble/services/models/tencent.dart';
import 'package:bubble/services/models/volcano_engine.dart';
import 'package:bubble/services/models/baidu.dart';
import 'package:bubble/services/models/zhipu.dart';
import 'package:bubble/services/models/zero_one_ai.dart';

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
abstract class ChatModel {
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

  ChatModel(this.bot);

  bool supportsWebSearch() {
    return false;
  }

  bool supportsDeepThinking() {
    return false;
  }

  void setWebSearch(bool enabled) {
    webSearch = enabled;
  }

  void setDeepThinking(bool enabled) {
    deepThinking = enabled;
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

  // 发送消息并获取完整响应
  Future<String> sendMessage(List<ChatMessage> messages);

  // 发送消息并获取流式响应
  Future<void> sendMessageStream(List<ChatMessage> messages);

  // 生成图片
  Future<List<String>> generateImage(
    String prompt,
    String size,
    String imageDirPath,
  ) async {
    // 默认实现抛出异常，子类可以覆盖此方法
    throw UnsupportedError('${bot.apiType}模型不支持图像生成');
  }

  List<String> getSupportedImageSizes() {
    return [];
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

  static ChatModel create(Bot bot) {
    switch (bot.apiType) {
      case Bot.apiTypeOpenAI:
        return OpenAIChatModel(bot);
      case Bot.apiTypeOllama:
        return OllamaChatModel(bot);
      case Bot.apiTypeDeepseek:
        return DeepSeekChatModel(bot);
      case Bot.apiTypeGemini:
        return GeminiChatModel(bot);
      case Bot.apiTypeGrok:
        return GrokChatModel(bot);
      case Bot.apiTypeHuggingface:
        return HuggingFaceChatModel(bot);
      case Bot.apiTypeAnthropic:
        return AnthropicChatModel(bot);
      case Bot.apiTypeVolcanoEngine:
        return VolcanoEngineChatModel(bot);
      case Bot.apiTypeTencent:
        return TencentChatModel(bot);
      case Bot.apiTypeOpenRouter:
        return OpenRouterChatModel(bot);
      case Bot.apiTypeBaidu:
        return BaiduChatModel(bot);
      case Bot.apiTypeZhipu:
        return ZhipuChatModel(bot);
      case Bot.apiTypeZeroOneAI:
        return ZeroOneAIChatModel(bot);
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
          print('Process image ${imagePath} failed: $e');
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
}
