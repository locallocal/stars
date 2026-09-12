import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/common.dart';

class RenameChatDialog extends StatefulWidget {
  const RenameChatDialog({
    super.key,
    required this.initialName,
    required this.onSave,
  });

  final String initialName;
  final Future<void> Function(String name) onSave;

  @override
  State<RenameChatDialog> createState() => _RenameChatDialogState();
}

class _RenameChatDialogState extends State<RenameChatDialog> {
  final GlobalKey<ShadFormState> _formKey = GlobalKey<ShadFormState>();
  late final TextEditingController _controller;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      key: const ValueKey<String>('rename-chat-dialog'),
      title: Text(S.of(context).renameConversation),
      description: Text(S.of(context).renameConversationDescription),
      constraints: const BoxConstraints(maxWidth: 480),
      actions: [
        ShadButton.outline(
          key: const ValueKey<String>('rename-chat-cancel'),
          enabled: !_isSaving,
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).cancel),
        ),
        ShadButton(
          key: const ValueKey<String>('rename-chat-save'),
          enabled: !_isSaving,
          onPressed: _save,
          leading:
              _isSaving
                  ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : null,
          child: Text(S.of(context).save),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShadForm(
              key: _formKey,
              autovalidateMode: ShadAutovalidateMode.alwaysAfterFirstValidation,
              child: ShadInputFormField(
                key: const ValueKey<String>('rename-chat-name-input'),
                id: 'conversationName',
                controller: _controller,
                autofocus: true,
                enabled: !_isSaving,
                label: Text(S.of(context).conversationName),
                placeholder: Text(S.of(context).conversationNamePlaceholder),
                leading: const Icon(LucideIcons.messageSquareText, size: 16),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(Chat.maxNameLength),
                ],
                onSubmitted: (_) => _save(),
                validator: (value) {
                  if (value.trim().isEmpty) {
                    return S.of(context).conversationNameRequired;
                  }
                  return null;
                },
              ),
            ),
            if (_errorMessage case final errorMessage?) ...[
              const SizedBox(height: 16),
              ShadAlert.destructive(
                icon: const Icon(LucideIcons.circleAlert),
                title: Text(S.of(context).unableToRenameConversation),
                description: Text(errorMessage),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.saveAndValidate() ?? false)) {
      return;
    }
    final name = _controller.text.trim();
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.onSave(name);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = safeFailureMessage(context, error);
      });
      return;
    }
    if (mounted) Navigator.pop(context, name);
  }
}
