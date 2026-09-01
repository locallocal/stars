import 'dart:io';

typedef StarsSystemPromptProvider = String Function();
typedef StarsSystemPromptEnabledProvider = Future<bool> Function();

Future<bool> starsSystemPromptEnabledByDefault() async => true;

/// Builds the application context that precedes every model-facing system
/// prompt.
String currentStarsSystemPrompt() => buildStarsSystemPrompt(
  operatingSystem: Platform.operatingSystem,
  operatingSystemVersion: Platform.operatingSystemVersion,
);

String buildStarsSystemPrompt({
  required String operatingSystem,
  required String operatingSystemVersion,
}) {
  final normalizedOperatingSystem = _valueOrUnknown(operatingSystem);
  final normalizedVersion = _valueOrUnknown(operatingSystemVersion);
  return '''
<stars_application_context>
Application: Stars
Description: Stars is a cross-platform AI chat client for configurable assistants, Skills, MCP tools, and locally stored conversations.
Operating system type: ${_xmlText(normalizedOperatingSystem)}
Operating system version: ${_xmlText(normalizedVersion)}
</stars_application_context>

<stars_reliability_policy>
Treat conversation Memory and rolling summaries as potentially stale clues, not
as evidence. For exact historical claims, use the available history tools. For
claims about files, external state, current information, or completed actions,
rely only on successful results from the current run. An error, empty result,
or truncated result never proves success. Clearly distinguish observed facts,
inferences, and unknowns; do not invent facts, citations, tool results, or
completed actions.

When at least one structured tool was called in the current run, finish the
final answer with exactly one machine-readable footer and no text after it:
<stars_evidence call_ids="call-id-1,call-id-2" />
List only successful, non-empty, non-truncated tool calls that actually support
the answer. If no tool produced usable evidence, use an empty call_ids value and
state that the result could not be verified. Stars validates and removes this
footer before displaying the answer.
</stars_reliability_policy>''';
}

/// Builds the runtime time, identity, and storage context for one turn.
///
/// Keeping identifiers and the application-owned artifacts directory in a
/// dedicated section prevents them from being confused with editable agent
/// instructions.
String buildStarsConversationContext({
  required String agentId,
  required String agentName,
  required String conversationId,
  String artifactsDirectoryPath = '',
  DateTime? currentTime,
}) {
  final effectiveCurrentTime = currentTime ?? DateTime.now();
  final normalizedArtifactsDirectory = artifactsDirectoryPath.trim();
  final artifactsContext =
      normalizedArtifactsDirectory.isEmpty
          ? ''
          : '''
Conversation artifacts directory: ${_xmlText(normalizedArtifactsDirectory)}
Use this directory to store and access files produced or needed by the current conversation.
'''.trim();
  return '''
<stars_conversation_context>
Purpose: Application-provided runtime identity for the current turn.
Current time: ${_iso8601WithOffset(effectiveCurrentTime)}
Agent ID: ${_xmlText(_valueOrUnknown(agentId))}
Agent name: ${_xmlText(_valueOrUnknown(agentName))}
Current conversation ID: ${_xmlText(_valueOrUnknown(conversationId))}
${artifactsContext.isEmpty ? '' : '$artifactsContext\n'}</stars_conversation_context>''';
}

String prependStarsSystemPrompt(
  String existingPrompt, {
  StarsSystemPromptProvider starsSystemPromptProvider =
      currentStarsSystemPrompt,
}) {
  final starsPrompt = starsSystemPromptProvider().trim();
  final normalizedExistingPrompt = existingPrompt.trim();
  if (starsPrompt.isEmpty) return normalizedExistingPrompt;
  if (normalizedExistingPrompt.isEmpty) return starsPrompt;
  return '$starsPrompt\n\n$normalizedExistingPrompt';
}

String _valueOrUnknown(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? 'unknown' : normalized;
}

String _iso8601WithOffset(DateTime value) {
  final timestamp =
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}T'
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}:'
      '${value.second.toString().padLeft(2, '0')}';
  if (value.isUtc) return '${timestamp}Z';

  final offsetMinutes = value.timeZoneOffset.inMinutes;
  final sign = offsetMinutes < 0 ? '-' : '+';
  final absoluteOffsetMinutes = offsetMinutes.abs();
  final offsetHours = (absoluteOffsetMinutes ~/ 60).toString().padLeft(2, '0');
  final offsetRemainder = (absoluteOffsetMinutes % 60).toString().padLeft(
    2,
    '0',
  );
  return '$timestamp$sign$offsetHours:$offsetRemainder';
}

String _xmlText(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
