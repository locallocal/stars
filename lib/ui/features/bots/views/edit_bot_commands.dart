part of 'edit_bot.dart';

// State mutations remain owned by the host State object in this library part.
// ignore_for_file: invalid_use_of_protected_member

extension _EditBotCommands on _EditAIBotPageState {
  Future<void> _saveBot() async {
    if (widget.readOnly || _isSaving || _isDeleting) return;
    if (nameController.text.trim().isEmpty) {
      setState(() {
        _commandFailure = const AppFailure.validation(
          'bot_required_fields_missing',
        );
      });
      return;
    }
    final navigator = Navigator.of(context);
    final keepsOriginalModel =
        widget.embedded ||
        selectedModelController.text.trim() == widget.bot.model;
    final updatedBot = const BuildBot()(
      BotDraft(
        id: widget.bot.id,
        name: nameController.text,
        avatar: avatarImage?.path ?? widget.bot.avatar,
        provider:
            widget.embedded ? widget.bot.provider : providerController.text,
        baseUrl: widget.embedded ? widget.bot.baseURL : baseURLController.text,
        apiKey: apiKeyController.text,
        apiType: widget.embedded ? widget.bot.apiType : apiTypeController.text,
        model:
            widget.embedded ? widget.bot.model : selectedModelController.text,
        systemPrompt: systemPromptController.text,
        supportsMcp: _modelSupportsMcp,
        supportsAutomaticSkillActivation:
            _modelSupportsAutomaticSkillActivation,
        supportsSkills:
            keepsOriginalModel ? widget.bot.configuredSupportsSkills : null,
        contextWindowTokens:
            keepsOriginalModel
                ? widget.bot.configuredContextWindowTokens
                : null,
        inputModalities:
            keepsOriginalModel
                ? widget.bot.configuredInputModalities ?? const []
                : const [],
        outputModalities:
            keepsOriginalModel
                ? widget.bot.configuredOutputModalities ?? const []
                : const [],
        mcpServerIds: _mcpServerIds,
        mcpTools: _mcpToolConfigurations,
        createdAt: widget.bot.createTimestamp,
        modifiedAt: DateTime.now(),
      ),
    );

    final saveRevision = _editRevision;
    var saved = false;
    setState(() {
      _isSaving = true;
      _isSaved = false;
      _commandFailure = null;
    });
    try {
      await widget.onBotUpdated(updatedBot);
      saved = true;
      if (!widget.embedded && mounted) {
        navigator.pop();
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _commandFailure = AppFailure.from(error, code: 'bot_update_failed');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaved = widget.embedded && saved && _editRevision == saveRevision;
        });
      }
    }
  }

  void _markUnsaved(String _) {
    if (!mounted) return;
    setState(() {
      _editRevision += 1;
      _isSaved = false;
    });
  }

  Widget _buildDetailValue({
    required Key key,
    required String label,
    required IconData icon,
    required String value,
    Widget? valueWidget,
    Widget? trailing,
    TextAlign textAlign = TextAlign.end,
    bool valueOnNewLine = false,
  }) {
    final materialTheme = Theme.of(context);
    final displayValue = value.trim().isEmpty ? '—' : value;
    final labelStyle =
        widget.embedded
            ? StarsDesktopThemeSpec.bodyStyle(context)
            : materialTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            );
    final valueStyle =
        widget.embedded
            ? StarsDesktopThemeSpec.metaStyle(context)
            : materialTheme.textTheme.bodySmall?.copyWith(
              color: materialTheme.colorScheme.onSurfaceVariant,
            );
    final iconColor =
        widget.embedded
            ? StarsDesktopThemeSpec.mutedText(context)
            : materialTheme.colorScheme.primary;

    final leading = SizedBox(
      width: StarsDesktopThemeSpec.settingsRowIconSlotWidth,
      child: Icon(
        icon,
        size: widget.embedded ? StarsDesktopThemeSpec.settingsRowIconSize : 20,
        color: iconColor,
      ),
    );

    return KeyedSubtree(
      key: key,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useSettingsRowLayout = constraints.maxWidth >= 600;
          if (valueOnNewLine) {
            return Padding(
              padding:
                  useSettingsRowLayout
                      ? StarsDesktopThemeSpec.settingsRowPadding
                      : EdgeInsets.symmetric(
                        horizontal: widget.embedded ? 8 : 0,
                        vertical: 8,
                      ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      useSettingsRowLayout
                          ? StarsDesktopThemeSpec.settingsRowMinHeight
                          : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading,
                    SizedBox(
                      width:
                          widget.embedded
                              ? StarsDesktopThemeSpec.settingsRowIconGap
                              : 16,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(label, style: labelStyle)),
                              if (trailing != null) ...[
                                const SizedBox(width: 8),
                                trailing,
                              ],
                            ],
                          ),
                          SizedBox(height: useSettingsRowLayout ? 6 : 2),
                          SizedBox(
                            width: double.infinity,
                            child:
                                valueWidget ??
                                SelectableText(
                                  displayValue,
                                  textAlign: TextAlign.start,
                                  style: valueStyle,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (useSettingsRowLayout) {
            return Padding(
              padding: StarsDesktopThemeSpec.settingsRowPadding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: StarsDesktopThemeSpec.settingsRowMinHeight,
                ),
                child: Row(
                  children: [
                    leading,
                    const SizedBox(
                      width: StarsDesktopThemeSpec.settingsRowIconGap,
                    ),
                    Expanded(child: Text(label, style: labelStyle)),
                    const SizedBox(
                      width: StarsDesktopThemeSpec.settingsRowValueGap,
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth:
                            StarsDesktopThemeSpec.settingsRowValueMaxWidth,
                      ),
                      child:
                          valueWidget ??
                          SelectableText(
                            displayValue,
                            textAlign: textAlign,
                            style: valueStyle,
                          ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing,
                    ],
                  ],
                ),
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.embedded ? 8 : 0,
              vertical: 8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                SizedBox(
                  width:
                      widget.embedded
                          ? StarsDesktopThemeSpec.settingsRowIconGap
                          : 16,
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: labelStyle),
                            const SizedBox(height: 2),
                            valueWidget ??
                                SelectableText(
                                  displayValue,
                                  textAlign: TextAlign.start,
                                  style: valueStyle,
                                ),
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailApiKey() {
    final apiKey = apiKeyController.text;
    final displayValue =
        apiKey.isEmpty
            ? ''
            : _isPasswordVisible
            ? apiKey
            : '••••••••••••';
    return _buildDetailValue(
      key: const ValueKey<String>('bot-detail-api-key'),
      label: S.of(context).apiKey,
      icon: Icons.key_outlined,
      value: displayValue,
      trailing:
          apiKey.isEmpty
              ? null
              : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailAction(
                    key: const ValueKey<String>('bot-detail-copy-api-key'),
                    tooltip: S.of(context).copyApiKey,
                    icon: Icons.copy_outlined,
                    onPressed:
                        () => Clipboard.setData(ClipboardData(text: apiKey)),
                  ),
                  _buildDetailAction(
                    key: const ValueKey<String>('bot-detail-toggle-api-key'),
                    tooltip:
                        _isPasswordVisible
                            ? S.of(context).hideApiKey
                            : S.of(context).showApiKey,
                    icon:
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ],
              ),
    );
  }

  Widget _buildDetailAction({
    required Key key,
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    if (widget.embedded) {
      return StarsDesktopIconAction(
        key: key,
        icon: icon,
        label: tooltip,
        onPressed: onPressed,
        iconSize: 16,
      );
    }
    return IconButton(
      key: key,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
    );
  }

  Widget _buildDesktopInput({
    Key? key,
    required String label,
    required IconData icon,
    required TextEditingController controller,
    Widget? trailing,
    String? placeholder,
    bool obscureText = false,
    bool isSensitive = false,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    final shadTheme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: shadTheme.textTheme.small),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ShadInput(
            key: key,
            controller: controller,
            padding: StarsDesktopThemeSpec.formFieldPadding,
            placeholder: placeholder == null ? null : Text(placeholder),
            leading: SizedBox(
              width: 17,
              height: 44,
              child: Center(child: Icon(icon, size: 17)),
            ),
            trailing: trailing,
            obscureText: obscureText,
            keyboardType: isSensitive ? TextInputType.visiblePassword : null,
            autocorrect: !isSensitive,
            enableSuggestions: !isSensitive,
            enableIMEPersonalizedLearning: !isSensitive,
            readOnly: readOnly,
            alignment: Alignment.centerLeft,
            placeholderAlignment: Alignment.centerLeft,
            crossAxisAlignment: CrossAxisAlignment.center,
            constraints: const BoxConstraints(
              minHeight: StarsDesktopThemeSpec.botFormFieldHeight,
            ),
            textInputAction: TextInputAction.next,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTextarea({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? placeholder,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    final shadTheme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: shadTheme.textTheme.small),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ShadTextarea(
            controller: controller,
            placeholder: placeholder == null ? null : Text(placeholder),
            leading: Icon(icon, size: 17),
            minHeight: 112,
            maxHeight: 220,
            readOnly: readOnly,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _desktopInputAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return StarsDesktopIconAction(
      icon: icon,
      label: tooltip,
      enabled: onPressed != null,
      onPressed: onPressed,
      iconSize: 16,
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(
        icon,
        size: 24,
        color: Theme.of(context).colorScheme.primary,
      ),
      suffixIcon: suffixIcon,
      border: const OutlineInputBorder(
        borderSide: BorderSide(width: 0, style: BorderStyle.none),
        borderRadius: BorderRadius.all(Radius.circular(24.0)),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildDeleteButton(double? fontSize) {
    Future<void> deleteBot() async {
      if (widget.readOnly || _isDeleting || _isSaving) return;
      final shouldDelete =
          widget.embedded
              ? await showShadDialog<bool>(
                context: context,
                variant: ShadDialogVariant.alert,
                builder:
                    (context) => ShadDialog.alert(
                      title: Text(S.of(context).deleteBot),
                      description: Text(
                        desktopConversationText(
                          context,
                          S.of(context).confirmDeleteBot(widget.bot.name),
                        ),
                      ),
                      actions: [
                        ShadButton.outline(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(S.of(context).cancel),
                        ),
                        ShadButton.destructive(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(S.of(context).delete),
                        ),
                      ],
                    ),
              )
              : await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Center(
                        child: Text(
                          S.of(context).deleteBot,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      content: Text(
                        desktopConversationText(
                          context,
                          S.of(context).confirmDeleteBot(widget.bot.name),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            S.of(context).cancel,
                            style: TextStyle(
                              fontSize: fontSize,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            S.of(context).delete,
                            style: TextStyle(
                              fontSize: fontSize,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
              );

      if (shouldDelete != true) return;

      if (_isDeleting || _isSaving) return;
      setState(() {
        _isDeleting = true;
        _commandFailure = null;
      });
      try {
        await widget.onBotDeleted();
        if (!widget.embedded && mounted) {
          Navigator.pop(context);
        }
      } on Object catch (error) {
        if (mounted) {
          setState(() {
            _commandFailure = AppFailure.from(error, code: 'bot_delete_failed');
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }

    if (widget.embedded) {
      return StarsDesktopIconAction(
        icon: LucideIcons.trash2,
        label: S.of(context).deleteBot,
        variant: ShadButtonVariant.destructive,
        enabled: !_isSaving && !_isDeleting,
        iconSize: 18,
        onPressed: _isSaving || _isDeleting ? null : deleteBot,
      );
    }

    return IconButton(
      tooltip: S.of(context).deleteBot,
      icon: Icon(
        Icons.delete_outline_rounded,
        size: 24,
        color: Theme.of(context).colorScheme.error,
      ),
      onPressed: deleteBot,
    );
  }
}
