import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/grounded_answer_validator.dart';
import 'package:stars/domain/services/task_evidence_scope.dart';
import 'package:stars/domain/services/task_terminal_summary_policy.dart';
import 'package:stars/domain/services/task_verification_preparation.dart';

import '../../support/task_terminal_harness.dart';

void main() {
  late TaskTerminalHarness h;
  setUp(() => h = TaskTerminalHarness());
  tearDown(() => h.close());

  test(
    'another task in the same conversation cannot borrow successful segment evidence',
    () async {
      await h.open();
      await h.observe();
      final original = await h.runner.snapshot;
      final other = taskFixture(id: 'other-task');
      final forgedScope = TaskExecutionSnapshot(
        task: other,
        plan: taskPlan(other),
        lastSequence: 1,
        attempts: original.attempts,
        attemptLinks: original.attemptLinks,
        evidence: original.evidence,
      );
      final candidate = taskPartialCandidate(original, [
        h.runner.tool.definition,
      ]);
      final validation = await GroundedAnswerValidator(
        evidenceRepository: h.evidence,
        scope: TaskEvidenceScope(forgedScope),
      ).validate(
        runId: other.taskId,
        candidate: candidate,
        requirements: taskVerificationRequirements(original, [
          h.runner.tool.definition,
        ]),
        validatedAt: h.runner.clock.now(),
      );
      expect(validation.evidenceIds, isEmpty);
      expect(
        validation.claims.single.issues.single.reason,
        EvidenceRejectionReason.evidenceRunMismatch,
      );
    },
  );

  for (final before in [false, true]) {
    test(
      'postcondition ${before ? 'rejects a read before the write' : 'accepts a read in a later segment'} even with equal timestamps',
      () async {
        await h.open(write: true, toolName: 'write_report');
        final writeTool = h.runner.tool;
        h.configureTool();
        final readTool = h.runner.tool;
        if (before) await h.observe();
        h.runner.tool = writeTool;
        await h.observe(call: 'write');
        h.runner.tool = readTool;
        if (!before) await h.observe(call: 'read-after');
        final snapshot = await h.runner.snapshot;
        final definitions = [writeTool.definition, readTool.definition];
        final requirements = taskVerificationRequirements(
          snapshot,
          definitions,
        );
        final state = requirements.singleWhere(
          (r) => r.claimId.endsWith(':state'),
        );
        final read = snapshot.evidence.singleWhere(
          (e) => e.evidenceKind == EvidenceKind.observation,
        );
        final receipt = snapshot.evidence.singleWhere(
          (e) => e.evidenceKind == EvidenceKind.actionReceipt,
        );
        expect(read.observedAt, receipt.observedAt);
        final validator = GroundedAnswerValidator(
          evidenceRepository: h.evidence,
          scope: TaskEvidenceScope(snapshot),
        );
        final result = await validator.validate(
          runId: 'task-1',
          candidate: GroundedAnswerCandidate(
            claims: [
              AnswerClaim(
                claimId: state.claimId,
                text: 'report.count: 42',
                kind: ClaimKind.currentFact,
                evidenceIds: [read.evidenceId, receipt.evidenceId],
              ),
            ],
          ),
          requirements: [state],
          validatedAt: h.runner.clock.now(),
        );
        expect(
          result.trustLevel,
          before ? AnswerTrustLevel.unverified : AnswerTrustLevel.verified,
        );
        expect(result.evidenceIds, before ? isEmpty : [read.evidenceId]);
        expect(result.evidenceIds, isNot(contains(receipt.evidenceId)));
      },
    );
  }

  test(
    'removed write tool does not remove its required postcondition',
    () async {
      await h.open(write: true);
      await h.observe();
      final requirements = taskVerificationRequirements(
        await h.runner.snapshot,
        [],
      );
      expect(requirements, hasLength(2));
      expect(requirements.last.verificationAvailable, isFalse);
      expect(requirements.last.allowedAttemptIds, isEmpty);
    },
  );

  test(
    'raw paths or sensitive values cannot enter partial terminal facts or artifact references',
    () async {
      await h.open();
      await h.observe();
      final snapshot = await h.runner.snapshot;
      final evidence = snapshot.evidence.single;
      final candidate = AnswerClaim(
        claimId: 'secret',
        text: '文件位于 /private/report.txt',
        kind: ClaimKind.currentFact,
        evidenceIds: [evidence.evidenceId],
      );
      final summary = const TaskTerminalSummaryPolicy().build(
        snapshot: snapshot,
        reasonCode: 'Bearer raw-secret',
        validation: GroundedAnswerValidationResult(
          trustLevel: AnswerTrustLevel.verified,
          reasonCode: 'all_claims_verified',
          claims: [
            ClaimValidationResult(
              claim: candidate,
              trustLevel: ClaimTrustLevel.verified,
              acceptedEvidenceIds: [evidence.evidenceId],
            ),
          ],
          evidenceIds: [evidence.evidenceId],
        ),
      );
      expect(summary.reasonCode, 'task_execution_failed');
      expect(summary.safeReason, isNot(contains('raw-secret')));
      expect(summary.completedWorkSummary, isEmpty);
      expect(summary.retainedArtifacts, isEmpty);
    },
  );
}
