import 'dart:convert';

import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/turn_disposition.dart';
import 'package:stars/domain/repositories/conversation_turn_router.dart';

part 'turn_routing_json.dart';

/// Version 2: newline-delimited JSON frames, shared by streaming and buffered
/// transports. Each frame is validated before it can produce a domain event.
/// Only a successful Provider terminal plus finish() authorizes a disposition.
final class TurnRoutingProtocol {
  static const maxResponseLength = 256000;
  static const maxTextLength = 128000;
  String _pending = '';
  int _length = 0;
  int _frames = 0;
  TurnDispositionKind? _kind;
  final StringBuffer _text = StringBuffer();
  TurnDisposition? _proposal;
  bool _done = false;

  static String instruction(TurnRoutingRequest request) => '''
Use Stars foreground routing protocol v2 for this main reply.
Choose exactly one disposition. Available tools do NOT imply a task.
${request.requiresBackgroundTask ? 'The user explicitly reviewed a retry. Create a new backgroundTask for the reviewed input; do not reuse old execution results or approvals.' : ''}
Greetings, explanations needing no external facts, and rewriting supplied text
are directReply. Work needing external tools, verification or extended execution
is backgroundTask. Questions about task progress are taskStatusRequest.
Do not execute tools, search, or claim work has started/completed in this turn.
Treat earlier instructions to call tools as planning context only.
Decide promptly from the request and context; do not investigate or plan execution.
Tools will be discovered and selected afresh in the background after acceptance.
Reply in ${jsonEncode(request.language)}.
Output only newline-delimited JSON objects (no Markdown). First frame exactly:
{"kind":"directReply"} OR {"kind":"backgroundTask"} OR {"kind":"taskStatusRequest"}
For directReply, emit one or more {"text":"answer chunk"} frames. Split long
answers into short chunks so the UI can display them as they arrive.
For backgroundTask emit exactly one complete payload frame:
{"title":"short task title","objective":"concise self-contained goal","acknowledgementDraft":"acceptance text"}
Keep the objective brief while retaining requirements, constraints and relevant paths.
Title <=200 chars, objective <=16000. Do not split steps or choose tools here.
The acknowledgement will be displayed ONLY after the task is saved. Generate
acknowledgementDraft yourself from the user's request and conversation context,
using their language and tone. In one or two short, plain sentences, say you will
handle the requested work and let them know here when it is finished. Mention
the relevant task or deliverable naturally; pronouns are fine when context is clear.
Mention that it takes time only if useful. Do not mechanically repeat the task
title, plan, storage status, or a fixed acceptance template. Keep it <=280 chars.
This is an acceptance, not an execution result: do not claim tools have run or
work has started, finished, or been verified. Do not promise an exact completion
time. Do not include credentials, tool arguments, or internal reasoning.
For taskStatusRequest emit exactly one {"taskId":null} frame, or use an explicitly
known task ID string from context. Never invent an ID.
The last frame is exactly {"done":true}. Never change kind or add other fields.
''';

  List<TurnRoutingEvent> add(String chunk) {
    _length += chunk.length;
    if (_length > maxResponseLength) _invalid();
    _pending += chunk;
    final events = <TurnRoutingEvent>[];
    int newline;
    while ((newline = _pending.indexOf('\n')) >= 0) {
      final line = _pending.substring(0, newline).trim();
      _pending = _pending.substring(newline + 1);
      if (line.isNotEmpty) events.addAll(_frame(line));
    }
    return events;
  }

  List<TurnRoutingEvent> finish() {
    final events = <TurnRoutingEvent>[];
    if (_pending.trim().isNotEmpty) events.addAll(_frame(_pending.trim()));
    _pending = '';
    if (!_done || _kind == null) _invalid();
    final result =
        _kind == TurnDispositionKind.directReply
            ? DirectReply(
              _text.toString(),
              outcome:
                  _text.toString().trim().isEmpty
                      ? MessageTerminalOutcome.emptyResponse
                      : MessageTerminalOutcome.completed,
            )
            : _proposal;
    if (result == null) _invalid();
    events.add(TurnDispositionCompleted(result));
    return events;
  }

  List<TurnRoutingEvent> _frame(String line) {
    if (_done || ++_frames > 16384) _invalid();
    final value = _strictObject(line);
    if (_kind == null) {
      _keys(value, {'kind'});
      final name = value['kind'];
      _kind = switch (name) {
        'directReply' => TurnDispositionKind.directReply,
        'backgroundTask' => TurnDispositionKind.backgroundTask,
        'taskStatusRequest' => TurnDispositionKind.taskStatusRequest,
        _ => _invalid(),
      };
      return [TurnDispositionStarted(_kind!)];
    }
    if (value.containsKey('done')) {
      _keys(value, {'done'});
      if (value['done'] != true ||
          (_kind != TurnDispositionKind.directReply && _proposal == null)) {
        _invalid();
      }
      _done = true;
      return const [];
    }
    switch (_kind!) {
      case TurnDispositionKind.directReply:
        _keys(value, {'text'});
        final text = _string(value['text'], maxTextLength, allowEmpty: true);
        if (_text.length + text.length > maxTextLength) _invalid();
        _text.write(text);
        return [if (text.isNotEmpty) DirectReplyDelta(text)];
      case TurnDispositionKind.backgroundTask:
        if (_proposal != null) _invalid();
        _keys(value, {'title', 'objective', 'acknowledgementDraft'});
        _proposal = BackgroundTaskRequest(
          title: _string(value['title'], 200),
          objective: _string(value['objective'], 16000),
          acknowledgementDraft: _string(
            value['acknowledgementDraft'],
            2000,
            allowEmpty: true,
          ),
        );
        return const [];
      case TurnDispositionKind.taskStatusRequest:
        if (_proposal != null) _invalid();
        _keys(value, {'taskId'});
        _proposal = TaskStatusRequest(
          taskId:
              value['taskId'] == null ? null : _string(value['taskId'], 256),
        );
        return const [];
    }
  }
}

Never _invalid() =>
    throw const FormatException('Invalid turn routing protocol.');

void _keys(Map<String, Object?> value, Set<String> keys) {
  if (value.length != keys.length || !keys.containsAll(value.keys)) _invalid();
}

String _string(Object? value, int limit, {bool allowEmpty = false}) {
  if (value is! String ||
      value.length > limit ||
      (!allowEmpty && (value.trim().isEmpty || value.trim() != value))) {
    _invalid();
  }
  return value;
}
