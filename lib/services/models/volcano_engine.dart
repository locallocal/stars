import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/models/chat_models.dart';
import 'package:bubble/model/model.dart';

class VolcanoEngineChatModel extends ChatModel {
  VolcanoEngineChatModel(Bot bot) : super(bot);
  
  @override
  Future<List<String>> listModels() async {
    try {
      // 火山引擎目前支持的模型列表
      // 这里是硬编码的模型列表，因为火山引擎可能没有提供获取模型列表的API
      return [
        'doubao-1-5-vision-pro-32k-250115',
      ];
    } catch (e) {
      print('获取火山引擎模型列表失败: $e');
      return [];
    }
  }
  
  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    try {
      // 构建火山引擎API请求URL
      final url = Uri.parse('${bot.baseURL}/v3/chat/completions');
      print(url);
      
      // 构建请求体
      final Map<String, dynamic> requestBody = {
        'model': bot.model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'parameters': {
          'temperature': 0.7,
          'top_p': 0.95,
          'max_tokens': 1024,
        },
      };
      // 发送请求
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${bot.apiKey}',
          'X-VolcEngine-Service': 'volc-llm',
        },
        body: jsonEncode(requestBody),
      );
      print(response.body);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // 检查火山引擎API的响应格式
        if (data['choices'] != null && data['choices'].length > 0) {
          final String content = data['choices'][0]['message']['content'];
          return content;
        } else {
          return '请求错误: ${data['msg'] ?? '未知错误'}';
        }
      } else {
        // 处理HTTP错误
        try {
          Map<String, dynamic> errorData = jsonDecode(response.body);
          String errorMessage = errorData['base_resp']?['status_message'] ?? '未知错误';
          return '火山引擎API错误: $errorMessage (${response.statusCode})';
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