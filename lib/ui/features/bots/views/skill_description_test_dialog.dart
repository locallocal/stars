import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/utils/theme.dart';

Future<SkillDescriptionTestCase?> showSkillDescriptionTestDialog({
  required BuildContext context,
  required SkillDescriptor skill,
  required bool desktopMode,
}) =>
    desktopMode
        ? showShadDialog<SkillDescriptionTestCase>(
          context: context,
          builder:
              (dialogContext) =>
                  _SkillDescriptionTestDialog(skill: skill, desktopMode: true),
        )
        : showDialog<SkillDescriptionTestCase>(
          context: context,
          builder:
              (dialogContext) =>
                  _SkillDescriptionTestDialog(skill: skill, desktopMode: false),
        );

class _SkillDescriptionTestDialog extends StatefulWidget {
  const _SkillDescriptionTestDialog({
    required this.skill,
    required this.desktopMode,
  });

  final SkillDescriptor skill;
  final bool desktopMode;

  @override
  State<_SkillDescriptionTestDialog> createState() =>
      _SkillDescriptionTestDialogState();
}

class _SkillDescriptionTestDialogState
    extends State<_SkillDescriptionTestDialog> {
  final _inputController = TextEditingController();
  var _shouldActivate = true;

  bool get _canRun => _inputController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    if (widget.desktopMode) {
      return ShadDialog(
        key: const ValueKey<String>('skill-description-test-dialog'),
        closeIcon: StarsDesktopIconAction(
          key: const ValueKey<String>('skill-description-test-close'),
          icon: LucideIcons.x,
          iconSize: 18,
          label: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.pop(context),
        ),
        closeIconPosition: ShadPosition.directional(
          top: 12,
          end: 8,
          textDirection: Directionality.of(context),
        ),
        title: Text(strings.testSkillDescription),
        description: Text(strings.autoActivationDescription),
        constraints: const BoxConstraints(maxWidth: 560),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('cancel-skill-description-test'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.cancel),
          ),
          ShadButton(
            key: const ValueKey<String>('run-skill-description-test'),
            enabled: _canRun,
            onPressed: _canRun ? _submit : null,
            leading: const Icon(LucideIcons.play, size: 15),
            child: Text(strings.runSkillDescriptionTest),
          ),
        ],
        child: _buildForm(),
      );
    }

    return AlertDialog(
      key: const ValueKey<String>('skill-description-test-dialog'),
      scrollable: true,
      title: Text(strings.testSkillDescription),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.autoActivationDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _buildForm(),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey<String>('cancel-skill-description-test'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton.icon(
          key: const ValueKey<String>('run-skill-description-test'),
          onPressed: _canRun ? _submit : null,
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: Text(strings.runSkillDescriptionTest),
        ),
      ],
    );
  }

  Widget _buildForm() => _SkillDescriptionTestForm(
    skill: widget.skill,
    inputController: _inputController,
    shouldActivate: _shouldActivate,
    desktopMode: widget.desktopMode,
    onInputChanged: (_) => setState(() {}),
    onShouldActivateChanged: (value) => setState(() => _shouldActivate = value),
  );

  void _submit() {
    Navigator.of(context).pop(
      SkillDescriptionTestCase(
        input: _inputController.text.trim(),
        shouldActivate: _shouldActivate,
      ),
    );
  }
}

class _SkillDescriptionTestForm extends StatelessWidget {
  const _SkillDescriptionTestForm({
    required this.skill,
    required this.inputController,
    required this.shouldActivate,
    required this.desktopMode,
    required this.onInputChanged,
    required this.onShouldActivateChanged,
  });

  final SkillDescriptor skill;
  final TextEditingController inputController;
  final bool shouldActivate;
  final bool desktopMode;
  final ValueChanged<String> onInputChanged;
  final ValueChanged<bool> onShouldActivateChanged;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSkillSummary(context),
          const SizedBox(height: 16),
          if (desktopMode) ...[
            Text(
              strings.skillDescriptionTestInput,
              style: ShadTheme.of(context).textTheme.small,
            ),
            const SizedBox(height: 6),
            ShadTextarea(
              key: const ValueKey<String>('skill-description-test-input'),
              controller: inputController,
              autofocus: true,
              minHeight: 104,
              maxHeight: 160,
              resizable: false,
              placeholder: Text(strings.skillDescriptionTestInput),
              leading: const Icon(LucideIcons.messageSquareText, size: 17),
              onChanged: onInputChanged,
            ),
          ] else
            TextField(
              key: const ValueKey<String>('skill-description-test-input'),
              controller: inputController,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              onChanged: onInputChanged,
              decoration: InputDecoration(
                labelText: strings.skillDescriptionTestInput,
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 58),
                  child: Icon(Icons.chat_bubble_outline_rounded, size: 20),
                ),
              ),
            ),
          const SizedBox(height: 14),
          _buildExpectation(context, strings),
        ],
      ),
    );
  }

  Widget _buildSkillSummary(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color:
                desktopMode
                    ? StarsDesktopThemeSpec.secondarySurface(context)
                    : Theme.of(context).colorScheme.secondaryContainer,
            borderRadius:
                desktopMode
                    ? StarsDesktopThemeSpec.itemRadius
                    : BorderRadius.circular(10),
          ),
          child: Icon(
            desktopMode ? LucideIcons.flaskConical : Icons.science_outlined,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                skill.name,
                style:
                    desktopMode
                        ? StarsDesktopThemeSpec.toolbarTitleStyle(context)
                        : Theme.of(context).textTheme.titleSmall,
              ),
              if (skill.description.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  skill.description.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style:
                      desktopMode
                          ? StarsDesktopThemeSpec.metaStyle(context)
                          : Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return Container(
      key: const ValueKey<String>('skill-description-test-summary'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            desktopMode
                ? StarsDesktopThemeSpec.raisedSurface(context)
                : Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(
          color:
              desktopMode
                  ? StarsDesktopThemeSpec.outline(context)
                  : Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius:
            desktopMode
                ? StarsDesktopThemeSpec.controlRadius
                : BorderRadius.circular(10),
      ),
      child: content,
    );
  }

  Widget _buildExpectation(BuildContext context, S strings) {
    final label = Text(
      strings.skillDescriptionShouldActivate,
      style:
          desktopMode
              ? StarsDesktopThemeSpec.bodyStyle(context)
              : Theme.of(context).textTheme.bodyMedium,
    );
    return Container(
      key: const ValueKey<String>('skill-description-test-expectation'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            desktopMode
                ? StarsDesktopThemeSpec.secondarySurface(context)
                : Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withValues(alpha: 0.45),
        border: Border.all(
          color:
              desktopMode
                  ? StarsDesktopThemeSpec.outline(context)
                  : Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius:
            desktopMode
                ? StarsDesktopThemeSpec.controlRadius
                : BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            desktopMode ? LucideIcons.wandSparkles : Icons.auto_awesome_rounded,
            size: 17,
            color:
                desktopMode
                    ? StarsDesktopThemeSpec.mutedText(context)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 9),
          Expanded(child: label),
          const SizedBox(width: 12),
          if (desktopMode)
            ShadSwitch(
              key: const ValueKey<String>('skill-description-should-activate'),
              value: shouldActivate,
              onChanged: onShouldActivateChanged,
            )
          else
            Switch.adaptive(
              key: const ValueKey<String>('skill-description-should-activate'),
              value: shouldActivate,
              onChanged: onShouldActivateChanged,
            ),
        ],
      ),
    );
  }
}
