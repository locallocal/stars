import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/model/model.dart';

// 定义消息类型
class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

// 定义流式响应回调
typedef StreamResponseCallback = void Function(String text);

// 聊天模型抽象类
abstract class ChatModel {
  final Bot bot;
  // 用于取消请求的控制器
  StreamController<bool>? _cancelController;
  bool _isCancelled = false;

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
    _isCancelled = true;
    _cancelController?.add(true);
  }

  // 重置取消状态
  void _resetCancelState() {
    _isCancelled = false;
    _cancelController = StreamController<bool>();
  }

  // 工厂方法，根据Bot类型创建对应的ChatModel实例
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
      default:
        throw UnsupportedError('不支持的API类型: ${bot.apiType}');
    }
  }
}

// OpenAI模型实现
class OpenAIChatModel extends ChatModel {
  OpenAIChatModel(Bot bot) : super(bot);

  @override
  Future<List<String>> listModels() async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/v1/models'
            : 'https://api.openai.com/v1/models';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${bot.apiKey}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final models =
            (data['data'] as List)
                .map((model) => model['id'] as String)
                .where((id) => id.contains('gpt'))
                .toList();
        return models;
      } else {
        throw Exception('获取模型列表失败: ${response.statusCode}');
      }
    } catch (e) {
      // 如果API调用失败，返回一些默认模型
      return ['gpt-3.5-turbo', 'gpt-4', 'gpt-4-turbo', 'gpt-4o'];
    }
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/v1/chat/completions'
            : 'https://api.openai.com/v1/chat/completions';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bot.apiKey}',
      },
      body: jsonEncode({
        'model': bot.model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('请求失败: ${response.statusCode}');
    }
  }

  @override
  Future<void> sendMessageStream(
    List<ChatMessage> messages,
    StreamResponseCallback onResponse, {
    Function? onComplete,
    Function(String)? onError,
  }) async {
    try {
      // 重置取消状态
      _resetCancelState();

      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/v1/chat/completions'
              : 'https://api.openai.com/v1/chat/completions';

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': messages.map((m) => m.toJson()).toList(),
              'temperature': 0.7,
              'stream': true,
            });

      final streamedResponse = await request.send();
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(LineSplitter());

      // 监听取消事件
      _cancelController?.stream.listen((_) {
        // request.abort(); // 使用abort()方法来取消请求 - 这是错误的
        // 在Dart的http包中，没有直接的方法来取消请求
        // 我们可以通过关闭控制器来间接实现取消
        _cancelController?.close();
      });

      await for (final line in stream) {
        // 检查是否已取消
        if (_isCancelled) break;

        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6);
          if (jsonStr == '[DONE]') {
            // 当收到[DONE]标记时，确保调用onComplete
            if (!_isCancelled && onComplete != null) {
              onComplete();
            }
            return;
          }

          try {
            final data = jsonDecode(jsonStr);
            final delta = data['choices'][0]['delta']['content'] ?? '';
            onResponse(delta);
          } catch (e) {
            // 忽略解析错误
          }
        }
      }

      // 确保在流处理完成后调用onComplete
      if (!_isCancelled && onComplete != null) {
        onComplete();
      } else if (_isCancelled && onError != null) {
        onError('请求已取消');
      }
    } catch (e) {
      if (!_isCancelled && onError != null) {
        onError(e.toString());
      }
    } finally {
      // 清理资源
      _cancelController?.close();
      _cancelController = null;
    }
  }
}

// DeepSeek模型实现
class DeepSeekChatModel extends ChatModel {
  DeepSeekChatModel(Bot bot) : super(bot);

  @override
  Future<List<String>> listModels() async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/models'
            : 'https://api.deepseek.com/models';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${bot.apiKey}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final models =
            (data['data'] as List)
                .map((model) => model['id'] as String)
                .toList();
        return models;
      } else {
        throw Exception('获取模型列表失败: ${response.statusCode}');
      }
    } catch (e) {
      // 如果API调用失败，返回一些默认模型
      return ['deepseek-chat', 'deepseek-reasoner'];
    }
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/v1/chat/completions'
            : 'https://api.deepseek.com/v1/chat/completions';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer ${bot.apiKey}',
      },
      body: jsonEncode({
        'model': bot.model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'temperature': 0.7,
        'max_tokens': 2000,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('请求失败: ${response.statusCode}');
    }
  }

  @override
  Future<void> sendMessageStream(
    List<ChatMessage> messages,
    StreamResponseCallback onResponse, {
    Function? onComplete,
    Function(String)? onError,
  }) async {
    try {
      // 重置取消状态
      _resetCancelState();

      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/v1/chat/completions'
              : 'https://api.deepseek.com/v1/chat/completions';

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': messages.map((m) => m.toJson()).toList(),
              'temperature': 0.7,
              'max_tokens': 2000,
              'stream': true,
            });

      // 监听取消事件
      _cancelController?.stream.listen((_) {
        // request.abort(); // 使用abort()方法来取消请求 - 这是错误的
        // 在Dart的http包中，没有直接的方法来取消请求
        // 我们可以通过关闭控制器来间接实现取消
        _cancelController?.close();
      });

      final streamedResponse = await request.send();
      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('请求失败: ${streamedResponse.statusCode}, $errorBody');
      }

      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(LineSplitter());

      await for (final line in stream) {
        // 检查是否已取消
        if (_isCancelled) break;

        if (line.isEmpty) continue;

        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr == '[DONE]') {
            // 当收到[DONE]标记时，确保调用onComplete
            if (!_isCancelled && onComplete != null) {
              onComplete();
            }
            return;
          }

          try {
            final data = jsonDecode(jsonStr);
            if (data.containsKey('choices') &&
                data['choices'].isNotEmpty &&
                data['choices'][0].containsKey('delta')) {
              final delta = data['choices'][0]['delta']['content'] ?? '';
              if (delta.isNotEmpty) {
                onResponse(delta);
              }
            }
          } catch (e) {
            print('解析DeepSeek响应出错: $e, 原始数据: $jsonStr');
          }
        }
      }

      if (!_isCancelled && onComplete != null) {
        onComplete();
      } else if (_isCancelled && onError != null) {
        onError('请求已取消');
      }
    } catch (e) {
      if (!_isCancelled && onError != null) {
        onError(e.toString());
      }
    } finally {
      // 清理资源
      _cancelController?.close();
      _cancelController = null;
    }
  }
}

// Ollama模型实现
class OllamaChatModel extends ChatModel {
  OllamaChatModel(Bot bot) : super(bot);

  @override
  Future<List<String>> listModels() async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/api/tags'
            : 'http://localhost:11434/api/tags';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final models =
            (data['models'] as List)
                .map((model) => model['name'] as String)
                .toList();
        return models;
      } else {
        throw Exception('获取模型列表失败: ${response.statusCode}');
      }
    } catch (e) {
      // 如果API调用失败，返回一些默认模型
      return ['llama3', 'mistral', 'mixtral', 'phi3', 'qwen'];
    }
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/api/chat'
            : 'http://localhost:11434/api/chat';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': bot.model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['message']['content'];
    } else {
      throw Exception('请求失败: ${response.statusCode}');
    }
  }

  @override
  Future<void> sendMessageStream(
    List<ChatMessage> messages,
    StreamResponseCallback onResponse, {
    Function? onComplete,
    Function(String)? onError,
  }) async {
    try {
      // 重置取消状态
      _resetCancelState();

      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/api/chat'
              : 'http://localhost:11434/api/chat';

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({'Content-Type': 'application/json'})
            ..body = jsonEncode({
              'model': bot.model,
              'messages': messages.map((m) => m.toJson()).toList(),
              'stream': true,
            });

      final streamedResponse = await request.send();
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(LineSplitter());

      // 监听取消事件
      _cancelController?.stream.listen((_) {
        // request.abort(); // 使用abort()方法来取消请求 - 这是错误的
        // 在Dart的http包中，没有直接的方法来取消请求
        // 我们可以通过关闭控制器来间接实现取消
        _cancelController?.close();
      });

      await for (final line in stream) {
        // 检查是否已取消
        if (_isCancelled) break;

        try {
          final data = jsonDecode(line);
          if (data.containsKey('message')) {
            final content = data['message']['content'] ?? '';
            onResponse(content);
          }
        } catch (e) {
          // 忽略解析错误
        }
      }

      if (!_isCancelled && onComplete != null) {
        onComplete();
      } else if (_isCancelled && onError != null) {
        onError('请求已取消');
      }
    } catch (e) {
      if (onError != null) {
        onError(e.toString());
      }
    }
  }
}

// Gemini模型实现
class GeminiChatModel extends ChatModel {
  GeminiChatModel(Bot bot) : super(bot);

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/v1beta/models/${bot.model}:generateContent'
            : 'https://generativelanguage.googleapis.com/v1beta/models/${bot.model}:generateContent';

    // 转换消息格式为Gemini格式
    final geminiMessages =
        messages
            .map(
              (m) => {
                'role': m.role == 'user' ? 'user' : 'model',
                'parts': [
                  {'text': m.content},
                ],
              },
            )
            .toList();

    final response = await http.post(
      Uri.parse('$url?key=${bot.apiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': geminiMessages,
        'generationConfig': {'temperature': 0.7},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('请求失败: ${response.statusCode}');
    }
  }

  @override
  Future<void> sendMessageStream(
    List<ChatMessage> messages,
    StreamResponseCallback onResponse, {
    Function? onComplete,
    Function(String)? onError,
  }) async {
    try {
      // 重置取消状态
      _resetCancelState();

      // Gemini目前不支持原生流式输出，这里模拟流式输出
      final response = await sendMessage(messages);

      // 将完整响应分成小块模拟流式输出
      const chunkSize = 10;
      for (var i = 0; i < response.length; i += chunkSize) {
        // 检查是否已取消
        if (_isCancelled) break;

        final end =
            (i + chunkSize < response.length) ? i + chunkSize : response.length;
        final chunk = response.substring(i, end);
        onResponse(chunk);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      if (!_isCancelled && onComplete != null) {
        onComplete();
      } else if (_isCancelled && onError != null) {
        onError('请求已取消');
      }
    } catch (e) {
      if (!_isCancelled && onError != null) {
        onError(e.toString());
      }
    } finally {
      // 清理资源
      _cancelController?.close();
      _cancelController = null;
    }
  }
}

// Grok模型实现
class GrokChatModel extends ChatModel {
  GrokChatModel(Bot bot) : super(bot);

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/v1/chat/completions'
            : 'https://api.grok.ai/v1/chat/completions';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bot.apiKey}',
      },
      body: jsonEncode({
        'model': bot.model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('请求失败: ${response.statusCode}');
    }
  }

  @override
  Future<void> sendMessageStream(
    List<ChatMessage> messages,
    StreamResponseCallback onResponse, {
    Function? onComplete,
    Function(String)? onError,
  }) async {
    try {
      // 重置取消状态
      _resetCancelState();

      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/v1/chat/completions'
              : 'https://api.grok.ai/v1/chat/completions';

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': messages.map((m) => m.toJson()).toList(),
              'temperature': 0.7,
              'stream': true,
            });

      final streamedResponse = await request.send();
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(LineSplitter());

      // 监听取消事件
      _cancelController?.stream.listen((_) {
        // request.abort(); // 使用abort()方法来取消请求 - 这是错误的
        // 在Dart的http包中，没有直接的方法来取消请求
        // 我们可以通过关闭控制器来间接实现取消
        _cancelController?.close();
      });

      await for (final line in stream) {
        // 检查是否已取消
        if (_isCancelled) break;

        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6);
          if (jsonStr == '[DONE]') {
            // 当收到[DONE]标记时，确保调用onComplete
            if (!_isCancelled && onComplete != null) {
              onComplete();
            }
            return;
          }

          try {
            final data = jsonDecode(jsonStr);
            final delta = data['choices'][0]['delta']['content'] ?? '';
            onResponse(delta);
          } catch (e) {
            // 忽略解析错误
          }
        }
      }

      if (!_isCancelled && onComplete != null) {
        onComplete();
      } else if (_isCancelled && onError != null) {
        onError('请求已取消');
      }
    } catch (e) {
      if (onError != null) {
        onError(e.toString());
      }
    }
  }
}

// HuggingFace模型实现
class HuggingFaceChatModel extends ChatModel {
  HuggingFaceChatModel(Bot bot) : super(bot);

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? bot.baseURL
            : 'https://api-inference.huggingface.co/models/${bot.model}';

    // 将消息格式化为单个文本
    final prompt = _formatMessagesToPrompt(messages);

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bot.apiKey}',
      },
      body: jsonEncode({
        'inputs': prompt,
        'parameters': {
          'temperature': 0.7,
          'max_new_tokens': 1024,
          'return_full_text': false,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      // HuggingFace API可能返回不同格式的响应，需要根据实际情况处理
      if (data is List && data.isNotEmpty) {
        return data[0]['generated_text'] ?? '';
      } else if (data is Map) {
        return data['generated_text'] ?? '';
      }
      return data.toString();
    } else {
      throw Exception('请求失败: ${response.statusCode}');
    }
  }

  @override
  Future<void> sendMessageStream(
    List<ChatMessage> messages,
    StreamResponseCallback onResponse, {
    Function? onComplete,
    Function(String)? onError,
  }) async {
    try {
      // HuggingFace Inference API目前不支持原生流式输出，这里模拟流式输出
      final response = await sendMessage(messages);

      // 将完整响应分成小块模拟流式输出
      const chunkSize = 8;
      for (var i = 0; i < response.length; i += chunkSize) {
        final end =
            (i + chunkSize < response.length) ? i + chunkSize : response.length;
        final chunk = response.substring(i, end);
        onResponse(chunk);
        await Future.delayed(const Duration(milliseconds: 30));
      }

      if (onComplete != null) {
        onComplete();
      }
    } catch (e) {
      if (onError != null) {
        onError(e.toString());
      }
    }
  }

  // 将消息列表格式化为适合HuggingFace模型的提示文本
  String _formatMessagesToPrompt(List<ChatMessage> messages) {
    final buffer = StringBuffer();

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];

      if (message.role == 'system') {
        buffer.write('System: ${message.content}\n\n');
      } else if (message.role == 'user') {
        buffer.write('Human: ${message.content}\n');
      } else if (message.role == 'assistant') {
        buffer.write('AI: ${message.content}\n');
      }

      // 如果是最后一条用户消息，添加AI前缀以提示模型生成回复
      if (i == messages.length - 1 && message.role == 'user') {
        buffer.write('AI: ');
      }
    }

    return buffer.toString();
  }
}

// Anthropic模型实现
class AnthropicChatModel extends ChatModel {
  AnthropicChatModel(Bot bot) : super(bot);

  @override
  Future<List<String>> listModels() async {
    // Anthropic目前没有公开的模型列表API，返回已知模型
    return [
      'claude-3-opus-20240229',
      'claude-3-sonnet-20240229',
      'claude-3-haiku-20240307',
    ];
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/v1/messages'
            : 'https://api.anthropic.com/v1/messages';

    // 转换消息格式为Anthropic格式
    final systemPrompt =
        messages
            .firstWhere(
              (m) => m.role == 'system',
              orElse: () => ChatMessage(role: 'system', content: ''),
            )
            .content;

    final anthropicMessages =
        messages
            .where((m) => m.role != 'system')
            .map(
              (m) => {
                'role': m.role == 'assistant' ? 'assistant' : 'user',
                'content': m.content,
              },
            )
            .toList();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': bot.apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': bot.model,
        'messages': anthropicMessages,
        'system': systemPrompt,
        'max_tokens': 2000,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['content'][0]['text'];
    } else {
      throw Exception('请求失败: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  Future<void> sendMessageStream(
    List<ChatMessage> messages,
    StreamResponseCallback onResponse, {
    Function? onComplete,
    Function(String)? onError,
  }) async {
    try {
      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/v1/messages'
              : 'https://api.anthropic.com/v1/messages';

      // 提取系统提示
      final systemPrompt =
          messages
              .firstWhere(
                (m) => m.role == 'system',
                orElse: () => ChatMessage(role: 'system', content: ''),
              )
              .content;

      // 过滤掉系统提示
      final anthropicMessages =
          messages
              .where((m) => m.role != 'system')
              .map(
                (m) => {
                  'role': m.role == 'assistant' ? 'assistant' : 'user',
                  'content': m.content,
                },
              )
              .toList();

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'x-api-key': bot.apiKey,
              'anthropic-version': '2023-06-01',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': anthropicMessages,
              'system': systemPrompt,
              'max_tokens': 2000,
              'temperature': 0.7,
              'stream': true,
            });

      final streamedResponse = await request.send();

      await streamedResponse.stream
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .forEach((line) {
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6);
              if (jsonStr == '[DONE]') return;

              try {
                final data = jsonDecode(jsonStr);
                if (data['type'] == 'content_block_delta') {
                  final delta = data['delta']['text'] ?? '';
                  onResponse(delta);
                }
              } catch (e) {
                // 忽略解析错误
              }
            }
          });

      if (onComplete != null) {
        onComplete();
      }
    } catch (e) {
      if (onError != null) {
        onError(e.toString());
      }
    }
  }
}
