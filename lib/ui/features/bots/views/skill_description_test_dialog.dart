import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/utils/theme.dart';

typedef SkillDescriptionTestRunner =
    Future<SkillDescriptionTestResult> Function(
      SkillDescriptionTestCase testCase,
    );

Future<void> showSkillDescriptionTestDialog({
  required BuildContext context,
  required SkillDescriptor skill,
  required bool desktopMode,
  required SkillDescriptionTestRunner onRun,
}) async {
  if (desktopMode) {
    await showShadDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _SkillDescriptionTestDialog(
            skill: skill,
            desktopMode: true,
            onRun: onRun,
          ),
    );
    return;
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder:
        (dialogContext) => _SkillDescriptionTestDialog(
          skill: skill,
          desktopMode: false,
          onRun: onRun,
        ),
  );
}

class _SkillDescriptionTestDialog extends StatefulWidget {
  const _SkillDescriptionTestDialog({
    required this.skill,
    required this.desktopMode,
    required this.onRun,
  });

  final SkillDescriptor skill;
  final bool desktopMode;
  final SkillDescriptionTestRunner onRun;

  @override
  State<_SkillDescriptionTestDialog> createState() =>
      _SkillDescriptionTestDialogState();
}

class _SkillDescriptionTestDialogState
    extends State<_SkillDescriptionTestDialog> {
  final _inputController = TextEditingController();
  var _shouldActivate = true;
  var _isRunning = false;
  SkillDescriptionTestResult? _result;
  String? _errorMessage;

  bool get _canRun => !_isRunning && _inputController.text.trim().isNotEmpty;

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
          enabled: !_isRunning,
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
            enabled: !_isRunning,
            onPressed: _isRunning ? null : () => Navigator.of(context).pop(),
            child: Text(strings.cancel),
          ),
          ShadButton(
            key: const ValueKey<String>('run-skill-description-test'),
            enabled: _canRun,
            onPressed: _canRun ? _runTest : null,
            leading: _buildRunLeading(context),
            child: Text(strings.runSkillDescriptionTest),
          ),
        ],
        child: _buildBody(),
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
            _buildBody(),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey<String>('cancel-skill-description-test'),
          onPressed: _isRunning ? null : () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton.icon(
          key: const ValueKey<String>('run-skill-description-test'),
          onPressed: _canRun ? _runTest : null,
          icon: _buildRunLeading(context),
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
    enabled: !_isRunning,
    onInputChanged: _handleInputChanged,
    onShouldActivateChanged: _handleShouldActivateChanged,
  );

  Widget _buildBody() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _buildForm(),
      if (_result != null || _errorMessage != null) ...[
        const SizedBox(height: 16),
        _buildOutcome(),
      ],
    ],
  );

  Widget _buildRunLeading(BuildContext context) {
    if (!_isRunning) {
      return Icon(
        widget.desktopMode ? LucideIcons.play : Icons.play_arrow_rounded,
        size: widget.desktopMode ? 15 : 18,
      );
    }
    return SizedBox.square(
      key: const ValueKey<String>('skill-description-test-progress'),
      dimension: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color:
            widget.desktopMode
                ? ShadTheme.of(context).colorScheme.primaryForeground
                : Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildOutcome() {
    final strings = S.of(context);
    final errorMessage = _errorMessage;
    if (widget.desktopMode) {
      if (errorMessage != null) {
        return Semantics(
          liveRegion: true,
          container: true,
          child: ShadAlert.destructive(
            key: const ValueKey<String>('skill-description-test-error'),
            icon: const Icon(LucideIcons.circleAlert),
            title: Text(errorMessage),
          ),
        );
      }
      final result = _result!;
      final alert =
          result.passed
              ? ShadAlert(
                key: const ValueKey<String>('skill-description-test-result'),
                icon: const Icon(LucideIcons.checkCircle),
                title: Text(strings.skillDescriptionTestResult),
                description: Text('${result.activations} / ${result.runs}'),
              )
              : ShadAlert.destructive(
                key: const ValueKey<String>('skill-description-test-result'),
                icon: const Icon(LucideIcons.circleX),
                title: Text(strings.skillDescriptionTestResult),
                description: Text('${result.activations} / ${result.runs}'),
              );
      return Semantics(liveRegion: true, container: true, child: alert);
    }

    final result = _result;
    final failed = errorMessage != null || result?.passed == false;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = failed ? colorScheme.error : colorScheme.primary;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: ValueKey<String>(
          errorMessage == null
              ? 'skill-description-test-result'
              : 'skill-description-test-error',
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              failed ? Icons.error_outline_rounded : Icons.check_circle_outline,
              color: accent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorMessage ?? strings.skillDescriptionTestResult,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 3),
                    Text('${result.activations} / ${result.runs}'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleInputChanged(String _) {
    setState(() {
      _result = null;
      _errorMessage = null;
    });
  }

  void _handleShouldActivateChanged(bool value) {
    setState(() {
      _shouldActivate = value;
      _result = null;
      _errorMessage = null;
    });
  }

  Future<void> _runTest() async {
    if (!_canRun) return;
    final testCase = SkillDescriptionTestCase(
      input: _inputController.text.trim(),
      shouldActivate: _shouldActivate,
    );
    setState(() {
      _isRunning = true;
      _result = null;
      _errorMessage = null;
    });

    SkillDescriptionTestResult? result;
    Object? failure;
    try {
      result = await widget.onRun(testCase);
    } catch (error) {
      failure = error;
    }
    if (!mounted) return;
    final errorMessage =
        failure == null ? null : safeFailureMessage(context, failure);
    setState(() {
      _isRunning = false;
      _result = result;
      _errorMessage = errorMessage;
    });
  }
}

class _SkillDescriptionTestForm extends StatelessWidget {
  const _SkillDescriptionTestForm({
    required this.skill,
    required this.inputController,
    required this.shouldActivate,
    required this.desktopMode,
    required this.enabled,
    required this.onInputChanged,
    required this.onShouldActivateChanged,
  });

  final SkillDescriptor skill;
  final TextEditingController inputController;
  final bool shouldActivate;
  final bool desktopMode;
  final bool enabled;
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
              enabled: enabled,
              placeholder: Text(strings.skillDescriptionTestInput),
              leading: const Icon(LucideIcons.messageSquareText, size: 17),
              onChanged: onInputChanged,
            ),
          ] else
            TextField(
              key: const ValueKey<String>('skill-description-test-input'),
              controller: inputController,
              enabled: enabled,
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
              enabled: enabled,
              onChanged: enabled ? onShouldActivateChanged : null,
            )
          else
            Switch.adaptive(
              key: const ValueKey<String>('skill-description-should-activate'),
              value: shouldActivate,
              onChanged: enabled ? onShouldActivateChanged : null,
            ),
        ],
      ),
    );
  }
}
