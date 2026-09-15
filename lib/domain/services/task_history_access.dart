import 'package:stars/domain/models/conversation_history.dart';
import 'package:stars/domain/models/tool.dart';

/// Rebuilds history access from committed tool-generated envelope metadata.
/// Pending model arguments and quoted conversation text grant no access.
final class TaskHistoryAccess {
  TaskHistoryAccess.fromAttempts(
    Iterable<ToolExecutionRecord> attempts, {
    required String chatId,
    required String turnId,
  }) {
    for (final attempt in attempts) {
      if (attempt.chatId != chatId ||
          attempt.turnId != turnId ||
          attempt.source != ToolSource.builtIn ||
          attempt.status != ToolInvocationStatus.succeeded ||
          !{
            searchConversationHistoryToolName,
            readConversationHistoryToolName,
          }.contains(attempt.name) ||
          !attempt.resultSummary.startsWith(
            '<conversation_history_result version="1" scope="current_chat">',
          )) {
        continue;
      }
      for (final match in RegExp(
        r'<(?:hit|message) turn_id="([^"]*)" message_id="([^"]*)"',
      ).allMatches(attempt.resultSummary)) {
        if (match[1]!.isNotEmpty) {
          _references.add('turn:${_unescape(match[1]!)}');
        }
        if (match[2]!.isNotEmpty) {
          _references.add('message:${_unescape(match[2]!)}');
        }
      }
      for (final match in RegExp(
        r'<next_cursor>([^<]+)</next_cursor>',
      ).allMatches(attempt.resultSummary)) {
        _cursors.add(_unescape(match[1]!));
      }
    }
  }
  final _references = <String>{}, _cursors = <String>{};
  Set<String> get references => Set.unmodifiable(_references);
  Set<String> get cursors => Set.unmodifiable(_cursors);
}

String _unescape(String value) => value
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');
