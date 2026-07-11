import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/database_service.dart';
import 'package:bubble/services/chat_service.dart';

class BotService {
  static List<Bot> _bots = [];
  static final _botListChangedController = StreamController<void>.broadcast();

  static Stream<void> get botListChanged => _botListChangedController.stream;

  static void notifyBotListChanged() {
    _bots = [];
    _botListChangedController.add(null);
  }

  // 获取所有联系人
  static Future<List<Bot>> getBots() async {
    if (_bots.isNotEmpty) {
      return _bots;
    }

    final db = await DatabaseService.database;
    final bots = await db.query('bots', orderBy: 'create_timestamp ASC');
    if (bots.isEmpty) {
      return [];
    }

    _bots =
        bots.map((bot) {
          return Bot.fromMap(bot);
        }).toList();
    return _bots;
  }

  // 获取智能体
  static Future<Bot?> getBot(String id) async {
    final index = _bots.indexWhere((bot) => bot.id == id);
    if (index != -1) {
      return _bots[index];
    }

    final db = await DatabaseService.database;
    final bots = await db.query('bots', where: 'id =?', whereArgs: [id]);
    if (bots.isEmpty) {
      return null;
    }
    var bot = Bot.fromMap(bots.first);
    _bots.add(bot);
    return bot;
  }

  // 添加智能体
  static Future<void> addBot(Bot bot) async {
    final db = await DatabaseService.database;
    await db.insert(
      'bots',
      bot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _bots.add(bot);
    _botListChangedController.add(null);
  }

  // 删除智能体
  static Future<void> deleteBot(String id) async {
    await ChatService.deleteBotChats(id);
    ChatService.notifyChatListChanged();

    final db = await DatabaseService.database;
    await db.delete('bots', where: 'id = ?', whereArgs: [id]);
    _bots.removeWhere((bot) => bot.id == id);
    _botListChangedController.add(null);
  }

  // 更新智能体
  static Future<void> updateBot(Bot updatedBot) async {
    final db = await DatabaseService.database;
    await db.update(
      'bots',
      {
        'name': updatedBot.name,
        'avatar': updatedBot.avatar,
        'provider': updatedBot.provider,
        'base_url': updatedBot.baseURL,
        'api_key': updatedBot.apiKey,
        'model': updatedBot.model,
        'system_prompt': updatedBot.systemPrompt,
        'modify_timestamp': updatedBot.modifyTimestamp.microsecondsSinceEpoch,
      },
      where: 'id =?',
      whereArgs: [updatedBot.id],
    );
    final index = _bots.indexWhere((bot) => bot.id == updatedBot.id);
    if (index != -1) {
      _bots[index] = updatedBot;
    }
    _botListChangedController.add(null);
  }

  static void dispose() {
    _botListChangedController.close();
  }
}
