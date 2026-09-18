part of 'conversation_task_record.dart';

abstract final class TaskAcceptanceRecord {
  static Map<String, Object?> encode(TaskAcceptanceSnapshot value) => {
    'providerId': value.providerId,
    'modelId': value.modelId,
    'configurationDigest': value.configurationDigest,
    'language': value.language,
    'context': value.context.map(_contextToJson).toList(),
    'allowedToolNames': value.allowedToolNames.toList(),
    // Preserve the original encoding for legacy tasks with no saved grants;
    // acceptance JSON is immutable in the database.
    if (value.approvalExemptToolNames.isNotEmpty)
      'approvalExemptToolNames': value.approvalExemptToolNames.toList(),
    'verification': {
      'reliabilityEnabled': value.verification.reliabilityEnabled,
      'strictGroundingEnabled': value.verification.strictGroundingEnabled,
      'showVerificationStatus': value.verification.showVerificationStatus,
      'policyVersion': value.verification.policyVersion,
    },
    'segmentLimits': TaskSegmentLimitsRecord.encode(value.segmentLimits),
  };

  static TaskAcceptanceSnapshot decode(Map<String, Object?> values) {
    final row = _TaskRow(values)..only({
      'providerId',
      'modelId',
      'configurationDigest',
      'language',
      'context',
      'allowedToolNames',
      if (values.containsKey('approvalExemptToolNames'))
        'approvalExemptToolNames',
      'verification',
      'segmentLimits',
    });
    final policy = _TaskRow(row.object('verification'))..only({
      'reliabilityEnabled',
      'strictGroundingEnabled',
      'showVerificationStatus',
      'policyVersion',
    });
    return TaskAcceptanceSnapshot(
      providerId: row.text('providerId'),
      modelId: row.text('modelId'),
      configurationDigest: row.text('configurationDigest'),
      language: row.text('language'),
      context: _contexts(row.require<List<Object?>>('context')),
      allowedToolNames: row.strings('allowedToolNames').toSet(),
      approvalExemptToolNames:
          values.containsKey('approvalExemptToolNames')
              ? row.strings('approvalExemptToolNames').toSet()
              : const {},
      verification: VerificationPolicySnapshot(
        reliabilityEnabled: policy.boolean('reliabilityEnabled'),
        strictGroundingEnabled: policy.boolean('strictGroundingEnabled'),
        showVerificationStatus: policy.boolean('showVerificationStatus'),
        policyVersion: policy.integer('policyVersion'),
      ),
      segmentLimits: TaskSegmentLimitsRecord.decode(
        row.object('segmentLimits'),
      ),
    );
  }
}

abstract final class TaskSegmentLimitsRecord {
  static Map<String, Object?> encode(TaskSegmentLimits value) => {
    'maxModelTurns': value.maxModelTurns,
    'maxToolCalls': value.maxToolCalls,
    'maxSameCallRetries': value.maxSameCallRetries,
    'maxConsecutiveToolFailures': value.maxConsecutiveToolFailures,
    'maxReliabilityRepairs': value.maxReliabilityRepairs,
    'maxPlanRevisions': value.maxPlanRevisions,
    'maxNoProgressSegments': value.maxNoProgressSegments,
    'providerTimeout': value.providerTimeout.inMicroseconds,
    'toolTimeout': value.toolTimeout.inMicroseconds,
    'pollTimeout': value.pollTimeout.inMicroseconds,
    'reconcileTimeout': value.reconcileTimeout.inMicroseconds,
    'initialBackoff': value.initialBackoff.inMicroseconds,
    'maxBackoff': value.maxBackoff.inMicroseconds,
  };

  static TaskSegmentLimits decode(Map<String, Object?> values) {
    final row = _TaskRow(values)..only({
      'maxModelTurns',
      'maxToolCalls',
      'maxSameCallRetries',
      'maxConsecutiveToolFailures',
      'maxReliabilityRepairs',
      'maxPlanRevisions',
      'maxNoProgressSegments',
      'providerTimeout',
      'toolTimeout',
      'pollTimeout',
      'reconcileTimeout',
      'initialBackoff',
      'maxBackoff',
    });
    return TaskSegmentLimits(
      maxModelTurns: row.integer('maxModelTurns'),
      maxToolCalls: row.integer('maxToolCalls'),
      maxSameCallRetries: row.integer('maxSameCallRetries'),
      maxConsecutiveToolFailures: row.integer('maxConsecutiveToolFailures'),
      maxReliabilityRepairs: row.integer('maxReliabilityRepairs'),
      maxPlanRevisions: row.integer('maxPlanRevisions'),
      maxNoProgressSegments: row.integer('maxNoProgressSegments'),
      providerTimeout: Duration(microseconds: row.integer('providerTimeout')),
      toolTimeout: Duration(microseconds: row.integer('toolTimeout')),
      pollTimeout: Duration(microseconds: row.integer('pollTimeout')),
      reconcileTimeout: Duration(microseconds: row.integer('reconcileTimeout')),
      initialBackoff: Duration(microseconds: row.integer('initialBackoff')),
      maxBackoff: Duration(microseconds: row.integer('maxBackoff')),
    );
  }
}

Map<String, Object?> _contextToJson(TaskContextMessage value) => {
  'role': value.role.name,
  'content': value.content,
  'assetReferences': value.assetReferences,
};

List<TaskContextMessage> _contexts(List<Object?> values) =>
    values.map((value) {
      if (value is! Map<String, Object?>) {
        throw const FormatException('Invalid context message.');
      }
      final row = _TaskRow(value)..only({'role', 'content', 'assetReferences'});
      return TaskContextMessage(
        role: row.enumeration('role', TaskContextRole.values),
        content: row.text('content'),
        assetReferences: row.strings('assetReferences'),
      );
    }).toList();

final class ConversationTaskPlanRecord {
  ConversationTaskPlanRecord(Map<String, Object?> values)
    : values = Map.unmodifiable(values);
  factory ConversationTaskPlanRecord.fromDomain(ConversationTaskPlan value) =>
      ConversationTaskPlanRecord({
        'task_id': value.taskId,
        'plan_revision': value.revision,
        'created_at': value.createdAt.microsecondsSinceEpoch,
        'plan_json': jsonEncode({
          'objective': value.objective,
          'allowedToolNames': value.allowedToolNames.toList(),
          'steps':
              value.steps
                  .map(
                    (step) => {
                      'stepId': step.stepId,
                      'summary': step.summary,
                      'status': step.status.name,
                    },
                  )
                  .toList(),
        }),
      });
  final Map<String, Object?> values;
  ConversationTaskPlan toDomain() {
    final row = _TaskRow(values),
        plan = _TaskRow(_TaskRow(values).json('plan_json'));
    return ConversationTaskPlan(
      taskId: row.text('task_id'),
      revision: row.integer('plan_revision'),
      objective: plan.text('objective'),
      allowedToolNames: plan.strings('allowedToolNames').toSet(),
      createdAt: row.time('created_at'),
      steps:
          plan.require<List<Object?>>('steps').map((value) {
            if (value is! Map<String, Object?>) {
              throw const FormatException('Invalid plan step.');
            }
            final step = _TaskRow(value);
            return TaskPlanStep(
              stepId: step.text('stepId'),
              summary: step.text('summary'),
              status: step.enumeration('status', TaskPlanStepStatus.values),
            );
          }).toList(),
    );
  }
}

final class ConversationTaskCheckpointRecord {
  ConversationTaskCheckpointRecord(Map<String, Object?> values)
    : values = Map.unmodifiable(values);
  factory ConversationTaskCheckpointRecord.fromDomain(
    ConversationTaskCheckpoint value,
  ) => ConversationTaskCheckpointRecord({
    'task_id': value.taskId,
    'plan_revision': value.planRevision,
    'segment_id': value.segmentId,
    'sequence': value.sequence,
    'saved_at': value.savedAt.microsecondsSinceEpoch,
    'checkpoint_json': jsonEncode({
      'phase': value.phase.name,
      'nextStepId': value.nextStepId,
      'evidenceCursor': value.evidenceCursor,
      'completedStepIds': value.completedStepIds,
      'pendingAttemptIds': value.pendingAttemptIds,
      'execution': value.execution?.toJson(),
      'context': value.context.map(_contextToJson).toList(),
      'externalJobs':
          value.externalJobs
              .map(
                (job) => {
                  'attemptId': job.attemptId,
                  'externalJobId': job.externalJobId,
                  'resumeHandle': job.resumeHandle,
                  'safeStatus': job.safeStatus,
                  'nextPollAt': job.nextPollAt.microsecondsSinceEpoch,
                },
              )
              .toList(),
    }),
  });
  final Map<String, Object?> values;
  ConversationTaskCheckpoint toDomain() {
    final row = _TaskRow(values),
        state = _TaskRow(_TaskRow(values).json('checkpoint_json'));
    state.only({
      'phase',
      'nextStepId',
      'evidenceCursor',
      'completedStepIds',
      'pendingAttemptIds',
      'execution',
      'context',
      'externalJobs',
    });
    return ConversationTaskCheckpoint(
      taskId: row.text('task_id'),
      planRevision: row.integer('plan_revision'),
      segmentId: row.text('segment_id'),
      sequence: row.integer('sequence'),
      savedAt: row.time('saved_at'),
      phase: state.enumeration('phase', ConversationTaskPhase.values),
      nextStepId: state.optionalText('nextStepId'),
      evidenceCursor: state.integer('evidenceCursor'),
      completedStepIds: state.strings('completedStepIds'),
      pendingAttemptIds: state.strings('pendingAttemptIds'),
      execution:
          state.values['execution'] == null
              ? null
              : TaskExecutionState.fromJson(
                Map<String, Object?>.from(state.values['execution']! as Map),
              ),
      context: _contexts(state.require<List<Object?>>('context')),
      externalJobs:
          state.require<List<Object?>>('externalJobs').map((value) {
            if (value is! Map<String, Object?>) {
              throw const FormatException('Invalid external job.');
            }
            final job = _TaskRow(value)..only({
              'attemptId',
              'externalJobId',
              'resumeHandle',
              'safeStatus',
              'nextPollAt',
            });
            return TaskExternalJob(
              attemptId: job.text('attemptId'),
              externalJobId: job.text('externalJobId'),
              resumeHandle: job.text('resumeHandle'),
              safeStatus: job.text('safeStatus'),
              nextPollAt: job.time('nextPollAt'),
            );
          }).toList(),
    );
  }
}
