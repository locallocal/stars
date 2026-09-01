part of 'profile.dart';

// State mutations remain owned by the host State object in this library part.
// ignore_for_file: invalid_use_of_protected_member

extension _ProfileDialogs on _ProfilePageState {
  void _openFeedbackPage() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const FeedbackPage()),
    );
  }

  void _openUserAgreementPage() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const UserAgreementPage()),
    );
  }

  void _openPrivacyPolicyPage() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const PrivacyPolicyPage()),
    );
  }

  // 显示编辑名称对话框
  void _showEditNameDialog() {
    final TextEditingController controller = TextEditingController(text: _name);

    void saveName(BuildContext dialogContext) {
      setState(() {
        _profile = _profile!.copyWith(
          name:
              controller.text.trim().isEmpty
                  ? _randomName
                  : controller.text.trim(),
          modifyTimestamp: DateTime.now(),
        );
      });
      _saveProfile();
      Navigator.pop(dialogContext);
    }

    if (isDesktopPlatform(context)) {
      showShadDialog<void>(
        context: context,
        builder:
            (dialogContext) => ShadDialog(
              key: const ValueKey<String>('profile-edit-name-dialog'),
              closeIcon: _buildDesktopDialogClose(
                dialogContext,
                key: const ValueKey<String>('profile-edit-name-close'),
              ),
              closeIconPosition: _desktopDialogClosePosition(dialogContext),
              title: Text(S.of(dialogContext).editName),
              description: Text(S.of(dialogContext).enterDisplayName),
              actions: [
                ShadButton.outline(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(S.of(dialogContext).cancel),
                ),
                ShadButton(
                  onPressed: () => saveName(dialogContext),
                  child: Text(S.of(dialogContext).save),
                ),
              ],
              child: SizedBox(
                width: 380,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ShadInput(
                    controller: controller,
                    autofocus: true,
                    placeholder: Text(S.of(dialogContext).enterDisplayName),
                    leading: const Padding(
                      padding: EdgeInsetsDirectional.only(end: 8),
                      child: Icon(Icons.person_outline_rounded, size: 18),
                    ),
                    onSubmitted: (_) => saveName(dialogContext),
                  ),
                ),
              ),
            ),
      ).whenComplete(controller.dispose);
      return;
    }

    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Center(
              child: Text(
                S.of(context).editName,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: S.of(context).enterDisplayName,
                hintStyle: TextStyle(
                  fontSize: _fontSize,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                prefixIcon: Icon(
                  Icons.person_rounded,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(width: 0, style: BorderStyle.none),
                  borderRadius: BorderRadius.all(Radius.circular(24.0)),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  S.of(context).cancel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => saveName(context),
                child: Text(
                  S.of(context).save,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // 显示主题选项
  void _showThemeOptions() {
    final themes = _themeChoices(context);
    if (isDesktopPlatform(context)) {
      showShadDialog<void>(
        context: context,
        builder: (dialogContext) {
          final tokens = StarsDesktopTokens.of(dialogContext);
          return ShadDialog(
            key: const ValueKey<String>('profile-theme-dialog'),
            closeIcon: _buildDesktopDialogClose(
              dialogContext,
              key: const ValueKey<String>('profile-theme-close'),
            ),
            closeIconPosition: _desktopDialogClosePosition(dialogContext),
            title: Text(S.of(dialogContext).selectTheme),
            description: Text(
              S.of(dialogContext).desktopSavedImmediatelyDescription,
            ),
            child: SizedBox(
              width: 380,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  key: const ValueKey<String>('profile-theme-options'),
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: tokens.raisedSurface,
                    borderRadius: StarsDesktopThemeSpec.containerRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final theme in themes)
                        Semantics(
                          selected: theme.mode == _themeMode,
                          child: ShadButton.raw(
                            key: ValueKey<String>(
                              'profile-theme-option-${theme.mode.name}',
                            ),
                            variant:
                                theme.mode == _themeMode
                                    ? ShadButtonVariant.secondary
                                    : ShadButtonVariant.ghost,
                            height: 44,
                            expands: true,
                            mainAxisAlignment: MainAxisAlignment.start,
                            leading: Icon(
                              theme.icon,
                              size: 18,
                              color: tokens.secondaryText,
                            ),
                            trailing:
                                theme.mode == _themeMode
                                    ? Icon(
                                      LucideIcons.check,
                                      size: 16,
                                      color: tokens.accent,
                                    )
                                    : const SizedBox.square(dimension: 16),
                            onPressed: () {
                              setState(() => _themeMode = theme.mode);
                              _saveProfile();
                              Navigator.pop(dialogContext);
                            },
                            child: Text(
                              theme.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        S.of(context).selectTheme,
                        style: TextStyle(
                          fontSize: _fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: RadioGroup<ThemeMode>(
                      groupValue: _themeMode,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _themeMode = value;
                        });
                        _saveProfile();
                        Navigator.pop(context);
                      },
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...themes.map(
                              (theme) => RadioListTile<ThemeMode>(
                                title: Row(
                                  children: [
                                    Icon(theme.icon),
                                    const SizedBox(width: 12),
                                    Text(theme.title),
                                  ],
                                ),
                                activeColor:
                                    Theme.of(context).colorScheme.onSurface,
                                value: theme.mode,
                              ),
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 显示字体大小对话框
  void _showFontSizeDialog() {
    double tempFontSize = _fontSize;

    showDialog<void>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Center(
                    child: Text(
                      S.of(context).adjustFontSize,
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        S.of(context).previewText,
                        style: TextStyle(fontSize: tempFontSize),
                      ),
                      const SizedBox(height: 20),
                      Slider(
                        value: tempFontSize,
                        min: 12.0,
                        max: 24.0,
                        divisions: 12,
                        activeColor: Theme.of(context).colorScheme.onSurface,
                        inactiveColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                        label: tempFontSize.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            tempFontSize = value;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        S.of(context).cancel,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        this.setState(() {
                          _profile = _profile!.copyWith(
                            fontSize: tempFontSize,
                            modifyTimestamp: DateTime.now(),
                          );
                        });
                        _saveProfile(); // 保存设置
                        Navigator.pop(context);
                      },
                      child: Text(
                        S.of(context).save,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }
}
