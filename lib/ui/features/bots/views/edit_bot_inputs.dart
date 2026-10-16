part of 'edit_bot.dart';

// State mutations remain owned by the host State object in this library part.
// ignore_for_file: invalid_use_of_protected_member

extension _EditBotInputs on _EditAIBotPageState {
  Widget _buildNameInput(double? fontSize) {
    if (widget.readOnly) {
      return _buildDetailValue(
        key: const ValueKey<String>('bot-detail-name'),
        label: S.of(context).botName,
        icon: Icons.auto_awesome_outlined,
        value: nameController.text,
      );
    }
    if (widget.embedded) {
      return _buildDesktopInput(
        key: const ValueKey<String>('desktop-bot-name'),
        label: S.of(context).botName,
        icon: Icons.auto_awesome_outlined,
        controller: nameController,
        placeholder: S.of(context).enterBotName,
        readOnly: widget.readOnly,
        onChanged: widget.readOnly ? null : _markUnsaved,
      );
    }
    return TextField(
      controller: nameController,
      readOnly: widget.readOnly,
      decoration: _fieldDecoration(
        label: S.of(context).botName,
        icon: Icons.auto_awesome_outlined,
        hintText: S.of(context).enterBotName,
      ),
    );
  }

  Widget _buildCreationTimeDetail() {
    return _buildTimestampDetail(
      key: const ValueKey<String>('bot-detail-creation-time'),
      label: S.of(context).creationTime,
      icon: Icons.schedule_outlined,
      timestamp: widget.bot.createTimestamp,
    );
  }

  Widget _buildModificationTimeDetail() {
    return _buildTimestampDetail(
      key: const ValueKey<String>('bot-detail-modification-time'),
      label: S.of(context).modificationTime,
      icon: Icons.update_outlined,
      timestamp: widget.bot.modifyTimestamp,
    );
  }

  Widget _buildTimestampDetail({
    required Key key,
    required String label,
    required IconData icon,
    required DateTime timestamp,
  }) {
    final localizations = MaterialLocalizations.of(context);
    final localTimestamp = timestamp.toLocal();
    final formattedDate = localizations.formatFullDate(localTimestamp);
    final formattedTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localTimestamp),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return _buildDetailValue(
      key: key,
      label: label,
      icon: icon,
      value: '$formattedDate $formattedTime',
    );
  }

  int? get _resolvedContextWindowTokens =>
      _modelInfo?.contextWindowTokens ??
      widget.bot.configuredContextWindowTokens;

  bool? get _resolvedSupportsSkills {
    final supportsSkills =
        _modelInfo?.supportsSkills ?? widget.bot.configuredSupportsSkills;
    if (supportsSkills != null) return supportsSkills;
    final supportsAutomaticActivation =
        _modelInfo?.supportsAutomaticSkillActivation ??
        widget.bot.configuredSupportsAutomaticSkillActivation;
    return supportsAutomaticActivation == true ? true : null;
  }

  bool? get _resolvedSupportsMcp =>
      _modelInfo?.supportsMcp ?? widget.bot.configuredSupportsMcp;

  List<InputModality> get _resolvedInputModalities =>
      List<InputModality>.unmodifiable(
        _modelInfo?.inputModalities.isNotEmpty == true
            ? _modelInfo!.inputModalities
            : widget.bot.configuredInputModalities?.isNotEmpty == true
            ? widget.bot.configuredInputModalities!
            : _providerInputModalities.isNotEmpty
            ? _providerInputModalities
            : const [InputModality.text],
      );

  List<OutputModality> get _resolvedOutputModalities =>
      List<OutputModality>.unmodifiable(
        _modelInfo?.outputModalities.isNotEmpty == true
            ? _modelInfo!.outputModalities
            : widget.bot.configuredOutputModalities?.isNotEmpty == true
            ? widget.bot.configuredOutputModalities!
            : _providerOutputModalities.isNotEmpty
            ? _providerOutputModalities
            : const [OutputModality.text],
      );

  Widget _buildModelContextWindowDetail() {
    final contextWindowTokens = _resolvedContextWindowTokens;
    final value =
        contextWindowTokens == null
            ? S.of(context).statusUnknown
            : '${NumberFormat.decimalPattern(Localizations.localeOf(context).toString()).format(contextWindowTokens)} '
                '${S.of(context).tokens}';
    return _buildDetailValue(
      key: const ValueKey<String>('bot-detail-model-context-window'),
      label: S.of(context).modelContextWindow,
      icon: Icons.data_array_rounded,
      value: value,
    );
  }

  Widget _buildModelModalitiesDetail({
    required Key key,
    required String label,
    required IconData icon,
    required Widget value,
  }) {
    return _buildDetailValue(
      key: key,
      label: label,
      icon: icon,
      value: '',
      valueWidget: value,
    );
  }

  Widget _buildModelCapabilityDetail({
    required Key key,
    required String label,
    required IconData icon,
    required bool? supported,
  }) {
    return _buildDetailValue(
      key: key,
      label: label,
      icon: icon,
      value:
          supported == null
              ? S.of(context).statusUnknown
              : supported
              ? S.of(context).supported
              : S.of(context).notSupported,
    );
  }

  Widget _buildProviderInput(double? fontSize) {
    if (widget.readOnly) {
      return _buildDetailValue(
        key: const ValueKey<String>('bot-detail-provider'),
        label: S.of(context).provider,
        icon: Icons.business_outlined,
        value: providerController.text,
      );
    }
    if (widget.embedded) {
      return _buildDesktopInput(
        key: const ValueKey<String>('desktop-bot-provider'),
        label: S.of(context).provider,
        icon: Icons.business_outlined,
        controller: providerController,
        readOnly: true,
      );
    }
    return TextField(
      controller: providerController,
      readOnly: widget.readOnly,
      onChanged:
          widget.readOnly
              ? null
              : (value) => setState(() => selectedProvider = value),
      decoration: _fieldDecoration(
        label: S.of(context).provider,
        icon: Icons.business_outlined,
      ),
    );
  }

  Widget _buildApiTypeInput(double? fontSize) {
    if (widget.readOnly) {
      return _buildDetailValue(
        key: const ValueKey<String>('bot-detail-api-type'),
        label: S.of(context).apiType,
        icon: Icons.category_outlined,
        value: apiTypeController.text,
      );
    }
    if (widget.embedded) {
      return _buildDesktopInput(
        key: const ValueKey<String>('desktop-bot-api-type'),
        label: S.of(context).apiType,
        icon: Icons.category_outlined,
        controller: apiTypeController,
        readOnly: true,
      );
    }
    return TextField(
      controller: apiTypeController,
      readOnly: widget.readOnly,
      decoration: _fieldDecoration(
        label: S.of(context).apiType,
        icon: Icons.category_outlined,
      ),
    );
  }

  Widget _buildApiAddressInput(double? fontSize) {
    if (widget.readOnly) {
      return _buildDetailValue(
        key: const ValueKey<String>('bot-detail-base-url'),
        label: S.of(context).apiAddress,
        icon: Icons.link_rounded,
        value: baseURLController.text,
      );
    }
    if (widget.embedded) {
      return _buildDesktopInput(
        key: const ValueKey<String>('desktop-bot-base-url'),
        label: S.of(context).apiAddress,
        icon: Icons.link_rounded,
        controller: baseURLController,
        readOnly: true,
      );
    }
    return TextField(
      controller: baseURLController,
      readOnly: widget.readOnly,
      decoration: _fieldDecoration(
        label: S.of(context).apiAddress,
        icon: Icons.link_rounded,
      ),
    );
  }

  Widget _buildApiKeyInput(double? fontSize) {
    if (widget.readOnly) return _buildDetailApiKey();
    if (widget.embedded) {
      return _buildDesktopInput(
        key: const ValueKey<String>('desktop-bot-api-key'),
        label: S.of(context).apiKey,
        icon: LucideIcons.keyRound,
        controller: apiKeyController,
        obscureText: !_isPasswordVisible,
        isSensitive: true,
        onChanged: _markUnsaved,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _desktopInputAction(
              tooltip: S.of(context).copyApiKey,
              icon: LucideIcons.copy,
              onPressed:
                  apiKeyController.text.isEmpty
                      ? null
                      : () => Clipboard.setData(
                        ClipboardData(text: apiKeyController.text),
                      ),
            ),
            _desktopInputAction(
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
          ],
        ),
      );
    }
    return TextField(
      controller: apiKeyController,
      obscureText: !_isPasswordVisible,
      keyboardType: TextInputType.visiblePassword,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      readOnly: widget.readOnly,
      onChanged: _markUnsaved,
      decoration: _fieldDecoration(
        label: S.of(context).apiKey,
        icon: Icons.key_outlined,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: S.of(context).copyApiKey,
              icon: const Icon(Icons.copy_outlined, size: 17),
              onPressed:
                  apiKeyController.text.isEmpty
                      ? null
                      : () => Clipboard.setData(
                        ClipboardData(text: apiKeyController.text),
                      ),
            ),
            IconButton(
              tooltip:
                  _isPasswordVisible
                      ? S.of(context).hideApiKey
                      : S.of(context).showApiKey,
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelsInput(double? fontSize) {
    if (widget.readOnly) {
      return _buildDetailValue(
        key: const ValueKey<String>('bot-detail-model'),
        label: S.of(context).model,
        icon: Icons.memory_outlined,
        value: selectedModelController.text,
      );
    }
    if (widget.embedded) {
      return _buildDesktopInput(
        key: const ValueKey<String>('desktop-bot-model'),
        label: S.of(context).model,
        icon: Icons.memory_outlined,
        controller: selectedModelController,
        readOnly: true,
      );
    }
    return TextField(
      controller: selectedModelController,
      readOnly: widget.readOnly,
      onChanged: (value) {
        final stillSelectedModel = value.trim() == widget.bot.model;
        setState(() {
          _modelSupportsMcp = stillSelectedModel && _initialModelSupportsMcp;
          _modelSupportsAutomaticSkillActivation =
              stillSelectedModel &&
              _initialModelSupportsAutomaticSkillActivation;
          _skillViewModel?.updateSupportsAutoActivation(
            _modelSupportsAutomaticSkillActivation,
          );
          _editRevision += 1;
          _isSaved = false;
        });
      },
      decoration: _fieldDecoration(
        label: S.of(context).model,
        icon: Icons.memory_outlined,
      ),
    );
  }

  Widget _buildMcpToolPicker() {
    return BotMcpToolPicker(
      servers: _mcpServers,
      toolsByServer: _mcpToolsByServer,
      selectedServerIds: _mcpServerIds,
      configurations: _mcpToolConfigurations,
      isLoading: _isLoadingMcpServers,
      embedded: widget.embedded,
      readOnly: widget.readOnly,
      onSelectedServerIdsChanged: (serverIds) {
        setState(() {
          _mcpServerIds = serverIds;
          _editRevision += 1;
          _isSaved = false;
        });
      },
      onChanged: (configurations) {
        setState(() {
          _mcpToolConfigurations = configurations;
          _editRevision += 1;
          _isSaved = false;
        });
      },
    );
  }

  Widget _buildSystemPromptInput(double? fontSize) {
    if (widget.readOnly) {
      return _buildDetailValue(
        key: const ValueKey<String>('bot-detail-system-prompt'),
        label: S.of(context).systemPrompt.replaceAll(':', ''),
        icon: Icons.subject_rounded,
        value: systemPromptController.text,
        textAlign: TextAlign.start,
        valueOnNewLine: true,
      );
    }
    if (widget.embedded) {
      return _buildDesktopTextarea(
        label: S.of(context).systemPrompt.replaceAll(':', ''),
        icon: Icons.subject_rounded,
        controller: systemPromptController,
        placeholder: S.of(context).enterSystemPrompt,
        readOnly: widget.readOnly,
        onChanged: widget.readOnly ? null : _markUnsaved,
      );
    }
    return TextField(
      controller: systemPromptController,
      readOnly: widget.readOnly,
      decoration: _fieldDecoration(
        label: S.of(context).systemPrompt.replaceAll(':', ''),
        icon: Icons.subject_rounded,
        hintText: S.of(context).enterSystemPrompt,
      ),
      minLines: 4,
      maxLines: 8,
    );
  }
}
