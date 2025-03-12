import 'package:flutter/material.dart';
import 'package:bubble/services/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bubble/model/model.dart';

class ProfileService {
  static Profile? _profile;
  // 添加主题变化通知的回调函数
  static Function(ThemeMode)? onThemeChanged;

  // 获取用户系统配置信息
  static Future<Profile> getProfile() async {
    if (_profile != null) {
      return _profile!;
    }

    final db = await DatabaseService.database;
    final profiles = await db.query(
      'profile',
      orderBy: 'create_timestamp DESC',
    );
    if (profiles.isEmpty) {
      _profile = Profile(
        name: '用户名',
        avatar: '',
        fontSize: 16.0,
        themeMode: 0,
        createTimestamp: DateTime.now(),
        modifyTimestamp: DateTime.now(),
      );
      await db.insert(
        'profile',
        _profile!.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return _profile!;
    }
    _profile = Profile.fromMap(profiles.first);
    return _profile!;
  }

  static Future<void> updateProfile(Profile profile) async {
    final db = await DatabaseService.database;
    await db.update(
      'profile',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
    _profile = profile;
  }

  // 通知主题变化
  static void notifyThemeChanged(ThemeMode themeMode) {
    if (onThemeChanged != null) {
      onThemeChanged!(themeMode);
    }
  }
}
