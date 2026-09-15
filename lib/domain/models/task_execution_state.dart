import 'dart:convert';

import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/tool.dart';

/// Portable continuation data. Tool arguments must be credential-free; adapters
/// resolve credentials through their own configuration, never through this JSON.
final class TaskPendingCall {
  TaskPendingCall({
    required ToolCallRequest call,
    required this.idempotencyKey,
    required this.toolVersion,
    this.attemptId,
    this.retryCount = 0,
    this.reconcileRequired = false,
  }) : call = ToolCallRequest(
         callId: call.callId,
         name: call.name,
         arguments: _freezeArguments(call.arguments),
       ) {
    for (final id in [
      call.callId,
      call.name,
      idempotencyKey,
      toolVersion,
      if (attemptId != null) attemptId!,
    ]) {
      if (id.isEmpty || id.trim() != id || id.length > 256) {
        throw ArgumentError('Invalid task call identity.');
      }
    }
    if (retryCount < 0 || (reconcileRequired && attemptId == null)) {
      throw ArgumentError('Invalid task retry state.');
    }
  }

  final ToolCallRequest call;
  final String idempotencyKey;
  final String toolVersion;
  final String? attemptId;
  final int retryCount;
  final bool reconcileRequired;

  TaskPendingCall withAttempt(
    String? id, {
    int? retries,
    bool reconcile = false,
  }) => TaskPendingCall(
    call: call,
    idempotencyKey: idempotencyKey,
    toolVersion: toolVersion,
    attemptId: id,
    retryCount: retries ?? retryCount,
    reconcileRequired: reconcile,
  );

  Map<String, Object?> toJson() => {
    'callId': call.callId,
    'name': call.name,
    'arguments': call.arguments,
    'idempotencyKey': idempotencyKey,
    'toolVersion': toolVersion,
    'attemptId': attemptId,
    'retryCount': retryCount,
    'reconcileRequired': reconcileRequired,
  };

  factory TaskPendingCall.fromJson(Map<String, Object?> json) {
    _only(json, {
      'callId',
      'name',
      'arguments',
      'idempotencyKey',
      'toolVersion',
      'attemptId',
      'retryCount',
      'reconcileRequired',
    });
    return TaskPendingCall(
      call: ToolCallRequest(
        callId: json['callId']! as String,
        name: json['name']! as String,
        arguments: Map<String, Object?>.from(json['arguments']! as Map),
      ),
      idempotencyKey: json['idempotencyKey']! as String,
      toolVersion: json['toolVersion']! as String,
      attemptId: json['attemptId'] as String?,
      retryCount: json['retryCount']! as int,
      reconcileRequired: json['reconcileRequired']! as bool,
    );
  }
}

/// No Provider session, reasoning, raw observation or credential belongs here.
final class TaskExecutionState {
  TaskExecutionState({
    List<TaskPendingCall> calls = const [],
    this.stepStarted = false,
    this.replanRequired = false,
    this.consecutiveFailures = 0,
    this.backoffCount = 0,
    this.candidate,
    this.finalizationReason,
    this.sideEffectsUnknown = false,
    this.segmentStartDigest = '',
  }) : calls = List.unmodifiable(calls) {
    if (calls.length > 4096 ||
        consecutiveFailures < 0 ||
        backoffCount < 0 ||
        calls.any((call) => call.retryCount < 0)) {
      throw ArgumentError('Invalid task continuation.');
    }
  }

  final List<TaskPendingCall> calls;
  final bool stepStarted;
  final bool replanRequired;
  final int consecutiveFailures;
  final int backoffCount;
  final GroundedAnswerCandidate? candidate;
  final String? finalizationReason;
  final bool sideEffectsUnknown;
  final String segmentStartDigest;

  Map<String, Object?> toJson() => {
    'calls': calls.map((call) => call.toJson()).toList(),
    'stepStarted': stepStarted,
    'replanRequired': replanRequired,
    'consecutiveFailures': consecutiveFailures,
    'backoffCount': backoffCount,
    'candidate': candidate?.toJson(),
    'finalizationReason': finalizationReason,
    'sideEffectsUnknown': sideEffectsUnknown,
    'segmentStartDigest': segmentStartDigest,
  };

  factory TaskExecutionState.fromJson(Map<String, Object?> json) {
    _only(json, {
      'calls',
      'stepStarted',
      'replanRequired',
      'consecutiveFailures',
      'backoffCount',
      'candidate',
      'finalizationReason',
      'sideEffectsUnknown',
      'segmentStartDigest',
    });
    final candidate = json['candidate'];
    final candidateMap =
        candidate == null ? null : Map<String, Object?>.from(candidate as Map);
    return TaskExecutionState(
      calls:
          (json['calls']! as List)
              .map(
                (call) => TaskPendingCall.fromJson(
                  Map<String, Object?>.from(call as Map),
                ),
              )
              .toList(),
      stepStarted: json['stepStarted']! as bool,
      replanRequired: json['replanRequired']! as bool,
      consecutiveFailures: json['consecutiveFailures']! as int,
      backoffCount: json['backoffCount']! as int,
      candidate:
          candidateMap == null
              ? null
              : GroundedAnswerCandidate.parseJson(
                jsonEncode(candidateMap),
                allowedEvidenceIds: {
                  for (final claim in candidateMap['claims']! as List)
                    ...List<String>.from(
                      (claim as Map)['evidence_ids']! as List,
                    ),
                },
              ),
      finalizationReason: json['finalizationReason'] as String?,
      sideEffectsUnknown: json['sideEffectsUnknown']! as bool,
      segmentStartDigest: json['segmentStartDigest']! as String,
    );
  }
}

Map<String, Object?> _freezeArguments(Map<String, Object?> arguments) {
  final encoded = jsonEncode(arguments);
  if (encoded.length > 64000) {
    throw ArgumentError('Task arguments are too large.');
  }
  return _freeze(jsonDecode(encoded))! as Map<String, Object?>;
}

Object? _freeze(Object? value) => switch (value) {
  final Map<String, Object?> map => Map<String, Object?>.unmodifiable(
    map.map((k, v) => MapEntry(k, _freeze(v))),
  ),
  final List<Object?> list => List<Object?>.unmodifiable(list.map(_freeze)),
  _ => value,
};

void _only(Map<String, Object?> json, Set<String> fields) {
  if (json.length != fields.length || !fields.containsAll(json.keys)) {
    throw const FormatException('Invalid task continuation fields.');
  }
}
