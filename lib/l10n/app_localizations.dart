import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

// 使用 intl 包的国际化方式
class AppLocalizations {
  AppLocalizations(this.localeName);

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh', 'CN'), // 简体中文
    Locale('en', 'US'), // 英文
    Locale('zh', 'TW'), // 繁体中文
    Locale('ja', 'JP'), // 日语
    Locale('fr', 'FR'), // 法语
    Locale('de', 'DE'), // 德语
    Locale('ko', 'KR'), // 韩语
    Locale('ru', 'RU'), // 俄语
  ];

  // 获取本地化文本
  String _getMessage(String key, {List<Object>? args}) {
    // 根据当前语言环境获取对应的翻译
    String? message;
    try {
      // 尝试使用 Intl 获取翻译
      message = Intl.message(key, name: key, args: args, locale: localeName);
    } catch (e) {
      print('获取翻译失败: $e');
    }
    // 如果没有找到翻译，则使用默认值
    if (message == null || message.isEmpty) {
      message = _getDefaultMessage(key, args);
    }
    return message;
  }

  // 获取默认消息（中文）
  String _getDefaultMessage(String key, List<Object>? args) {
    final messages = {
      // 通用文本
      'appName': '泡泡',
      'profile': '我的',
      'settings': '设置',
      'about': '关于',
      'cancel': '取消',
      'save': '保存',
      'confirm': '确定',
      
      // 主页相关
      'home': '首页',
      'chats': '聊天',
      'newChat': '新建聊天',
      
      // 设置相关
      'themeSettings': '主题设置',
      'followSystem': '跟随系统',
      'lightMode': '浅色模式',
      'darkMode': '深色模式',
      'languageSettings': '语言设置',
      'fontSizeSettings': '文字大小',
      'adjustAppFontSize': '调整应用内文字大小',
      
      // 个人资料相关
      'name': '名称',
      'editName': '修改名称',
      'enterNewName': '请输入新名称',
      'nameUpdated': '名称已更新',
      
      // 聊天相关
      'send': '发送',
      'typing': '正在输入...',
      'clearChat': '清空聊天',
      
      // 机器人相关
      'addBot': '添加机器人',
      'editBot': '编辑机器人',
      'botName': '机器人名称',
      'botAvatar': '机器人头像',
      'provider': '供应商',
      'apiKey': 'API密钥',
      'model': '模型',
      'systemPrompt': '系统提示词',
      
      // 带参数的消息
      'languageChanged': '语言已设置为${args != null && args.isNotEmpty ? args[0] : ""}',
    };
    return messages[key] ?? key;
  }

  // 通用文本
  String get appName => _getMessage('appName');
  String get profile => _getMessage('profile');
  String get settings => _getMessage('settings');
  String get about => _getMessage('about');
  String get cancel => _getMessage('cancel');
  String get save => _getMessage('save');
  String get confirm => _getMessage('confirm');
  
  // 主页相关
  String get home => _getMessage('home');
  String get chats => _getMessage('chats');
  String get newChat => _getMessage('newChat');
  
  // 设置相关
  String get themeSettings => _getMessage('themeSettings');
  String get followSystem => _getMessage('followSystem');
  String get lightMode => _getMessage('lightMode');
  String get darkMode => _getMessage('darkMode');
  String get languageSettings => _getMessage('languageSettings');
  String get fontSizeSettings => _getMessage('fontSizeSettings');
  String get adjustAppFontSize => _getMessage('adjustAppFontSize');
  
  // 个人资料相关
  String get name => _getMessage('name');
  String get editName => _getMessage('editName');
  String get enterNewName => _getMessage('enterNewName');
  String get nameUpdated => _getMessage('nameUpdated');
  
  // 聊天相关
  String get send => _getMessage('send');
  String get typing => _getMessage('typing');
  String get clearChat => _getMessage('clearChat');
  
  // 机器人相关
  String get addBot => _getMessage('addBot');
  String get editBot => _getMessage('editBot');
  String get botName => _getMessage('botName');
  String get botAvatar => _getMessage('botAvatar');
  String get provider => _getMessage('provider');
  String get apiKey => _getMessage('apiKey');
  String get model => _getMessage('model');
  String get systemPrompt => _getMessage('systemPrompt');
  
  // 带参数的消息
  String languageChanged(String language) => _getMessage('languageChanged', args: [language]);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    // 设置当前区域
    final String name = locale.countryCode == null || locale.countryCode!.isEmpty
        ? locale.languageCode
        : locale.toString();
    
    // 确保 Intl 使用正确的区域设置
    final String localeName = Intl.canonicalizedLocale(name);
    Intl.defaultLocale = localeName;
    
    return SynchronousFuture<AppLocalizations>(
      AppLocalizations(localeName),
    );
  }

  @override
  bool isSupported(Locale locale) {
    for (var supportedLocale in AppLocalizations.supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

String getLanguageName(String languageCode) {
  switch (languageCode) {
    case 'zh_CN':
      return '简体中文';
    case 'en_US':
      return 'English';
    case 'zh_TW':
      return '繁體中文';
    case 'ja_JP':
      return '日本語';
    case 'fr_FR':
      return 'Français';
    case 'de_DE':
      return 'Deutsch';
    case 'ko_KR':
      return '한국어';
    case 'ru_RU':
      return 'Русский';
    default:
      return '简体中文';
  }
}