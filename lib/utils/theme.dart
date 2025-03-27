import 'package:flutter/material.dart';

// 定义一个全局的主题变量
ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(),
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: Colors.black,
    onPrimary: Colors.white,
    surface: Colors.grey,
    onSurface: Colors.black,
  ),
);
