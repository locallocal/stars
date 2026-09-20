import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/chat/view_models/model_log_view_model.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';

class ModelLogSettingsView extends StatefulWidget {
  const ModelLogSettingsView({super.key, required this.viewModel});
  final ModelLogViewModel viewModel;

  @override
  State<ModelLogSettingsView> createState() => _ModelLogSettingsViewState();
}

class _ModelLogSettingsViewState extends State<ModelLogSettingsView> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.viewModel.load());
  }

  @override
  void didUpdateWidget(covariant ModelLogSettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      unawaited(widget.viewModel.load());
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      final vm = widget.viewModel;
      final settings = vm.settings;
      final s = S.of(context);
      final theme = ShadTheme.of(context);
      final secondary = StarsDesktopThemeSpec.metaStyle(context);
      final error = switch (vm.error) {
        ModelLogActionError.load => s.modelLogLoadFailed,
        ModelLogActionError.save => s.modelLogSaveFailed,
        ModelLogActionError.open => s.modelLogOpenFailed,
        ModelLogActionError.copy => s.modelLogCopyFailed,
        null => settings?.writeFailed == true ? s.modelLogWriteFailed : null,
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: StarsInspectorInfoRow(
              icon: LucideIcons.fileText,
              label: s.modelRequestLogging,
              description:
                  '${s.modelRequestLoggingDescription}\n'
                  '${s.modelRequestLoggingRetention}',
              layout: StarsInspectorInfoRowLayout.settings,
              trailingWidth: 44,
              trailing: ShadSwitch(
                key: const ValueKey('model-log-switch'),
                width: 44,
                value: settings?.enabled ?? false,
                enabled: settings != null && !vm.busy,
                onChanged: (value) => unawaited(vm.setEnabled(value)),
              ),
            ),
          ),
          if (settings != null || error != null)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start:
                    StarsDesktopThemeSpec.settingsRowPadding.left +
                    StarsDesktopThemeSpec.settingsRowIconSlotWidth +
                    StarsDesktopThemeSpec.settingsRowIconGap,
                end: StarsDesktopThemeSpec.settingsRowPadding.right,
                bottom: StarsDesktopThemeSpec.settingsRowPadding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (settings != null) ...[
                    Text(
                      s.modelLogDirectory,
                      style: StarsDesktopThemeSpec.bodyStyle(context),
                    ),
                    const SizedBox(height: 4),
                    _ModelLogPath(
                      path: settings.directoryPath,
                      copied: vm.pathCopied,
                      onCopy: vm.busy ? null : () => unawaited(vm.copyPath()),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error,
                        style: secondary?.copyWith(
                          color: theme.colorScheme.destructive,
                        ),
                      ),
                    ),
                    if (settings == null)
                      ShadButton.ghost(
                        onPressed: vm.busy ? null : () => unawaited(vm.load()),
                        child: Text(s.retry),
                      ),
                  ],
                ],
              ),
            ),
        ],
      );
    },
  );
}

class _ModelLogPath extends StatefulWidget {
  const _ModelLogPath({
    required this.path,
    required this.copied,
    required this.onCopy,
  });

  final String path;
  final bool copied;
  final VoidCallback? onCopy;

  @override
  State<_ModelLogPath> createState() => _ModelLogPathState();
}

class _ModelLogPathState extends State<_ModelLogPath> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final showCopy =
        _hovered ||
        _focused ||
        !isDesktopPlatform(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return Focus(
      canRequestFocus: false,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SelectableText(
                widget.path,
                style: StarsDesktopThemeSpec.metaStyle(context),
              ),
            ),
            const SizedBox(width: 4),
            // Keep the action's space and keyboard access when it is hidden.
            AnimatedOpacity(
              opacity: showCopy ? 1 : 0,
              duration:
                  MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 100),
              alwaysIncludeSemantics: true,
              child: IgnorePointer(
                ignoring: !showCopy,
                child: StarsDesktopIconAction(
                  key: const ValueKey('model-log-copy-path'),
                  icon: widget.copied ? LucideIcons.check : LucideIcons.copy,
                  iconSize: 16,
                  label: widget.copied ? s.modelLogCopied : s.modelLogCopyPath,
                  foregroundColor: StarsDesktopThemeSpec.mutedText(context),
                  onPressed: widget.onCopy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
