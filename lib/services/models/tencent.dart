import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/models/chat_models.dart';
import 'package:bubble/model/model.dart';

class TencentChatModel extends ChatModel {
  TencentChatModel(Bot bot) : super(bot);

  @override
  Future<List<String>> listModels() async {
    try {
      // 腾讯混元目前支持的模型列表
      return [
        'hunyuan',
        'hunyuan-lite',
        'hunyuan-pro',
        'hunyuan-standard',
        'hunyuan-turbo',
      ];
    } catch (e) {
      print('获取腾讯混元模型列表失败: $e');
      return [];
    }
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    try {
      // 腾讯混元API的端点
      final url = Uri.parse('${bot.baseURL}/v1/chat/completions');

      // 构建请求体 - 腾讯混元API特定格式
      final Map<String, dynamic> requestBody = {
        'model': bot.model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'temperature': 0.7,
        'stream': false,
      };

      // 发送请求
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer ${bot.apiKey}',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode(requestBody),
        encoding: Encoding.getByName('utf-8'), // 确保请求体使用UTF-8编码
      );

      if (response.statusCode == 200) {
        // 确保使用UTF-8解码响应内容
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = jsonDecode(decodedBody);

        // 腾讯混元API的响应格式
        if (data['choices'] != null && data['choices'].length > 0) {
          final String content = data['choices'][0]['message']['content'];
          // 再次确保内容是有效的UTF-8字符串
          return content;
        } else {
          return '请求错误: ${data['msg'] ?? '未知错误'}';
        }
      } else {
        // 处理HTTP错误
        try {
          // 使用UTF-8解码错误响应
          final String decodedError = utf8.decode(response.bodyBytes);
          Map<String, dynamic> errorData = jsonDecode(decodedError);
          String errorMessage = errorData['msg'] ?? '未知错误';
          return '腾讯混元API错误: $errorMessage (${response.statusCode})';
        } catch (e) {
          return '请求失败: HTTP ${response.statusCode}';
        }
      }
    } catch (e) {
      return '请求异常: $e';
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
      resetCancelState();

      // Gemini目前不支持原生流式输出，这里模拟流式输出
      final response = await sendMessage(messages);
      onResponse(response);
      onComplete?.call();
    } catch (e) {
      onError?.call(e.toString());
    } finally {
      // 清理资源
      cancelController?.close();
      cancelController = null;
    }
  }
}
