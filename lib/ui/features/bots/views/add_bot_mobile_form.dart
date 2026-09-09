part of 'add_bot.dart';

// State mutations remain owned by the host State object in this library part.
// ignore_for_file: invalid_use_of_protected_member

extension _AddBotMobileForm on _AddBotPageState {
  Widget _buildNameInput(double? fontSize) {
    return TextField(
      controller: nameController,
      decoration: InputDecoration(
        hintText: S.of(context).enterBotName,
        hintStyle: TextStyle(
          fontSize: fontSize,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        prefixIcon: Icon(
          Icons.smart_toy_rounded,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  // 构建提供商选择器
  Widget _buildProviderInput(double? fontSize) {
    return TextField(
      controller: providerController,
      onChanged: (value) {
        setState(() {
          _isCustomProvider = !providersInfo.keys.contains(value);
          providerModels = [];
          selectedModelController.text = '';
        });
      },
      decoration: InputDecoration(
        hintText: S.of(context).selectProvider,
        hintStyle: TextStyle(
          fontSize: fontSize,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        prefixIcon: Icon(
          Icons.business_rounded,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        suffixIcon: IconButton(
          icon: Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onPressed: () {
            _showProvidersOptions(fontSize);
          },
        ),
      ),
    );
  }

  void _showProvidersOptions(double? fontSize) {
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
                        S.of(context).selectProvider,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: RadioGroup<String>(
                      groupValue: providerController.text,
                      onChanged: (value) {
                        _onProviderChanged(value);
                        Navigator.pop(context);
                      },
                      child: Scrollbar(
                        thumbVisibility: true,
                        thickness: 6.0,
                        radius: const Radius.circular(10.0),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                providersInfo.keys.map((provider) {
                                  return RadioListTile<String>(
                                    title: Row(
                                      children: [
                                        buildProviderLogo(
                                          context,
                                          '',
                                          provider,
                                          24,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(provider),
                                      ],
                                    ),
                                    activeColor:
                                        Theme.of(context).colorScheme.onSurface,
                                    value: provider,
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }

  // 构建提供商选择器
  Widget _buildSubProviderInput(double? fontSize) {
    return TextField(
      controller: subProviderController,
      onChanged: (value) {
        setState(() {
          _isCustomProvider = providersInfo.keys.contains(value);
          providerModels = [];
          selectedModelController.text = '';
        });
      },
      decoration: InputDecoration(
        hintText: S.of(context).selectProvider,
        hintStyle: TextStyle(
          fontSize: fontSize,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        prefixIcon: Icon(
          Icons.business_rounded,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        suffixIcon: IconButton(
          icon: Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onPressed: () {
            _showSubProvidersOptions(fontSize);
          },
        ),
      ),
    );
  }

  void _showSubProvidersOptions(double? fontSize) {
    final subProviders =
        providersInfo[providerController.text]?['sub_providers']
            as Map<String, Object>;
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
                        S.of(context).selectProvider,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: RadioGroup<String>(
                      groupValue: subProviderController.text,
                      onChanged: (value) {
                        _onSubProviderChanged(value);
                        Navigator.pop(context);
                      },
                      child: Scrollbar(
                        thumbVisibility: true,
                        thickness: 6.0,
                        radius: const Radius.circular(10.0),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                subProviders.keys.map((subProvider) {
                                  return RadioListTile<String>(
                                    title: Row(
                                      children: [
                                        buildProviderLogo(
                                          context,
                                          '',
                                          subProvider,
                                          24,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(subProvider),
                                      ],
                                    ),
                                    activeColor:
                                        Theme.of(context).colorScheme.onSurface,
                                    value: subProvider,
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildApiTypeSelector(double? fontSize) {
    return TextField(
      controller: apiTypeController,
      decoration: InputDecoration(
        hintText: S.of(context).apiType,
        hintStyle: TextStyle(
          fontSize: fontSize,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        prefixIcon: Icon(
          Icons.category_rounded,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        suffixIcon: IconButton(
          icon: Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onPressed: () {
            _showApiTypeOptions(fontSize);
          },
        ),
        enabled: _isCustomProvider,
      ),
    );
  }

  void _showApiTypeOptions(double? fontSize) {
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
                        S.of(context).apiType,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: RadioGroup<String>(
                      groupValue: apiTypeController.text,
                      onChanged: (value) {
                        if (value == null) return;
                        apiTypeController.text = value;
                        Navigator.pop(context);
                      },
                      child: Scrollbar(
                        thumbVisibility: true,
                        thickness: 6.0,
                        radius: const Radius.circular(10.0),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                Bot.getAllApiTypes().map((apiType) {
                                  return RadioListTile<String>(
                                    title: Text(apiType),
                                    activeColor:
                                        Theme.of(context).colorScheme.onSurface,
                                    value: apiType,
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildApiAddressInput(double? fontSize) {
    return TextField(
      controller: baseURLController,
      decoration: InputDecoration(
        hintText: S.of(context).apiAddress,
        hintStyle: TextStyle(
          fontSize: fontSize,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        prefixIcon: Icon(
          Icons.link_rounded,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  // 构建API密钥输入框
  Widget _buildApiKeyInput(double? fontSize) {
    return TextField(
      controller: apiKeyController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: S.of(context).apiKey,
        hintStyle: TextStyle(
          fontSize: fontSize,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        prefixIcon: Icon(
          Icons.key_rounded,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
    );
  }

  Widget _buildModelsInput(double? fontSize) {
    return TextField(
      controller: selectedModelController,
      decoration: InputDecoration(
        hintText: S.of(context).selectModel,
        hintStyle: TextStyle(
          fontSize: fontSize,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        prefixIcon: Icon(
          Icons.auto_awesome_rounded,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        suffixIcon:
            providerModels.isEmpty
                ? _isLoadingModels
                    ? Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.all(16),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                    : IconButton(
                      icon: Icon(Icons.refresh_rounded),
                      onPressed: () {
                        _fetchModels();
                      },
                    )
                : IconButton(
                  icon: Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onPressed: () {
                    _showModelsOptions(fontSize);
                  },
                ),
      ),
    );
  }

  void _showModelsOptions(double? fontSize) {
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
                        S.of(context).selectModel,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (_isLoadingModels)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Flexible(
                      child: RadioGroup<AiModelInfo>(
                        groupValue: _modelInfoById(
                          selectedModelController.text,
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(
                            () => selectedModelController.text = value.modelId,
                          );
                          Navigator.pop(context);
                        },
                        child: Scrollbar(
                          thumbVisibility: true,
                          thickness: 6.0,
                          radius: const Radius.circular(10.0),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children:
                                  providerModels.isEmpty
                                      ? [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            S.of(context).noModelsRetrieved,
                                          ),
                                        ),
                                      ]
                                      : providerModels.map((model) {
                                        return RadioListTile<AiModelInfo>(
                                          title: Text(model.modelId),
                                          activeColor:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                          value: model,
                                        );
                                      }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }

  AiModelInfo? _modelInfoById(String modelId) {
    for (final model in providerModels) {
      if (model.modelId == modelId) return model;
    }
    return null;
  }

  bool get _selectedModelSupportsMcp =>
      _modelInfoById(selectedModelController.text)?.supportsMcp == true;

  Widget _buildMcpServerPicker() {
    return BotMcpToolPicker(
      servers: _mcpServers,
      toolsByServer: _mcpToolsByServer,
      selectedServerIds: _mcpServerIds,
      configurations: _mcpToolConfigurations,
      isLoading: _isLoadingMcpServers,
      embedded: widget.embedded,
      onSelectedServerIdsChanged: (serverIds) {
        setState(() => _mcpServerIds = serverIds);
      },
      onChanged: (configurations) {
        setState(() => _mcpToolConfigurations = configurations);
      },
    );
  }

  bool get _selectedModelSupportsAutomaticSkillActivation {
    final model = _modelInfoById(selectedModelController.text);
    if (model?.supportsAutomaticSkillActivation != true) return false;
    final dependencies = AppScope.maybeOf(context);
    if (dependencies == null) return true;
    final providerInfo = providersInfo[providerController.text];
    final apiType =
        (providerInfo?['api_type'] as String?) ?? apiTypeController.text.trim();
    if (apiType.isEmpty) return false;
    try {
      final provider = dependencies.aiProviderRepository.create(
        Bot(
          id: _botId,
          name: '',
          avatar: '',
          provider: providerController.text,
          baseURL: baseURLController.text.trim(),
          apiKey: apiKeyController.text.trim(),
          apiType: apiType,
          model: selectedModelController.text,
          systemPrompt: '',
          createTimestamp: DateTime.now(),
          modifyTimestamp: DateTime.now(),
        ),
      );
      return provider.capabilities.supportsAutomaticSkillActivation;
    } on UnsupportedError {
      return false;
    }
  }

  void _syncSelectedModelSkillSupport() {
    final viewModel = widget.skillViewModel;
    if (viewModel == null) return;

    final model = _modelInfoById(selectedModelController.text);
    if (model?.supportsAutomaticSkillActivation != true) {
      viewModel.updateSupportsAutoActivation(false);
      return;
    }

    final dependencies = AppScope.maybeOf(context);
    if (dependencies == null) {
      viewModel.updateSupportsAutoActivation(true);
      return;
    }

    final providerInfo = providersInfo[providerController.text];
    final apiType =
        (providerInfo?['api_type'] as String?) ?? apiTypeController.text.trim();
    if (apiType.isEmpty) {
      viewModel.updateSupportsAutoActivation(false);
      return;
    }

    try {
      final provider = dependencies.aiProviderRepository.create(
        Bot(
          id: _botId,
          name: '',
          avatar: '',
          provider: providerController.text,
          baseURL: baseURLController.text.trim(),
          apiKey: apiKeyController.text.trim(),
          apiType: apiType,
          model: selectedModelController.text,
          systemPrompt: '',
          createTimestamp: DateTime.now(),
          modifyTimestamp: DateTime.now(),
        ),
      );
      viewModel.updateSupportsAutoActivation(
        provider.capabilities.supportsAutomaticSkillActivation,
      );
    } on UnsupportedError {
      viewModel.updateSupportsAutoActivation(false);
    }
  }

  Widget _buildSystemPromptInput(double? fontSize) {
    return TextField(
      controller: systemPromptController,
      decoration: InputDecoration(
        hintText: S.of(context).systemPrompt,
        hintStyle: TextStyle(fontSize: fontSize),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      maxLines: 6,
    );
  }
}
