import 'dart:async';
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

// 定义消息类型
class ChatMessage {
  final String role;
  final String content;
  bool? deepThinking;
  bool? webSearch;

  ChatMessage({required this.role, required this.content, this.deepThinking, this.webSearch});

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

  ChatModel(this.bot);

  // 发送消息并获取完整响应
  Future<String> sendMessage(List<ChatMessage> messages);

  // 发送消息并获取流式响应
  Future<void> sendMessageStream(
    List<ChatMessage> messages,
    StreamResponseCallback onResponse, {
    Function? onComplete,
    Function(String)? onError,
  });

  // 获取模型列表
  Future<List<String>> listModels() async {
    // 默认实现返回空列表，子类可以覆盖此方法
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
      default:
        throw UnsupportedError('Not support api type: ${bot.apiType}');
    }
  }

  bool supportsWebSearch() {
    return false;
  }

  bool supportsDeepThinking() {
    return false;
  }

  List<InputModality> getInputModalites() {
    return [InputModality.text];
  }

  List<OutputModality> getOutputModalites() {
    return [OutputModality.text];
  }
}
