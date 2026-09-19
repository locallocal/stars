import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/generated/l10n.dart';

void main() {
  const localeFiles = <String>[
    'intl_zh_CN.arb',
    'intl_en.arb',
    'intl_zh_TW.arb',
    'intl_ja_JP.arb',
    'intl_fr_FR.arb',
    'intl_de_DE.arb',
    'intl_ko_KR.arb',
    'intl_ru_RU.arb',
    'intl_es_ES.arb',
    'intl_hi_IN.arb',
    'intl_pt_BR.arb',
    'intl_it_IT.arb',
  ];

  test('every supported locale defines all settings page messages', () {
    final profileSource = Directory('lib/ui/features/profile/views')
        .listSync()
        .whereType<File>()
        .where(
          (file) =>
              file.uri.pathSegments.last.startsWith('profile') &&
              file.path.endsWith('.dart'),
        )
        .map((file) => file.readAsStringSync())
        .join('\n');
    final settingsKeys =
        RegExp(
          r'S\.of\([^)]*\)\s*\.\s*([A-Za-z0-9_]+)',
        ).allMatches(profileSource).map((match) => match.group(1)!).toSet();

    final modelLogSource =
        File(
          'lib/ui/features/chat/views/model_log_settings.dart',
        ).readAsStringSync();
    settingsKeys.addAll(
      RegExp(
        r'\bs\.(model\w+)',
      ).allMatches(modelLogSource).map((match) => match[1]!),
    );
    expect(settingsKeys, contains('modelRequestLogging'));
    expect(settingsKeys, contains('enterDisplayName'));
    expect(profileSource, isNot(contains('.enterBotName')));

    for (final fileName in localeFiles) {
      final file = File('lib/l10n/$fileName');
      expect(file.existsSync(), isTrue, reason: file.path);

      final messages =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final key in settingsKeys) {
        expect(
          messages[key],
          isA<String>().having(
            (value) => value.trim(),
            'trimmed value',
            isNotEmpty,
          ),
          reason: '$fileName is missing $key',
        );
      }
    }
  });

  test('generated settings messages load for every supported locale', () async {
    final expectedPersonalInformation = <Locale, String>{
      Locale('zh', 'CN'): '个人信息',
      Locale('en', 'US'): 'Personal Information',
      Locale('zh', 'TW'): '個人資訊',
      Locale('ja', 'JP'): '個人情報',
      Locale('fr', 'FR'): 'Informations personnelles',
      Locale('de', 'DE'): 'Persönliche Informationen',
      Locale('ko', 'KR'): '개인 정보',
      Locale('ru', 'RU'): 'Личная информация',
      Locale('es', 'ES'): 'Información personal',
      Locale('hi', 'IN'): 'व्यक्तिगत जानकारी',
      Locale('pt', 'BR'): 'Informações pessoais',
      Locale('it', 'IT'): 'Informazioni personali',
    };

    for (final entry in expectedPersonalInformation.entries) {
      await S.load(entry.key);
      expect(
        S.current.desktopPersonalInformation,
        entry.value,
        reason: entry.key.toString(),
      );
    }
  });
}
