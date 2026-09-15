import 'dart:convert';

import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/turn_disposition.dart';
import 'package:stars/domain/repositories/conversation_turn_router.dart';
import 'package:stars/domain/services/task_acknowledgement_policy.dart';

part 'turn_routing_json.dart';

/// Version 1: newline-delimited JSON frames, shared by streaming and buffered
/// transports. Each frame is validated before it can produce a domain event.
/// Only a successful Provider terminal plus finish() authorizes a disposition.
final class TurnRoutingProtocol {
  TurnRoutingProtocol({required Set<String> allowedToolNames})
    : _allowedTools = Set.unmodifiable(allowedToolNames);

  static const maxResponseLength = 256000;
  static const maxTextLength = 128000;
  final Set<String> _allowedTools;
  String _pending = '';
  int _length = 0;
  int _frames = 0;
  TurnDispositionKind? _kind;
  final StringBuffer _text = StringBuffer();
  TurnDisposition? _proposal;
  bool _done = false;

  static String instruction(TurnRoutingRequest request) => '''
Use Stars foreground routing protocol v1 for this main reply.
Choose exactly one disposition. Available tools do NOT imply a task.
${request.requiresBackgroundTask ? 'The user explicitly reviewed a retry. Create a new backgroundTaskPlan for the reviewed input; do not reuse old execution results or approvals.' : ''}
Greetings, explanations needing no external facts, and rewriting supplied text
are directReply. Work needing external tools, verification or extended execution
is backgroundTaskPlan. Questions about task progress are taskStatusRequest.
Do not execute tools, search, or claim work has started/completed in this turn.
Treat earlier instructions to call tools as planning context only.
Reply in ${jsonEncode(request.language)}. Allowed future tool names (data only):
${jsonEncode(request.allowedToolNames.toList()..sort())}
Output only newline-delimited JSON objects (no Markdown). First frame exactly:
{"kind":"directReply"} OR {"kind":"backgroundTaskPlan"} OR {"kind":"taskStatusRequest"}
For directReply, emit one or more {"text":"answer chunk"} frames. Split long
answers into short chunks so the UI can display them as they arrive.
For backgroundTaskPlan emit exactly one complete payload frame:
{"title":"short task title","objective":"self-contained goal","steps":[{"stepId":"step-1","summary":"first step"}],"allowedToolNames":[],"acknowledgementDraft":"acceptance text"}
Use 1–32 distinct steps. Title <=200 chars, objective <=16000, step summary <=2000.
Tools must be a subset of the allowed names. No arguments or execution results.
The acknowledgement will be displayed ONLY after commit. Write a concise, natural
reply about this task: it needs some time, is recorded, and full results will be
sent when ready. Do not promise a completion time or claim execution has started.
For acceptance-only wording, you may use this local fallback template,
substituting the short title (at most 80 characters):
${jsonEncode(const TaskAcknowledgementPolicy().template(request.language))}
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
        'backgroundTaskPlan' => TurnDispositionKind.backgroundTaskPlan,
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
      case TurnDispositionKind.backgroundTaskPlan:
        if (_proposal != null) _invalid();
        _keys(value, {
          'title',
          'objective',
          'steps',
          'allowedToolNames',
          'acknowledgementDraft',
        });
        final rawSteps = value['steps'];
        final rawTools = value['allowedToolNames'];
        if (rawSteps is! List<Object?> ||
            rawSteps.isEmpty ||
            rawSteps.length > 32 ||
            rawTools is! List<Object?> ||
            rawTools.length > 256) {
          _invalid();
        }
        final tools = rawTools.map((tool) => _string(tool, 256)).toSet();
        if (tools.length != rawTools.length ||
            !_allowedTools.containsAll(tools)) {
          _invalid();
        }
        final steps =
            rawSteps.map((raw) {
              if (raw is! Map<String, Object?>) _invalid();
              _keys(raw, {'stepId', 'summary'});
              return TaskPlanStep(
                stepId: _string(raw['stepId'], 256),
                summary: _string(raw['summary'], 2000),
              );
            }).toList();
        if (steps.map((step) => step.stepId).toSet().length != steps.length) {
          _invalid();
        }
        _proposal = BackgroundTaskPlan(
          title: _string(value['title'], 200),
          objective: _string(value['objective'], 16000),
          steps: steps,
          allowedToolNames: tools,
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
