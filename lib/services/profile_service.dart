import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/database_service.dart';
import 'package:bubble/utils/utils.dart';

class ProfileService {
  // 主题变更流
  static final StreamController<ThemeMode> _themeController =
      StreamController<ThemeMode>.broadcast();
  static Stream<ThemeMode> get themeStream => _themeController.stream;

  // 字体大小变更流
  static final StreamController<double> _fontSizeController =
      StreamController<double>.broadcast();
  static Stream<double> get fontSizeStream => _fontSizeController.stream;

  // 语言变更流
  static final StreamController<String> _languageController =
      StreamController<String>.broadcast();
  static Stream<String> get languageStream => _languageController.stream;

  // 通知主题变更
  static void notifyThemeChanged(ThemeMode themeMode) {
    _themeController.add(themeMode);
  }

  // 通知字体大小变更
  static void notifyFontSizeChanged(double fontSize) {
    _fontSizeController.add(fontSize);
  }

  // 通知语言变更
  static void notifyLanguageChanged(String language) {
    _languageController.add(language);
  }

  // 获取个人资料
  static Future<Profile> getProfile() async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('profile');

    if (maps.isEmpty) {
      // 创建默认个人资料
      final profile = Profile(
        name: '用户名',
        avatar: '',
        fontSize: 16.0,
        themeMode: 0, // 系统
        language: 'zh_CN', // 默认简体中文
        createTimestamp: DateTime.now(),
        modifyTimestamp: DateTime.now(),
      );
      await updateProfile(profile);
      return profile;
    }

    return Profile.fromMap(maps.first);
  }

  // 更新个人资料
  static Future<void> updateProfile(Profile profile) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('profile');

    if (maps.isEmpty) {
      // 插入新记录
      await db.insert('profile', profile.toMap());
    } else {
      // 更新现有记录
      await db.update(
        'profile',
        profile.toMap(),
        where: 'id = ?',
        whereArgs: [maps.first['id']],
      );
    }

    // 通知更新
    notifyThemeChanged(intToThemeMode(profile.themeMode));
    notifyFontSizeChanged(profile.fontSize);
    if (profile.language.isNotEmpty) {
      notifyLanguageChanged(profile.language);
    }
  }
}
