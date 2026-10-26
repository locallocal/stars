import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/services/task_progress_strings.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';

Future<String?> showConversationTaskClosureDialog(BuildContext context) {
  final desktop = ShadTheme.maybeOf(context) != null;
  Widget builder(BuildContext context) => _TaskClosureDialog(desktop: desktop);
  return desktop
      ? showChatShadDialog<String>(context: context, builder: builder)
      : showDialog<String>(context: context, builder: builder);
}

class _TaskClosureDialog extends StatefulWidget {
  const _TaskClosureDialog({required this.desktop});
  final bool desktop;
  @override
  State<_TaskClosureDialog> createState() => _TaskClosureDialogState();
}

class _TaskClosureDialogState extends State<_TaskClosureDialog> {
  final _note = TextEditingController();
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = TaskProgressStrings(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final content = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 460,
        maxHeight: MediaQuery.sizeOf(context).height * .55,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(words.unresolvedWarning),
            const SizedBox(height: 16),
            Text(words.reviewNote),
            const SizedBox(height: 8),
            Semantics(
              label: words.reviewNote,
              child:
                  widget.desktop
                      ? ShadInput(
                        controller: _note,
                        maxLines: 4,
                        maxLength: 1000,
                        onChanged: (_) => setState(() {}),
                      )
                      : TextField(
                        controller: _note,
                        maxLines: 4,
                        maxLength: 1000,
                        onChanged: (_) => setState(() {}),
                      ),
            ),
          ],
        ),
      ),
    );
    final submit =
        _note.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, _note.text.trim());
    return widget.desktop
        ? ShadDialog(
          title: Text(words.closeUnresolved),
          actions: [
            ShadButton.outline(
              onPressed: () => Navigator.pop(context),
              child: Text(words.dismiss),
            ),
            ShadButton.destructive(
              onPressed: submit,
              child: Text(words.closeUnresolved),
            ),
          ],
          child: content,
        )
        : AlertDialog(
          title: Text(words.closeUnresolved),
          content: content,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(words.dismiss),
            ),
            FilledButton(onPressed: submit, child: Text(words.closeUnresolved)),
          ],
        );
  }
}
