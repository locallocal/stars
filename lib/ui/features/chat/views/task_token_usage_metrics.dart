import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/services/task_progress_strings.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/features/chat/views/execution_metric.dart';

final class TaskTokenUsageMetrics extends StatelessWidget {
  const TaskTokenUsageMetrics({super.key, required this.usage});
  final ModelTokenUsage? usage;

  @override
  Widget build(BuildContext context) {
    final words = TaskProgressStrings(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final strings = S.maybeOf(context);
    final content = Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        ExecutionMetric(
          icon: Icons.login_rounded,
          label:
              '${strings?.inputTokens ?? words.inputTokens} ${usage?.inputTokens ?? '—'}',
        ),
        ExecutionMetric(
          icon: Icons.logout_rounded,
          label:
              '${strings?.outputTokens ?? words.outputTokens} ${usage?.outputTokens ?? '—'}',
        ),
      ],
    );
    return ShadTheme.maybeOf(context) == null
        ? Tooltip(message: words.tokenUsageHint, child: content)
        : ShadTooltip(
          builder: (_) => Text(words.tokenUsageHint),
          child: content,
        );
  }
}
