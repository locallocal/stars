part of 'add_bot.dart';

// State mutations remain owned by the host State object in this library part.
// ignore_for_file: invalid_use_of_protected_member

extension _AddBotDesktopForm on _AddBotPageState {
  Widget _buildEmbeddedDesktop(BuildContext context) {
    final isHuggingFace = providerController.text == 'HuggingFace';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildDesktopHeader(context),
          const ShadSeparator.horizontal(),
          Expanded(
            child: Scrollbar(
              controller: _desktopScrollController,
              child: SingleChildScrollView(
                controller: _desktopScrollController,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _AddBotPageState._desktopFormWidth,
                    ),
                    child: ShadForm(
                      key: _desktopFormKey,
                      autovalidateMode:
                          ShadAutovalidateMode.alwaysAfterFirstValidation,
                      child: FocusTraversalGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDesktopSection(
                              context,
                              S.of(context).basicInformation,
                              [_buildDesktopNameInput()],
                              sectionKey: const ValueKey<String>(
                                'add-bot-basic-section',
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildDesktopSection(
                              context,
                              S.of(context).providerInformation,
                              [
                                _buildDesktopProviderInput(),
                                if (isHuggingFace)
                                  _buildDesktopSubProviderInput(),
                                _buildDesktopApiTypeSelector(),
                                _buildDesktopApiAddressInput(),
                                _buildDesktopApiKeyInput(),
                              ],
                              sectionKey: const ValueKey<String>(
                                'add-bot-provider-section',
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildDesktopSection(
                              context,
                              S.of(context).modelConfiguration,
                              [
                                _buildDesktopModelsInput(),
                                _buildDesktopSystemPromptInput(),
                              ],
                              sectionKey: const ValueKey<String>(
                                'add-bot-model-section',
                              ),
                            ),
                            if (_selectedModelSupportsMcp) ...[
                              const SizedBox(height: 20),
                              _buildDesktopSection(
                                context,
                                S.of(context).mcpServers,
                                [_buildMcpServerPicker()],
                                sectionKey: const ValueKey<String>(
                                  'add-bot-mcp-section',
                                ),
                              ),
                            ],
                            if (widget.skillViewModel?.supportsAutoActivation ??
                                false) ...[
                              const SizedBox(height: 20),
                              _buildDesktopSection(
                                context,
                                S.of(context).botSkills,
                                [
                                  AddBotSkills(
                                    viewModel: widget.skillViewModel!,
                                  ),
                                ],
                                sectionKey: const ValueKey<String>(
                                  'add-bot-skills-section',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildDesktopFooter(context),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    final strings = S.of(context);
    final tokens = StarsDesktopTokens.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
      child: Row(
        children: [
          ShadTooltip(
            builder: (context) => Text(strings.botAvatar),
            child: ShadButton.ghost(
              width: 48,
              height: 48,
              padding: EdgeInsets.zero,
              onPressed: _pickImage,
              child: Semantics(
                label: strings.botAvatar,
                image: true,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          avatarImage == null
                              ? getFrostedProviderColor(
                                providerController.text,
                                tokens.accent,
                              )
                              : tokens.accent,
                      backgroundImage:
                          avatarImage != null ? FileImage(avatarImage!) : null,
                      child:
                          avatarImage == null
                              ? buildProviderLogo(
                                context,
                                '',
                                providerController.text,
                                24,
                              )
                              : null,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: tokens.raisedSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: tokens.separator, width: 0),
                        ),
                        child: Icon(
                          LucideIcons.pencil,
                          size: 11,
                          color: tokens.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.addBot,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StarsDesktopThemeSpec.pageTitleStyle(context),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.botInformation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StarsDesktopThemeSpec.metaStyle(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StarsDesktopIconAction(
            key: const ValueKey<String>('add-bot-close'),
            icon: LucideIcons.x,
            iconSize: 18,
            label: MaterialLocalizations.of(context).closeButtonTooltip,
            enabled: !_isSubmitting,
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSection(
    BuildContext context,
    String title,
    List<Widget> children, {
    required Key sectionKey,
  }) {
    final tokens = StarsDesktopTokens.of(context);
    return ShadCard(
      key: sectionKey,
      width: double.infinity,
      padding: const EdgeInsets.all(_AddBotPageState._desktopSectionPadding),
      backgroundColor: tokens.raisedSurface,
      border: ShadBorder.all(
        color: tokens.separator,
        width: _AddBotPageState._desktopSectionBorderWidth,
      ),
      columnCrossAxisAlignment: CrossAxisAlignment.stretch,
      title: Text(
        title,
        style: StarsDesktopThemeSpec.sectionTitleStyle(context)?.copyWith(
          fontSize: StarsDesktopThemeSpec.botFormSectionTitleFontSize,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopFooter(BuildContext context) {
    final shadTheme = ShadTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_errorMessage case final error?)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _AddBotPageState._desktopFormWidth,
                ),
                child: SizedBox(
                  key: const ValueKey<String>('add-bot-error-region'),
                  width: double.infinity,
                  child: StarsInlineErrorAlert(
                    error: error,
                    isDesktop: true,
                    onDismiss: _dismissError,
                    alertKey: const ValueKey<String>('add-bot-error-alert'),
                    messageKey: const ValueKey<String>('add-bot-error-message'),
                    dismissKey: const ValueKey<String>('dismiss-add-bot-error'),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
        const ShadSeparator.horizontal(),
        ColoredBox(
          key: const ValueKey<String>('add-bot-footer-surface'),
          color: shadTheme.colorScheme.background,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _AddBotPageState._desktopFormWidth,
                  ),
                  child: SizedBox(
                    key: const ValueKey<String>('add-bot-footer-actions'),
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ShadButton.outline(
                          enabled: !_isSubmitting,
                          onPressed:
                              _isSubmitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                          child: Text(S.of(context).cancel),
                        ),
                        const SizedBox(width: 8),
                        ShadButton(
                          key: const ValueKey<String>('add-bot-submit'),
                          enabled: !_isSubmitting,
                          onPressed: _isSubmitting ? null : _submitBot,
                          leading:
                              _isSubmitting
                                  ? SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          shadTheme
                                              .colorScheme
                                              .primaryForeground,
                                    ),
                                  )
                                  : const Icon(LucideIcons.plus, size: 17),
                          child: Text(S.of(context).addBot),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _desktopIconButton({
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

  Widget _desktopInputLeading(IconData icon) {
    return SizedBox(
      width: 17,
      height: 44,
      child: Center(child: Icon(icon, size: 17)),
    );
  }

  Widget _desktopSelectMenu<T>({
    Key? key,
    required List<T> options,
    required T? selectedValue,
    required Widget Function(VoidCallback toggle) fieldBuilder,
    required ValueChanged<T> onSelected,
    String Function(T value)? labelBuilder,
    Widget Function(T value)? leadingBuilder,
    double? menuWidth,
    bool alignEnd = false,
    bool constrainMenuWidth = false,
  }) {
    assert(!alignEnd || menuWidth != null);
    return StarsDesktopMenu<T>(
      key: key,
      width: menuWidth ?? (constrainMenuWidth ? 420 : 220),
      alignEnd: alignEnd,
      items: [
        for (final option in options)
          StarsDesktopMenuItem<T>(
            value: option,
            label: labelBuilder?.call(option) ?? option.toString(),
            leading: leadingBuilder?.call(option),
            selected: option == selectedValue,
          ),
      ],
      onSelected: onSelected,
      triggerBuilder: (context, toggle, isOpen) => fieldBuilder(toggle),
    );
  }

  Widget _buildDesktopNameInput() {
    return ShadInputFormField(
      key: const ValueKey<String>('add-bot-name'),
      id: 'name',
      controller: nameController,
      padding: StarsDesktopThemeSpec.formFieldPadding,
      textInputAction: TextInputAction.next,
      label: Text(S.of(context).botName),
      placeholder: Text(S.of(context).enterBotName),
      leading: _desktopInputLeading(LucideIcons.sparkles),
      constraints: _AddBotPageState._desktopInputConstraints,
      validator:
          (value) =>
              value.trim().isEmpty ? S.of(context).fillRequiredFields : null,
    );
  }

  Widget _buildDesktopProviderInput() {
    return ShadInputFormField(
      key: const ValueKey<String>('add-bot-provider'),
      id: 'provider',
      controller: providerController,
      padding: StarsDesktopThemeSpec.formFieldPadding,
      textInputAction: TextInputAction.next,
      label: Text(S.of(context).provider),
      placeholder: Text(S.of(context).selectProvider),
      leading: _desktopInputLeading(LucideIcons.building2),
      constraints: _AddBotPageState._desktopInputConstraints,
      onChanged: _handleProviderTextChanged,
      trailing: _desktopSelectMenu(
        options: providersInfo.keys.toList(growable: false),
        selectedValue: providerController.text,
        onSelected: _onProviderChanged,
        menuWidth: _AddBotPageState._desktopProviderMenuWidth,
        alignEnd: true,
        leadingBuilder:
            (provider) => buildProviderLogo(context, '', provider, 18),
        fieldBuilder:
            (toggleMenu) => _desktopIconButton(
              tooltip: S.of(context).selectProvider,
              icon: LucideIcons.chevronDown,
              onPressed: toggleMenu,
            ),
      ),
    );
  }

  Widget _buildDesktopSubProviderInput() {
    final subProviders =
        providersInfo[providerController.text]?['sub_providers']
            as Map<String, Map>;
    return _desktopSelectMenu(
      options: subProviders.keys.toList(growable: false),
      selectedValue: subProviderController.text,
      onSelected: _onSubProviderChanged,
      leadingBuilder:
          (provider) => buildProviderLogo(context, '', provider, 18),
      fieldBuilder:
          (toggleMenu) => ShadInputFormField(
            key: const ValueKey<String>('add-bot-sub-provider'),
            id: 'subProvider',
            controller: subProviderController,
            padding: StarsDesktopThemeSpec.formFieldPadding,
            textInputAction: TextInputAction.next,
            label: Text('${S.of(context).provider} (HuggingFace)'),
            placeholder: Text(S.of(context).selectProvider),
            leading: _desktopInputLeading(LucideIcons.server),
            constraints: _AddBotPageState._desktopInputConstraints,
            onChanged: _handleSubProviderTextChanged,
            trailing: _desktopIconButton(
              tooltip: S.of(context).selectProvider,
              icon: LucideIcons.chevronDown,
              onPressed: toggleMenu,
            ),
          ),
    );
  }

  Widget _buildDesktopApiTypeSelector() {
    return _desktopSelectMenu(
      options: Bot.getAllApiTypes(),
      selectedValue: apiTypeController.text,
      onSelected: (value) {
        setState(() => apiTypeController.text = value);
      },
      fieldBuilder:
          (toggleMenu) => ShadInputFormField(
            key: const ValueKey<String>('add-bot-api-type'),
            id: 'apiType',
            controller: apiTypeController,
            padding: StarsDesktopThemeSpec.formFieldPadding,
            enabled: _isCustomProvider,
            textInputAction: TextInputAction.next,
            label: Text(S.of(context).apiType),
            leading: _desktopInputLeading(LucideIcons.tags),
            constraints: _AddBotPageState._desktopInputConstraints,
            trailing: _desktopIconButton(
              tooltip: S.of(context).apiType,
              icon: LucideIcons.chevronDown,
              onPressed: _isCustomProvider ? toggleMenu : null,
            ),
          ),
    );
  }

  Widget _buildDesktopApiAddressInput() {
    return ShadInputFormField(
      key: const ValueKey<String>('add-bot-base-url'),
      id: 'baseUrl',
      controller: baseURLController,
      padding: StarsDesktopThemeSpec.formFieldPadding,
      textInputAction: TextInputAction.next,
      label: Text(S.of(context).apiAddress),
      leading: _desktopInputLeading(LucideIcons.link),
      constraints: _AddBotPageState._desktopInputConstraints,
      validator:
          (value) =>
              value.trim().isEmpty ? S.of(context).enterApiAddress : null,
    );
  }

  Widget _buildDesktopApiKeyInput() {
    return ShadInputFormField(
      key: const ValueKey<String>('add-bot-api-key'),
      id: 'apiKey',
      controller: apiKeyController,
      padding: StarsDesktopThemeSpec.formFieldPadding,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.next,
      label: Text(S.of(context).apiKey),
      leading: _desktopInputLeading(LucideIcons.keyRound),
      constraints: _AddBotPageState._desktopInputConstraints,
      validator:
          (value) =>
              value.trim().isEmpty ? S.of(context).pleaseEnterApiKey : null,
      trailing: _desktopIconButton(
        tooltip:
            _isPasswordVisible
                ? S.of(context).hideApiKey
                : S.of(context).showApiKey,
        icon: _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
        onPressed: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
      ),
    );
  }

  Widget _buildDesktopModelsInput() {
    return ShadInputFormField(
      key: const ValueKey<String>('add-bot-model'),
      id: 'model',
      controller: selectedModelController,
      padding: StarsDesktopThemeSpec.formFieldPadding,
      textInputAction: TextInputAction.next,
      label: Text(S.of(context).model),
      placeholder: Text(S.of(context).selectModel),
      leading: _desktopInputLeading(LucideIcons.cpu),
      constraints: _AddBotPageState._desktopInputConstraints,
      trailing:
          providerModels.isEmpty
              ? _isLoadingModels
                  ? const SizedBox.square(
                    dimension: 30,
                    child: Center(
                      child: SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                  : _desktopIconButton(
                    tooltip: S.of(context).fetchModelList,
                    icon: LucideIcons.refreshCw,
                    onPressed: _fetchModels,
                  )
              : _desktopSelectMenu<AiModelInfo>(
                key: const ValueKey<String>('add-bot-model-menu'),
                options: providerModels,
                selectedValue: _modelInfoById(selectedModelController.text),
                labelBuilder: (model) => model.modelId,
                menuWidth: _AddBotPageState._desktopModelMenuWidth,
                alignEnd: true,
                constrainMenuWidth: true,
                onSelected: (value) {
                  setState(() => selectedModelController.text = value.modelId);
                },
                fieldBuilder:
                    (toggleMenu) => _desktopIconButton(
                      tooltip: S.of(context).selectModel,
                      icon: LucideIcons.chevronDown,
                      onPressed: toggleMenu,
                    ),
              ),
    );
  }

  Widget _buildDesktopSystemPromptInput() {
    return ShadTextareaFormField(
      key: const ValueKey<String>('add-bot-system-prompt'),
      id: 'systemPrompt',
      controller: systemPromptController,
      label: Text(S.of(context).systemPrompt),
      leading: const Icon(LucideIcons.notebookText, size: 17),
      minHeight: 96,
      maxHeight: 96,
      resizable: false,
    );
  }
}
