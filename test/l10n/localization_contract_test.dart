import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';

void main() {
  final catalogs = <Locale, File>{
    for (final locale in supportedLocales) locale: File(_catalogPath(locale)),
  };

  test('supported locale catalogs have key and placeholder parity', () {
    final template = _readCatalog(File('lib/l10n/intl_en.arb'));
    final expectedKeys = _messageKeys(template);
    expect(
      expectedKeys,
      containsAll(const {
        'answerTrustUnverified',
        'answerTrustFailed',
        'answerTrustReasonNoTool',
        'answerTrustReasonProviderUnsupported',
        'answerTrustReasonToolRejected',
        'answerTrustReasonProviderFailed',
        'answerTrustReasonGateFailed',
        'answerTrustReasonUnavailable',
        'answerTrustSemanticLabel',
      }),
    );

    for (final entry in catalogs.entries) {
      expect(entry.value.existsSync(), isTrue, reason: entry.value.path);
      final catalog = _readCatalog(entry.value);
      final actualKeys = _messageKeys(catalog);
      expect(actualKeys, expectedKeys, reason: entry.value.path);

      for (final key in expectedKeys) {
        final value = catalog[key];
        expect(value, isA<String>(), reason: '${entry.value.path}: $key');
        final localizedValue = value! as String;
        expect(
          localizedValue.trim(),
          isNotEmpty,
          reason: '${entry.value.path}: $key',
        );
        expect(
          _placeholders(localizedValue),
          _placeholders(template[key]! as String),
          reason: '${entry.value.path}: $key',
        );
      }
    }
  });

  for (final locale in supportedLocales) {
    testWidgets('${locale.toString()} renders localized UI', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            S.delegate,
          ],
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: Text(
                    S.of(context).appName,
                    key: const ValueKey<String>('localized-app-name'),
                  ),
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('localized-app-name')),
        findsOneWidget,
      );
      expect(find.text('Stars'), findsOneWidget);
    });
  }
}

String _catalogPath(Locale locale) {
  if (locale.languageCode == 'en') return 'lib/l10n/intl_en.arb';
  final countryCode = locale.countryCode;
  final suffix =
      countryCode == null || countryCode.isEmpty
          ? locale.languageCode
          : '${locale.languageCode}_$countryCode';
  return 'lib/l10n/intl_$suffix.arb';
}

Map<String, Object?> _readCatalog(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
    throw FormatException('${file.path} must contain a JSON object.');
  }
  return decoded.cast<String, Object?>();
}

Set<String> _messageKeys(Map<String, Object?> catalog) =>
    catalog.keys.where((key) => !key.startsWith('@')).toSet();

Set<String> _placeholders(String message) =>
    RegExp(
      r'\{([A-Za-z][A-Za-z0-9_]*)(?:,|\})',
    ).allMatches(message).map((match) => match.group(1)!).toSet();
