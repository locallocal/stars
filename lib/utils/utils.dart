import 'package:flutter/material.dart';

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
