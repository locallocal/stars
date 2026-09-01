part of 'profile.dart';

// State mutations remain owned by the host State object in this library part.
// ignore_for_file: invalid_use_of_protected_member

extension _ProfileSettingsControls on _ProfilePageState {
  Widget _buildDesktopSettingsSection(
    BuildContext context, {
    required GlobalKey sectionKey,
    required String title,
    String? description,
    required List<Widget> children,
  }) {
    return KeyedSubtree(
      key: sectionKey,
      child: ShadCard(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        title: Text(
          title,
          style: StarsDesktopThemeSpec.sectionTitleStyle(context)?.copyWith(
            fontSize: StarsDesktopThemeSpec.botFormSectionTitleFontSize,
          ),
        ),
        description: description == null ? null : Text(description),
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1)
                  const ShadSeparator.horizontal(
                    margin: StarsDesktopThemeSpec.settingsRowSeparatorMargin,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopProfileRow(BuildContext context) {
    return _buildDesktopSettingRow(
      context,
      key: const ValueKey<String>('profile-name-setting'),
      leading: ShadTooltip(
        builder: (context) => Text(S.of(context).changeAvatar),
        child: ShadButton.ghost(
          width: 56,
          height: 56,
          padding: EdgeInsets.zero,
          onPressed: _pickImage,
          child: Semantics(
            label: S.of(context).changeAvatar,
            image: true,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: StarsDesktopThemeSpec.secondarySurface(context),
              backgroundImage: _buildAvatarImageProvider(),
            ),
          ),
        ),
      ),
      title: S.of(context).name,
      value: _name,
      onTap: _showEditNameDialog,
    );
  }

  Widget _buildDesktopSettingRow(
    BuildContext context, {
    Key? key,
    IconData? icon,
    Widget? leading,
    required String title,
    String? subtitle,
    String? value,
    required VoidCallback onTap,
  }) {
    assert(icon != null || leading != null);
    return Semantics(
      button: true,
      label: title,
      value: value ?? subtitle,
      child: ShadButton.ghost(
        key: key,
        width: double.infinity,
        height: 0,
        expands: true,
        padding: StarsDesktopThemeSpec.settingsRowPadding,
        mainAxisAlignment: MainAxisAlignment.start,
        onPressed: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: StarsDesktopThemeSpec.settingsRowMinHeight,
          ),
          child: Row(
            children: [
              SizedBox(
                width:
                    leading == null
                        ? StarsDesktopThemeSpec.settingsRowIconSlotWidth
                        : 56,
                child:
                    leading ??
                    Icon(
                      icon,
                      size: StarsDesktopThemeSpec.settingsRowIconSize,
                      color: StarsDesktopThemeSpec.mutedText(context),
                    ),
              ),
              const SizedBox(width: StarsDesktopThemeSpec.settingsRowIconGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: StarsDesktopThemeSpec.bodyStyle(context),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: StarsDesktopThemeSpec.metaStyle(context),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(
                  width: StarsDesktopThemeSpec.settingsRowValueGap,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: StarsDesktopThemeSpec.settingsRowValueMaxWidth,
                  ),
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StarsDesktopThemeSpec.metaStyle(context),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: StarsDesktopThemeSpec.softText(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopFontSizeControl(BuildContext context) {
    final isDefault =
        (_fontSize - ProfileDefaults.desktopFontSize).abs() < 0.01;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                child: Icon(
                  Icons.text_fields_outlined,
                  size: 18,
                  color: StarsDesktopThemeSpec.mutedText(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  S.of(context).fontSizeSettings,
                  style: StarsDesktopThemeSpec.bodyStyle(context),
                ),
              ),
              Text(
                '${_fontSize.round()} px',
                style: StarsDesktopThemeSpec.metaStyle(
                  context,
                )?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              ShadButton.ghost(
                enabled: !isDefault,
                size: ShadButtonSize.sm,
                onPressed:
                    () => _commitFontSize(ProfileDefaults.desktopFontSize),
                leading: const Icon(Icons.restart_alt_rounded, size: 16),
                child: Text(S.of(context).resetToDefault),
              ),
            ],
          ),
          Slider(
            value: _fontSize,
            min: 12,
            max: 24,
            divisions: 12,
            label: _fontSize.round().toString(),
            onChanged: _previewFontSize,
            onChangeEnd: _commitFontSize,
            semanticFormatterCallback:
                (value) => '${value.round()} ${S.of(context).fontSizeSettings}',
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: StarsDesktopThemeSpec.statusDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).previewText,
                  style: StarsDesktopThemeSpec.metaStyle(context),
                ),
                const SizedBox(height: 6),
                Text(
                  desktopConversationText(
                    context,
                    S.of(context).appDescription,
                  ),
                  style: TextStyle(
                    color: StarsDesktopThemeSpec.text(context),
                    fontSize: _fontSize,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopExecutionStatusControl(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Icon(
                LucideIcons.activity,
                size: 18,
                color: StarsDesktopThemeSpec.mutedText(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).chatExecutionStatus,
                    style: StarsDesktopThemeSpec.bodyStyle(context),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    S.of(context).showExecutionStatusDescription,
                    style: StarsDesktopThemeSpec.metaStyle(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ShadSwitch(
              key: const ValueKey<String>(
                'profile-show-execution-status-switch',
              ),
              value: _showExecutionStatus,
              onChanged: _updateShowExecutionStatus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationInjectedPrompt(
    BuildContext context, {
    required bool desktop,
  }) {
    final prompt = _applicationInjectedPrompt;
    final promptSwitch =
        desktop
            ? ShadSwitch(
              key: const ValueKey<String>(
                'profile-inject-application-prompt-switch',
              ),
              value: _injectApplicationPrompt,
              onChanged: _updateInjectApplicationPrompt,
            )
            : Switch.adaptive(
              key: const ValueKey<String>(
                'profile-inject-application-prompt-switch',
              ),
              value: _injectApplicationPrompt,
              onChanged: _updateInjectApplicationPrompt,
            );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MergeSemantics(
          child: Row(
            children: [
              SizedBox(
                width: StarsDesktopThemeSpec.settingsRowIconSlotWidth,
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: StarsDesktopThemeSpec.settingsRowIconSize,
                  color: StarsDesktopThemeSpec.mutedText(context),
                ),
              ),
              const SizedBox(width: StarsDesktopThemeSpec.settingsRowIconGap),
              Expanded(
                child: Text(
                  S.of(context).applicationInjectedPrompt,
                  style: StarsDesktopThemeSpec.bodyStyle(context),
                ),
              ),
              const SizedBox(width: StarsDesktopThemeSpec.settingsRowValueGap),
              promptSwitch,
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start:
                StarsDesktopThemeSpec.settingsRowIconSlotWidth +
                StarsDesktopThemeSpec.settingsRowIconGap,
          ),
          child: Text(
            S.of(context).applicationInjectedPromptDescription,
            style: StarsDesktopThemeSpec.metaStyle(context),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          key: const ValueKey<String>('profile-application-prompt-value'),
          textField: true,
          readOnly: true,
          label: S.of(context).applicationInjectedPrompt,
          value: prompt,
          child: ExcludeSemantics(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration:
                  desktop
                      ? StarsDesktopThemeSpec.statusDecoration(context)
                      : BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: StarsDesktopThemeSpec.containerRadius,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
              child: SelectableText(
                prompt,
                style: TextStyle(
                  color: StarsDesktopThemeSpec.text(context),
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Padding(
      key: const ValueKey<String>('profile-application-injected-prompt'),
      padding:
          desktop ? const EdgeInsets.fromLTRB(8, 14, 8, 16) : EdgeInsets.zero,
      child: content,
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _previewFontSize(double value) {
    if (_profile == null || (_fontSize - value).abs() < 0.01) return;

    setState(() {
      _profile = _profile!.copyWith(
        fontSize: value,
        modifyTimestamp: DateTime.now(),
      );
    });
  }

  Future<void> _commitFontSize(double value) async {
    _previewFontSize(value);
    await _saveProfile();
  }

  Future<void> _updateShowExecutionStatus(bool value) async {
    if (_profile == null || _showExecutionStatus == value) return;
    setState(() {
      _profile = _profile!.copyWith(
        showExecutionStatus: value,
        modifyTimestamp: DateTime.now(),
      );
    });
    await _saveProfile();
  }

  Future<void> _updateInjectApplicationPrompt(bool value) async {
    if (_profile == null || _injectApplicationPrompt == value) return;
    setState(() {
      _profile = _profile!.copyWith(
        injectApplicationPrompt: value,
        modifyTimestamp: DateTime.now(),
      );
    });
    await _saveProfile();
  }

  Widget _buildFontSizeSlider(BuildContext context) {
    final slider = Slider(
      value: _fontSize,
      min: 12.0,
      max: 24.0,
      divisions: 12,
      activeColor: Theme.of(context).colorScheme.onSurface,
      inactiveColor: Theme.of(
        context,
      ).colorScheme.onSurface.withValues(alpha: 0.3),
      label: _fontSize.round().toString(),
      onChanged: _previewFontSize,
      onChangeEnd: _commitFontSize,
    );

    if (isDesktopPlatform(context)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: StarsDesktopThemeSpec.statusDecoration(context),
        child: slider,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 4.0),
      child: slider,
    );
  }

  String _themeLabel(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return S.of(context).followSystem;
    }
    if (_themeMode == ThemeMode.light) {
      return S.of(context).lightMode;
    }
    return S.of(context).darkMode;
  }

  List<({String title, ThemeMode mode, IconData icon})> _themeChoices(
    BuildContext context,
  ) => [
    (
      title: S.of(context).followSystem,
      mode: ThemeMode.system,
      icon: Icons.brightness_6_rounded,
    ),
    (
      title: S.of(context).lightMode,
      mode: ThemeMode.light,
      icon: Icons.brightness_5_rounded,
    ),
    (
      title: S.of(context).darkMode,
      mode: ThemeMode.dark,
      icon: Icons.brightness_2_rounded,
    ),
  ];

  Widget _buildDesktopDialogClose(
    BuildContext dialogContext, {
    required Key key,
  }) {
    return buildStarsDesktopDialogCloseAction(
      dialogContext,
      key: key,
      onPressed: () => Navigator.pop(dialogContext),
    );
  }

  ShadPosition _desktopDialogClosePosition(BuildContext dialogContext) {
    return starsDesktopDialogClosePosition(dialogContext);
  }

  ImageProvider _buildAvatarImageProvider() {
    if (_avatar.isNotEmpty) {
      return FileImage(File(_avatar));
    }
    return const ResizeImage(
      AssetImage('assets/images/profile/avatar.png'),
      width: 256,
      height: 256,
    );
  }
}
