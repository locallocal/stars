import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/features/chat/view_models/model_log_view_model.dart';
import 'package:stars/utils/theme.dart';

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
      final secondary = theme.textTheme.muted;
      final error = switch (vm.error) {
        ModelLogActionError.load => s.modelLogLoadFailed,
        ModelLogActionError.save => s.modelLogSaveFailed,
        ModelLogActionError.open => s.modelLogOpenFailed,
        ModelLogActionError.copy => s.modelLogCopyFailed,
        null => settings?.writeFailed == true ? s.modelLogWriteFailed : null,
      };
      return Padding(
        padding: StarsDesktopThemeSpec.settingsRowPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: StarsDesktopThemeSpec.settingsRowIconSlotWidth,
                  child: Icon(
                    LucideIcons.fileText,
                    size: StarsDesktopThemeSpec.settingsRowIconSize,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                const SizedBox(width: StarsDesktopThemeSpec.settingsRowIconGap),
                Expanded(
                  child: Text(
                    s.modelRequestLogging,
                    style: theme.textTheme.small,
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  label: s.modelRequestLogging,
                  child: ShadSwitch(
                    key: const ValueKey('model-log-switch'),
                    value: settings?.enabled ?? false,
                    enabled: settings != null && !vm.busy,
                    onChanged: (value) => unawaited(vm.setEnabled(value)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(s.modelRequestLoggingDescription, style: secondary),
            const SizedBox(height: 4),
            Text(s.modelRequestLoggingRetention, style: secondary),
            if (settings != null) ...[
              const SizedBox(height: 16),
              Text(s.modelLogDirectory, style: theme.textTheme.small),
              const SizedBox(height: 4),
              SelectableText(settings.directoryPath, style: secondary),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ShadButton.outline(
                    key: const ValueKey('model-log-copy-path'),
                    size: ShadButtonSize.sm,
                    leading: Icon(
                      vm.pathCopied ? LucideIcons.check : LucideIcons.copy,
                      size: 14,
                    ),
                    onPressed: vm.busy ? null : () => unawaited(vm.copyPath()),
                    child: Text(
                      vm.pathCopied ? s.modelLogCopied : s.modelLogCopyPath,
                    ),
                  ),
                  ShadButton.ghost(
                    key: const ValueKey('model-log-open-directory'),
                    size: ShadButtonSize.sm,
                    leading: const Icon(LucideIcons.folderOpen, size: 14),
                    onPressed:
                        vm.busy ? null : () => unawaited(vm.openDirectory()),
                    child: Text(s.modelLogOpenDirectory),
                  ),
                ],
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  style: secondary.copyWith(
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
      );
    },
  );
}
