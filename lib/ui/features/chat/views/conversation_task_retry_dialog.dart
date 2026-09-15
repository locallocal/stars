import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/services/task_progress_strings.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';

Future<String?> showConversationTaskRetryDialog(
  BuildContext context, {
  required String input,
  required String policyDescription,
}) {
  final desktop = ShadTheme.maybeOf(context) != null;
  Widget builder(BuildContext context) => _TaskRetryDialog(
    input: input,
    policyDescription: policyDescription,
    desktop: desktop,
  );
  return desktop
      ? showChatShadDialog<String>(context: context, builder: builder)
      : showDialog<String>(context: context, builder: builder);
}

class _TaskRetryDialog extends StatefulWidget {
  const _TaskRetryDialog({
    required this.input,
    required this.policyDescription,
    required this.desktop,
  });
  final String input, policyDescription;
  final bool desktop;
  @override
  State<_TaskRetryDialog> createState() => _TaskRetryDialogState();
}

class _TaskRetryDialogState extends State<_TaskRetryDialog> {
  late final controller = TextEditingController(text: widget.input);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = TaskProgressStrings(
      Localizations.localeOf(context).toLanguageTag(),
    );
    void submit() {
      if (controller.text.trim().isNotEmpty) {
        Navigator.pop(context, controller.text);
      }
    }

    final content = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 460,
        maxHeight: MediaQuery.sizeOf(context).height * .55,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${w.retryConfirmation}\n\n${widget.policyDescription}'),
            const SizedBox(height: 12),
            widget.desktop
                ? ShadInput(
                  controller: controller,
                  maxLines: 5,
                  placeholder: Text(w.pick('Task input', '任务输入')),
                )
                : TextField(
                  controller: controller,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: w.pick('Task input', '任务输入'),
                  ),
                ),
          ],
        ),
      ),
    );
    return widget.desktop
        ? ShadDialog(
          title: Text(w.retry),
          actions: [
            ShadButton.outline(
              onPressed: () => Navigator.pop(context),
              child: Text(w.dismiss),
            ),
            ShadButton(onPressed: submit, child: Text(w.retrySend)),
          ],
          child: content,
        )
        : AlertDialog(
          title: Text(w.retry),
          content: content,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(w.dismiss),
            ),
            FilledButton(onPressed: submit, child: Text(w.retrySend)),
          ],
        );
  }
}
