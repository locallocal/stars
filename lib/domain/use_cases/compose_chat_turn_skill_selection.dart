part of 'compose_chat_turn.dart';

const _backgroundSkillSelectionInstruction = '''
<background_skill_selection>
The foreground decision is complete and the background task is already saved.
Your only job in this request is to select and activate Skills for its accepted
objective. Do not answer the user, draft the deliverable, plan execution steps,
or perform the task yet.

Use the current available_skills catalog to discover capabilities afresh.
Business tools are intentionally absent during Skill selection: activate_skill
loads the relevant instructions and makes their tools available for the next
planning request. Their absence now does not mean they are unavailable.
Select every relevant Skill needed to perform AND verify the objective, including
changes to external state when requested. Never rely on historical assistant
claims about which tools exist. The application still enforces tool policy and
approval independently.

Call activate_skill for the Skills you select, and read_skill_resource for any
needed references. After successful activation, call finish_skill_selection
with exactly the names of all activated Skills and a short reason describing
how they cover the objective. An empty list is valid only when no catalog Skill
is relevant, not because business tools have not yet been exposed.
Ordinary prose does not finish this stage.
</background_skill_selection>
''';

bool _skillSelectionFinished(SkillToolTurn turn, _TurnSkillState state) {
  final completions = turn.calls.where(
    (call) => call.name == finishSkillSelectionToolName,
  );
  if (completions.isEmpty) return false;
  if (turn.calls.length != 1) {
    throw const SkillSelectionIncompleteException();
  }
  final arguments = completions.single.arguments;
  final selected = arguments['selectedSkills'];
  final reason = arguments['reason'];
  final activated = {
    for (final entry in state.contents.values) entry.content.descriptor.name,
  };
  if (arguments.length != 2 ||
      selected is! List ||
      selected.any((name) => name is! String) ||
      selected.toSet().length != selected.length ||
      selected.length != activated.length ||
      !activated.containsAll(selected) ||
      reason is! String ||
      reason.trim().isEmpty ||
      reason.length > 1000 ||
      (activated.isEmpty && state.attempts.isNotEmpty)) {
    throw const SkillSelectionIncompleteException();
  }
  return true;
}
