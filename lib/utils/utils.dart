import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// 自定义函数将 int 转换为 ThemeMode
ThemeMode intToThemeMode(int value) {
  switch (value) {
    case 0:
      return ThemeMode.system;
    case 1:
      return ThemeMode.light;
    case 2:
      return ThemeMode.dark;
    default:
      // 当传入的 int 值不在 0 - 2 范围内时，默认返回 ThemeMode.system
      return ThemeMode.system;
  }
}

// 自定义函数将 int 转换为 ThemeMode
int themeModeToInt(ThemeMode value) {
  switch (value) {
    case ThemeMode.system:
      return 0;
    case ThemeMode.light:
      return 1;
    case ThemeMode.dark:
      return 2;
  }
}

// 创建聊天文件夹
Future<void> createChatDirectory(String chatId) async {
  final appDir = await getApplicationDocumentsDirectory();
  final chatDir = Directory(path.join(appDir.path, 'chats', chatId));
  try {
    if (!await chatDir.exists()) {
      await chatDir.create(recursive: true);
    }
  } catch (e) {
    debugPrint('Create chat directory $chatDir failed: $e');
  }
}

// 删除聊天文件夹
Future<bool> deleteChatDirectory(String chatId) async {
  var chatDirStr = await getChatDirectoryPath(chatId);
  try {
    final chatDir = Directory(chatDirStr);
    if (await chatDir.exists()) {
      await chatDir.delete(recursive: true);
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('Delete chat directory $chatDirStr for $chatId failed: $e');
    return false;
  }
}

Future<String> getChatDirectoryPath(String chatId) async {
  final appDir = await getApplicationDocumentsDirectory();
  return path.join(appDir.path, 'chats', chatId);
}

bool isDesktopPlatform(BuildContext context) {
  if (kIsWeb) {
    return false;
  }

  final platform = defaultTargetPlatform;
  return platform == TargetPlatform.windows ||
      platform == TargetPlatform.macOS ||
      platform == TargetPlatform.linux;
}

bool isDesktopOrTabletPlatform(BuildContext context) {
  // 兼容既有调用方，但桌面工作台样式现在只对 Windows/Linux/macOS 生效。
  return isDesktopPlatform(context);
}
