import 'package:flutter/widgets.dart';


const List<Locale> supportedLocales = <Locale>[
  Locale('zh', 'CN'), // 简体中文
  Locale('en', 'US'), // 英文
  Locale('zh', 'TW'), // 繁体中文
  Locale('ja', 'JP'), // 日语
  Locale('fr', 'FR'), // 法语
  Locale('de', 'DE'), // 德语
  Locale('ko', 'KR'), // 韩语
  Locale('ru', 'RU'), // 俄语
  Locale('es', 'ES'), // 西班牙语
  Locale('hi', 'IN'), // 印地语
  Locale('pt', 'BR'), // 葡萄牙语(巴西)
  Locale('it', 'IT'), // 意大利语
];

// 获取语言名称
String getLanguageName(String code) {
  switch (code) {
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
    case 'es_ES':
      return 'Español';
    case 'hi_IN':
      return 'हिन्दी';
    case 'pt_BR':
      return 'Português';
    case 'it_IT':
      return 'Italiano';
    default:
      return '简体中文';
  }
}