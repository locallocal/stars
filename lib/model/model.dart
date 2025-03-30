import 'dart:convert';

enum InputModality {
  text('text'),
  image('image'),
  file('file'),
  audio('audio'),
  video('video');

  final String value;
  const InputModality(this.value);
}

enum OutputModality {
  text('text'),
  image('image'),
  audio('audio'),
  video('video');

  final String value;
  const OutputModality(this.value);
}

// 机器人信息
class Bot {
  static const apiTypeOpenAI = "openai";
  static const apiTypeAzure = "azure";
  static const apiTypeOllama = "ollama";
  static const apiTypeGemini = "gemini";
  static const apiTypeDeepseek = "deepseek";
  static const apiTypeGrok = "grok";
  static const apiTypeHuggingface = "huggingface";
  static const apiTypeOpenRouter = 'openrouter';
  static const apiTypeAnthropic = "anthropic";
  static const apiTypeVolcanoEngine = "volcanoengine";
  static const apiTypeTencent = "tencent";
  static const apiTypeBaidu = "baidu";
  static const String apiTypeZhipu = 'zhipu';

  final String id;
  final String name;
  final String avatar;
  final String provider;
  final String baseURL;
  final String apiKey;
  final String apiType;
  final String model;
  final String systemPrompt;
  final Map<String, dynamic>? parameters;
  final DateTime createTimestamp;
  final DateTime modifyTimestamp;

  const Bot({
    required this.id,
    required this.name,
    required this.avatar,
    required this.provider,
    required this.baseURL,
    required this.apiKey,
    required this.apiType,
    required this.model,
    required this.systemPrompt,
    this.parameters,
    required this.createTimestamp,
    required this.modifyTimestamp,
  });

  factory Bot.fromMap(Map<String, dynamic> map) {
    // 从JSON字符串解析parameters
    Map<String, dynamic>? params;
    if (map['parameters'] != null) {
      // 如果是字符串，尝试解析JSON
      try {
        params =
            jsonDecode(map['parameters'] as String) as Map<String, dynamic>;
      } catch (e) {
        print('解析parameters失败: $e');
        params = {};
      }
    } else if (map['parameters'] is Map) {
      // 如果已经是Map，直接使用
      params = Map<String, dynamic>.from(map['parameters'] as Map);
    }

    return Bot(
      id: map['id'] as String,
      name: map['name'] as String,
      avatar: map['avatar'] as String,
      provider: map['provider'] as String,
      baseURL: map['base_url'] as String,
      apiKey: map['api_key'] as String,
      apiType: map['api_type'] as String,
      model: map['model'] as String,
      systemPrompt: map['system_prompt'] as String,
      parameters: params,
      createTimestamp: DateTime.fromMillisecondsSinceEpoch(
        map['create_timestamp'] as int,
      ),
      modifyTimestamp: DateTime.fromMillisecondsSinceEpoch(
        map['modify_timestamp'] as int,
      ),
    );
  }

  Map<String, Object> toMap() {
    // 将parameters转换为JSON字符串
    String paramsJson = '{}';
    if (parameters != null && parameters!.isNotEmpty) {
      try {
        paramsJson = jsonEncode(parameters);
      } catch (e) {
        print('序列化parameters失败: $e');
      }
    }

    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'provider': provider,
      'base_url': baseURL,
      'api_key': apiKey,
      'api_type': apiType,
      'model': model,
      'system_prompt': systemPrompt,
      'parameters': paramsJson,
      'create_timestamp': createTimestamp.millisecondsSinceEpoch,
      'modify_timestamp': modifyTimestamp.millisecondsSinceEpoch,
    };
  }

  // 获取所有API类型
  static List<String> getAllApiTypes() {
    return [
      apiTypeOpenAI,
      apiTypeAnthropic,
      apiTypeGemini,
      apiTypeDeepseek,
      apiTypeOllama,
      apiTypeHuggingface,
      apiTypeGrok,
      apiTypeVolcanoEngine,
      apiTypeTencent,
      apiTypeBaidu,
      apiTypeOpenRouter,
      apiTypeZhipu,
    ];
  }
}

// 消息
class Message {
  final String chatId;
  final String botId;
  final String senderId;
  final String content;
  final String reasoning;
  final List<String> images; // 图片路径列表
  final List<String> files; // 文件路径列表
  final DateTime timestamp;

  const Message({
    required this.chatId,
    required this.botId,
    required this.senderId,
    required this.content,
    this.reasoning = '',
    this.images = const [],
    this.files = const [],
    required this.timestamp,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    // 处理图片列表
    List<String> imagesList = [];
    if (map['images'] != null) {
      if (map['images'] is String) {
        try {
          final List<dynamic> decoded = jsonDecode(map['images'] as String);
          imagesList = decoded.map((e) => e.toString()).toList();
        } catch (e) {
          print('Parse images failed: $e');
        }
      } else if (map['images'] is List) {
        imagesList = (map['images'] as List).map((e) => e.toString()).toList();
      }
    }

    // 处理文件列表
    List<String> filesList = [];
    if (map['files'] != null) {
      if (map['files'] is String) {
        try {
          final List<dynamic> decoded = jsonDecode(map['files'] as String);
          filesList = decoded.map((e) => e.toString()).toList();
        } catch (e) {
          print('Parse files failed: $e');
        }
      } else if (map['files'] is List) {
        filesList = (map['files'] as List).map((e) => e.toString()).toList();
      }
    }

    return Message(
      chatId: map['chat_id'] as String,
      botId: map['bot_id'] as String,
      senderId: map['sender_id'] as String,
      content: map['content'] as String,
      reasoning: map['reasoning'] as String,
      images: imagesList,
      files: filesList,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  Map<String, Object> toMap() {
    return {
      'chat_id': chatId,
      'bot_id': botId,
      'sender_id': senderId,
      'content': content,
      'reasoning': reasoning,
      'images': jsonEncode(images),
      'files': jsonEncode(files),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

// 聊天信息
class Chat {
  final String id;
  final String botId;
  final String lastMessage;
  final DateTime lastMessageTimestamp;
  final DateTime createTimestamp;
  final DateTime modifyTimestamp;

  const Chat({
    required this.id,
    required this.botId,
    this.lastMessage = '',
    required this.lastMessageTimestamp,
    required this.createTimestamp,
    required this.modifyTimestamp,
  });

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] as String,
      botId: map['bot_id'] as String,
      lastMessage: map['last_message'] as String,
      lastMessageTimestamp: DateTime.fromMillisecondsSinceEpoch(
        map['last_message_timestamp'] as int,
      ),
      createTimestamp: DateTime.fromMillisecondsSinceEpoch(
        map['create_timestamp'] as int,
      ),
      modifyTimestamp: DateTime.fromMillisecondsSinceEpoch(
        map['modify_timestamp'] as int,
      ),
    );
  }

  Map<String, Object> toMap() {
    return {
      'id': id,
      'bot_id': botId,
      'last_message': lastMessage,
      'last_message_timestamp': lastMessageTimestamp.millisecondsSinceEpoch,
      'create_timestamp': createTimestamp.millisecondsSinceEpoch,
      'modify_timestamp': modifyTimestamp.millisecondsSinceEpoch,
    };
  }
}

class Profile {
  final String name;
  final String avatar;
  final double fontSize;
  final int themeMode;
  final String language;
  final DateTime createTimestamp;
  final DateTime modifyTimestamp;

  const Profile({
    required this.name,
    required this.avatar,
    required this.fontSize,
    required this.themeMode,
    required this.language,
    required this.createTimestamp,
    required this.modifyTimestamp,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      name: map['name'] as String,
      avatar: map['avatar'] as String,
      fontSize: map['font_size'] as double,
      themeMode: map['theme_mode'] as int,
      language: map['language'] as String,
      createTimestamp: DateTime.fromMillisecondsSinceEpoch(
        map['create_timestamp'] as int,
      ),
      modifyTimestamp: DateTime.fromMillisecondsSinceEpoch(
        map['modify_timestamp'] as int,
      ),
    );
  }

  Map<String, Object> toMap() {
    return {
      'name': name,
      'avatar': avatar,
      'font_size': fontSize,
      'theme_mode': themeMode,
      'language': language,
      'create_timestamp': createTimestamp.millisecondsSinceEpoch,
      'modify_timestamp': modifyTimestamp.millisecondsSinceEpoch,
    };
  }
}
