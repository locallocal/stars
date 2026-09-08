import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/utils/theme.dart';

const double _modelControlWidth = 44;
const double _modelTurnLimitControlWidth = 72;

typedef MaxModelTurnsChanged = Future<void> Function(int maxModelTurns);

/// Conversation-scoped model options shown in the bot-information inspector.
final class ConversationModelControls extends StatefulWidget {
  const ConversationModelControls({
    super.key,
    required this.provider,
    this.maxModelTurns = ConversationMemoryState.defaultMaxModelTurns,
    this.maxModelTurnsEnabled = true,
    this.onMaxModelTurnsChanged,
  });

  final AiProvider provider;
  final int maxModelTurns;
  final bool maxModelTurnsEnabled;
  final MaxModelTurnsChanged? onMaxModelTurnsChanged;

  @override
  State<ConversationModelControls> createState() =>
      _ConversationModelControlsState();
}

final class _ConversationModelControlsState
    extends State<ConversationModelControls> {
  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return Column(
      key: const ValueKey<String>('conversation-model-controls'),
      children: [
        if (provider.supportWebSearch())
          _ModelControlRow(
            key: const ValueKey<String>('conversation-web-search-row'),
            switchKey: const ValueKey<String>('conversation-web-search-toggle'),
            icon: LucideIcons.globe,
            label: S.of(context).webSearch,
            value: provider.getWebSearch(),
            onChanged: (value) {
              setState(() {
                provider.setWebSearch(value);
              });
            },
          ),
        if (provider.supportDeepThinking())
          _ModelControlRow(
            key: const ValueKey<String>('conversation-deep-thinking-row'),
            switchKey: const ValueKey<String>(
              'conversation-deep-thinking-toggle',
            ),
            icon: LucideIcons.brain,
            label: S.of(context).deepThinking,
            value: provider.getDeepThinking(),
            onChanged: (value) {
              setState(() {
                provider.setDeepThinking(value);
              });
            },
          ),
        _MaxModelTurnsRow(
          enabled:
              widget.maxModelTurnsEnabled &&
              widget.onMaxModelTurnsChanged != null,
          value: widget.maxModelTurns,
          onPressed: () => unawaited(_editMaxModelTurns(context)),
        ),
      ],
    );
  }

  Future<void> _editMaxModelTurns(BuildContext context) async {
    final onChanged = widget.onMaxModelTurnsChanged;
    if (onChanged == null) return;
    final value = await showChatShadDialog<int>(
      context: context,
      builder:
          (dialogContext) =>
              _MaxModelTurnsDialog(initialValue: widget.maxModelTurns),
    );
    if (value == null || !context.mounted) return;
    try {
      await onChanged(value);
      if (context.mounted) {
        showStarsNotice(context, S.of(context).maxToolRequestRoundsSaved);
      }
    } on Object catch (error) {
      if (context.mounted) {
        showStarsNotice(
          context,
          safeFailureMessage(context, error),
          tone: StarsNoticeTone.error,
        );
      }
    }
  }
}

final class _ModelControlRow extends StatelessWidget {
  const _ModelControlRow({
    super.key,
    required this.switchKey,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final toggle = ShadSwitch(
      key: switchKey,
      width: _modelControlWidth,
      value: value,
      onChanged: onChanged,
    );
    return MergeSemantics(
      child: StarsInspectorInfoRow(
        icon: icon,
        label: label,
        padding: const EdgeInsets.symmetric(vertical: 5),
        crossAxisAlignment: CrossAxisAlignment.center,
        trailingWidth: _modelControlWidth,
        trailing: toggle,
      ),
    );
  }
}

final class _MaxModelTurnsRow extends StatelessWidget {
  const _MaxModelTurnsRow({
    required this.enabled,
    required this.value,
    required this.onPressed,
  });

  final bool enabled;
  final int value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => StarsInspectorInfoRow(
    key: const ValueKey<String>('max-model-turns-row'),
    icon: LucideIcons.rotateCcw,
    label: S.of(context).maxToolRequestRounds,
    padding: const EdgeInsets.symmetric(vertical: 5),
    crossAxisAlignment: CrossAxisAlignment.center,
    trailingWidth: _modelTurnLimitControlWidth,
    trailing: ShadButton.outline(
      key: const ValueKey<String>('max-model-turns-edit'),
      size: ShadButtonSize.sm,
      width: _modelTurnLimitControlWidth,
      onPressed: enabled ? onPressed : null,
      child: Text('$value'),
    ),
  );
}

final class _MaxModelTurnsDialog extends StatefulWidget {
  const _MaxModelTurnsDialog({required this.initialValue});

  final int initialValue;

  @override
  State<_MaxModelTurnsDialog> createState() => _MaxModelTurnsDialogState();
}

final class _MaxModelTurnsDialogState extends State<_MaxModelTurnsDialog> {
  final _formKey = GlobalKey<ShadFormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialValue}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ShadDialog(
    key: const ValueKey<String>('max-model-turns-dialog'),
    title: Text(
      S.of(context).maxToolRequestRounds,
      style: StarsDesktopThemeSpec.pageTitleStyle(context),
    ),
    description: Text(S.of(context).maxToolRequestRoundsDescription),
    constraints: const BoxConstraints(maxWidth: 480),
    actions: [
      ShadButton.outline(
        key: const ValueKey<String>('max-model-turns-cancel'),
        onPressed: () => Navigator.pop(context),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      ShadButton(
        key: const ValueKey<String>('max-model-turns-save'),
        onPressed: _save,
        child: Text(S.of(context).save),
      ),
    ],
    child: Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ShadForm(
        key: _formKey,
        autovalidateMode: ShadAutovalidateMode.alwaysAfterFirstValidation,
        child: ShadInputFormField(
          key: const ValueKey<String>('max-model-turns-input'),
          id: 'maxModelTurns',
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSubmitted: (_) => _save(),
          validator: _validate,
        ),
      ),
    ),
  );

  String? _validate(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null &&
        ConversationMemoryState.isValidMaxModelTurns(parsed)) {
      return null;
    }
    return S.of(context).maxToolRequestRoundsRange;
  }

  void _save() {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    Navigator.pop(context, int.parse(_controller.text.trim()));
  }
}
