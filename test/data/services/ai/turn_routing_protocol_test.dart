import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/ai/turn_routing_protocol.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/turn_disposition.dart';

import '../../../support/foreground_turn_fixtures.dart';

void main() {
  TurnRoutingProtocol parser() =>
      TurnRoutingProtocol(allowedToolNames: {'read_file'});
  List<TurnRoutingEvent> decode(String value) {
    final protocol = parser();
    return [...protocol.add(value), ...protocol.finish()];
  }

  test('arbitrary chunk boundaries never expose text before a typed kind', () {
    final protocol = parser();
    final input = routeFrames('directReply', [
      {'text': '你好\n"quoted" 😀'},
    ]);
    final events = <TurnRoutingEvent>[];
    for (final rune in input.runes) {
      events.addAll(protocol.add(String.fromCharCode(rune)));
      if (events.whereType<DirectReplyDelta>().isNotEmpty) {
        expect(events.first, isA<TurnDispositionStarted>());
      }
    }
    expect(events.whereType<TurnDispositionCompleted>(), isEmpty);
    events.addAll(protocol.finish());
    expect(events.whereType<DirectReplyDelta>().single.text, '你好\n"quoted" 😀');
    expect(
      (events.last as TurnDispositionCompleted).disposition,
      isA<DirectReply>(),
    );
  });

  test('background kind and complete payload do not publish an acceptance', () {
    final protocol = parser();
    final initial = protocol.add(
      '${routeFrames('backgroundTaskPlan', [foregroundPlan()], done: false)}\n',
    );
    expect(initial, [isA<TurnDispositionStarted>()]);
    expect(protocol.add('{"done":true}\n'), isEmpty);
    final result = protocol.finish().single as TurnDispositionCompleted;
    final plan = result.disposition as BackgroundTaskPlan;
    expect(plan.steps.length, 2);
    expect(plan.allowedToolNames, {'read_file'});
  });

  test('empty direct response is a typed empty terminal, never a task', () {
    final result =
        decode(routeFrames('directReply', [])).last as TurnDispositionCompleted;
    expect(
      (result.disposition as DirectReply).outcome,
      MessageTerminalOutcome.emptyResponse,
    );
  });

  test('status uses nullable explicit task identity', () {
    for (final id in [null, 'task-1']) {
      final event =
          decode(
                routeFrames('taskStatusRequest', [
                  {'taskId': id},
                ]),
              ).last
              as TurnDispositionCompleted;
      expect((event.disposition as TaskStatusRequest).taskId, id);
    }
  });

  final malformed = <String, String>{
    'invalid JSON': 'not JSON',
    'unknown kind': '{"kind":"unknown"}\n{"text":"secret draft"}',
    'text before kind': '{"text":"secret draft"}\n{"kind":"directReply"}',
    'switched kind': '{"kind":"directReply"}\n{"kind":"backgroundTaskPlan"}',
    'duplicate kind': '{"kind":"directReply","kind":"backgroundTaskPlan"}',
    'escaped duplicate':
        r'{"kind":"directReply","ki\u006ed":"backgroundTaskPlan"}',
    'duplicate text':
        '{"kind":"directReply"}\n{"text":"a","text":"b"}\n{"done":true}',
    'no done': routeFrames('directReply', [
      {'text': 'partial'},
    ], done: false),
    'trailing content':
        '${routeFrames('directReply', [
          {'text': 'answer'},
        ])}\n{"text":"more"}',
    'unknown field': routeFrames('directReply', [
      {'text': 'answer', 'trust': 'verified'},
    ]),
    'incorrect type': routeFrames('directReply', [
      {'text': 23},
    ]),
    'no task payload': routeFrames('backgroundTaskPlan', []),
    'no status payload': routeFrames('taskStatusRequest', []),
    'empty task ID': routeFrames('taskStatusRequest', [
      {'taskId': ''},
    ]),
    'repeated plan': routeFrames('backgroundTaskPlan', [
      foregroundPlan(),
      foregroundPlan(),
    ]),
    'nested depth': '{"kind":${'[' * 9}0${']' * 9}}',
  };
  for (final entry in malformed.entries) {
    test('rejects ${entry.key}', () {
      expect(() => decode(entry.value), throwsFormatException);
    });
  }

  final badPlans = <String, Map<String, Object?>>{
    'unauthorized tool': {
      ...foregroundPlan(),
      'allowedToolNames': ['shell'],
    },
    'duplicate tools': {
      ...foregroundPlan(),
      'allowedToolNames': ['read_file', 'read_file'],
    },
    'empty title': {...foregroundPlan(), 'title': ''},
    'oversized title': {...foregroundPlan(), 'title': 'x' * 201},
    'oversized objective': {...foregroundPlan(), 'objective': 'x' * 16001},
    'oversized ack': {...foregroundPlan(), 'acknowledgementDraft': 'x' * 2001},
    'missing objective': {...foregroundPlan()}..remove('objective'),
    'extra arguments': {
      ...foregroundPlan(),
      'arguments': {'path': '/secret'},
    },
    'empty steps': {...foregroundPlan(), 'steps': []},
    'too many steps': {
      ...foregroundPlan(),
      'steps': List.generate(33, (i) => {'stepId': '$i', 'summary': 'step'}),
    },
    'duplicate step': {
      ...foregroundPlan(),
      'steps': [
        {'stepId': 's', 'summary': 'a'},
        {'stepId': 's', 'summary': 'b'},
      ],
    },
    'fake completed step': {
      ...foregroundPlan(),
      'steps': [
        {'stepId': 's', 'summary': 'a', 'status': 'completed'},
      ],
    },
    'blank step': {
      ...foregroundPlan(),
      'steps': [
        {'stepId': 's', 'summary': ' '},
      ],
    },
  };
  for (final entry in badPlans.entries) {
    test('rejects task with ${entry.key}', () {
      expect(
        () => decode(routeFrames('backgroundTaskPlan', [entry.value])),
        throwsFormatException,
      );
    });
  }

  test('bounded across multiple text frames and response chunks', () {
    expect(
      () => decode(
        routeFrames('directReply', [
          {'text': 'x' * 64001},
          {'text': 'x' * 64000},
        ]),
      ),
      throwsFormatException,
    );
    expect(
      () => parser().add(' ' * (TurnRoutingProtocol.maxResponseLength + 1)),
      throwsFormatException,
    );
  });

  test(
    'duplicate keys inside a plan are rejected, quoted key text is allowed',
    () {
      final plan = jsonEncode(
        foregroundPlan(),
      ).replaceFirst('"title":', '"title":"old","title":');
      expect(
        () => decode('{"kind":"backgroundTaskPlan"}\n$plan\n{"done":true}'),
        throwsFormatException,
      );
      final text = 'explain {"kind":"directReply","kind":"status"}';
      expect(
        decode(
          routeFrames('directReply', [
            {'text': text},
          ]),
        ).whereType<DirectReplyDelta>().single.text,
        text,
      );
    },
  );
}
