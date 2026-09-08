import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
  const executionStatusKeys = <String>[
    'replyStoppedPartial',
    'generationFailedPartial',
    'generationFailed',
    'noContentReturned',
    'partialResponse',
    'statusCompleted',
    'processDuration',
    'processToolCount',
    'processCommandCount',
    'processFileCount',
    'executionStatus',
    'toolCalls',
    'commandExecutions',
    'fileStatus',
    'structuredProcessInfo',
    'statusGenerated',
    'statusAttached',
    'statusInProgress',
    'statusRunning',
    'statusCancelled',
    'statusFailed',
    'modelTurnLimitReached',
    'statusRecorded',
    'statusRequested',
    'statusAwaitingApproval',
    'statusDenied',
    'statusTimedOut',
    'statusDuplicate',
    'statusSkipped',
    'statusActivated',
    'statusUnknown',
    'toolSourceBuiltIn',
    'toolSourceMcp',
    'toolSourceSkillScript',
    'toolRiskReadOnly',
    'toolRiskWrite',
    'toolRiskDestructive',
    'toolApprovalAllowOnce',
    'toolApprovalDenied',
    'reasoningCompleted',
    'reasoningInterrupted',
    'reasoningInProgress',
    'processInformation',
    'fileTypeSpeech',
    'fileTypeMusic',
    'fileTypeVideo',
    'thinkingInProgress',
    'thinkingCompleted',
    'thinkingCompletedWithDuration',
    'inputTokens',
    'outputTokens',
    'uploadImage',
    'uploadFile',
    'deepThinking',
    'replyCancelled',
  ];

  test('every supported locale defines all execution status messages', () {
    for (final fileName in localeFiles) {
      final file = File('lib/l10n/$fileName');
      expect(file.existsSync(), isTrue, reason: file.path);

      final messages =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final key in executionStatusKeys) {
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
}
