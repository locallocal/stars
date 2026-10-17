import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/models/provider_catalog.dart';
import 'package:stars/domain/use_cases/bot_commands.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/core/widgets/logo.dart';
import 'package:stars/ui/features/bots/view_models/bot_skill_view_model.dart';
import 'package:stars/ui/features/bots/view_models/bot_form_view_model.dart';
import 'package:stars/ui/features/bots/views/add_bot_skills.dart';
import 'package:stars/ui/features/bots/views/bot_mcp_tool_picker.dart';
import 'package:stars/utils/theme.dart';

part 'add_bot_desktop_form.dart';
part 'add_bot_mobile_form.dart';

class AddBotDialog extends StatelessWidget {
  const AddBotDialog({
    super.key,
    required this.onBotAdded,
    this.modelLoader,
    this.avatarPicker,
    this.botId,
    this.skillViewModel,
    this.mcpCatalogLoader,
  });

  final Future<void> Function(Bot, List<BotSkillBinding>) onBotAdded;
  final Future<List<AiModelInfo>> Function(Bot)? modelLoader;
  final Future<String?> Function()? avatarPicker;
  final String? botId;
  final BotSkillViewModel? skillViewModel;
  final Future<BotMcpCatalog> Function()? mcpCatalogLoader;

  @override
  Widget build(BuildContext context) {
    final windowSize = MediaQuery.sizeOf(context);
    final inset =
        windowSize.width < 900 || windowSize.height < 760 ? 16.0 : 24.0;
    final dialogWidth =
        (windowSize.width - inset * 2).clamp(0.0, 840.0).toDouble();
    final dialogHeight =
        (windowSize.height - inset * 2).clamp(0.0, 720.0).toDouble();

    return ShadDialog(
      constraints: BoxConstraints.tightFor(
        width: dialogWidth,
        height: dialogHeight,
      ),
      padding: EdgeInsets.zero,
      gap: 0,
      scrollable: false,
      useSafeArea: false,
      removeBorderRadiusWhenTiny: false,
      closeIcon: const SizedBox.shrink(),
      child: SizedBox(
        key: const ValueKey<String>('add-bot-dialog-content'),
        width: dialogWidth,
        height: dialogHeight,
        child: AddBotPage(
          embedded: true,
          onBotAdded: onBotAdded,
          modelLoader: modelLoader,
          avatarPicker: avatarPicker,
          botId: botId,
          skillViewModel: skillViewModel,
          mcpCatalogLoader: mcpCatalogLoader,
        ),
      ),
    );
  }
}

class AddBotPage extends StatefulWidget {
  final Future<void> Function(Bot, List<BotSkillBinding>) onBotAdded;
  final Future<List<AiModelInfo>> Function(Bot)? modelLoader;
  final Future<String?> Function()? avatarPicker;
  final bool embedded;
  final String? botId;
  final BotSkillViewModel? skillViewModel;
  final Future<BotMcpCatalog> Function()? mcpCatalogLoader;

  const AddBotPage({
    super.key,
    required this.onBotAdded,
    this.modelLoader,
    this.avatarPicker,
    this.embedded = false,
    this.botId,
    this.skillViewModel,
    this.mcpCatalogLoader,
  });

  @override
  State<AddBotPage> createState() => _AddBotPageState();
}

class _AddBotPageState extends State<AddBotPage> {
  static const double _desktopFieldWidth =
      StarsDesktopThemeSpec.addBotFormFieldWidth;
  static const double _desktopProviderMenuWidth = 256;
  static const double _desktopModelMenuWidth = 320;
  static const double _desktopSectionPadding =
      StarsDesktopThemeSpec.botFormSectionPadding;
  static const double _desktopSectionBorderWidth =
      StarsDesktopThemeSpec.botFormSectionBorderWidth;
  static const double _desktopFormWidth =
      _desktopFieldWidth +
      _desktopSectionPadding * 2 +
      _desktopSectionBorderWidth * 2;
  static const BoxConstraints _desktopInputConstraints = BoxConstraints(
    minHeight: StarsDesktopThemeSpec.botFormFieldHeight,
  );

  final _desktopFormKey = GlobalKey<ShadFormState>();
  final _desktopScrollController = ScrollController();
  final nameController = TextEditingController();
  final providerController = TextEditingController(text: 'OpenAI');
  final subProviderController = TextEditingController(text: 'HF-Inference');
  final apiTypeController = TextEditingController();
  final baseURLController = TextEditingController();
  final apiKeyController = TextEditingController();
  final selectedModelController = TextEditingController();
  final systemPromptController = TextEditingController();
  late final String _botId;

  bool _isLoadingModels = false;
  bool _isSubmitting = false;
  bool _isCustomProvider = false;
  bool _isSyncingProviderFields = false;
  bool _isPasswordVisible = false;
  File? avatarImage;
  List<AiModelInfo> providerModels = [];
  List<McpServer> _mcpServers = const [];
  Map<String, List<McpToolDescriptor>> _mcpToolsByServer = const {};
  Set<String> _mcpServerIds = const {};
  Set<McpToolConfiguration> _mcpToolConfigurations = const {};
  bool _isLoadingMcpServers = false;
  bool _startedLoadingMcpServers = false;
  BotFormViewModel? _formViewModel;

  Future<void> _pickImage() async {
    try {
      final imagePath = await widget.avatarPicker?.call();

      if (imagePath != null && mounted) {
        setState(() {
          avatarImage = File(imagePath);
        });
      }
    } on Object catch (error) {
      if (mounted) _showError(safeFailureMessage(context, error));
    }
  } // 添加加载状态变量

  void _showError(String message) {
    if (!mounted) return;
    showStarsNotice(context, message.trim(), tone: StarsNoticeTone.error);
  }

  // 添加获取模型列表的方法
  Future<void> _fetchModels() async {
    if (apiKeyController.text.trim().isEmpty) {
      _showError(S.of(context).pleaseEnterApiKey);
      return;
    }
    if (baseURLController.text.trim().isEmpty) {
      _showError(S.of(context).enterApiAddress);
      return;
    }
    setState(() {
      _isLoadingModels = true;
    });

    try {
      final apiType = apiTypeController.text.trim();
      final baseURL = baseURLController.text.trim(); // 使用baseURLController的值

      final now = DateTime.now();
      final tempBot = const BuildBot()(
        BotDraft(
          id: 'temp_bot',
          name: 'Temp Bot',
          avatar: '',
          provider: providerController.text,
          baseUrl: baseURL,
          apiKey: apiKeyController.text,
          apiType: apiType,
          model: '',
          systemPrompt: '',
          supportsMcp: false,
          supportsAutomaticSkillActivation: false,
          mcpServerIds: const {},
          mcpTools: const {},
          createdAt: now,
          modifiedAt: now,
        ),
      );

      final modelLoader = widget.modelLoader;
      if (modelLoader == null) {
        throw StateError('No AI provider model loader was injected.');
      }
      final models = await modelLoader(tempBot);
      if (models.isNotEmpty && mounted) {
        setState(() {
          providerModels = models;
          selectedModelController.text = models.first.modelId;
        });
      } else if (mounted) {
        _showError(S.of(context).noModelsRetrieved);
      }
    } on Object catch (error) {
      if (mounted) _showError(safeFailureMessage(context, error));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _botId = widget.botId ?? 'bot_${DateTime.now().millisecondsSinceEpoch}';
    selectedModelController.addListener(_syncSelectedModelSkillSupport);
    if (widget.embedded && widget.skillViewModel != null) {
      unawaited(widget.skillViewModel!.load());
    }
    // 初始化baseURLController
    baseURLController.text =
        providersInfo[providerController.text]?['base_url'] as String? ?? '';
    apiTypeController.text =
        providersInfo[providerController.text]?['api_type'] as String? ?? '';
    // 使用国际化字符串初始化系统提示词
    WidgetsBinding.instance.addPostFrameCallback((_) {
      systemPromptController.text = S.of(context).defaultSystemPrompt;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_startedLoadingMcpServers) {
      final dependencies = AppScope.maybeOf(context);
      _formViewModel ??= dependencies?.createBotFormViewModel();
      final loader = widget.mcpCatalogLoader ?? _formViewModel?.loadMcpCatalog;
      if (loader != null) {
        _startedLoadingMcpServers = true;
        unawaited(_loadMcpCatalog(loader));
      }
    }
    _syncSelectedModelSkillSupport();
  }

  Future<void> _loadMcpCatalog(Future<BotMcpCatalog> Function() loader) async {
    setState(() => _isLoadingMcpServers = true);
    try {
      final catalog = await loader();
      if (!mounted) return;
      setState(() {
        _mcpServers = List<McpServer>.unmodifiable(
          List<McpServer>.of(catalog.servers)
            ..sort((left, right) => left.name.compareTo(right.name)),
        );
        _mcpToolsByServer = Map<String, List<McpToolDescriptor>>.unmodifiable({
          for (final entry in catalog.toolsByServer.entries)
            entry.key: List<McpToolDescriptor>.unmodifiable(entry.value),
        });
      });
    } on Object {
      if (mounted) {
        setState(() {
          _mcpServers = const [];
          _mcpToolsByServer = const {};
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingMcpServers = false);
    }
  }

  @override
  void dispose() {
    // 释放控制器资源
    _desktopScrollController.dispose();
    nameController.dispose();
    apiKeyController.dispose();
    baseURLController.dispose();
    systemPromptController.dispose();
    providerController.dispose();
    subProviderController.dispose();
    apiTypeController.dispose();
    selectedModelController.removeListener(_syncSelectedModelSkillSupport);
    selectedModelController.dispose();
    super.dispose();
  }

  // 修改onChanged方法
  void _onProviderChanged(String? value) {
    if (value == null) return;
    if (providerController.text == value) {
      _handleProviderTextChanged(value);
    } else {
      providerController.text = value;
    }
  }

  void _onSubProviderChanged(String? value) {
    if (value == null) return;
    if (subProviderController.text == value) {
      _handleSubProviderTextChanged(value);
    } else {
      subProviderController.text = value;
    }
  }

  void _handleProviderTextChanged(String value) {
    if (_isSyncingProviderFields) return;

    final providerInfo = providersInfo[value];
    setState(() {
      _isSyncingProviderFields = true;
      try {
        _isCustomProvider = providerInfo == null;
        if (providerInfo != null) {
          apiTypeController.text = providerInfo['api_type'] as String? ?? '';

          if (value == 'HuggingFace') {
            final subProviders =
                providerInfo['sub_providers'] as Map<String, Map>;
            if (subProviders.isNotEmpty) {
              final selectedSubProvider =
                  subProviders.containsKey(subProviderController.text)
                      ? subProviderController.text
                      : subProviders.keys.first;
              subProviderController.text = selectedSubProvider;
              baseURLController.text =
                  subProviders[selectedSubProvider]?['base_url'] as String? ??
                  '';
            } else {
              baseURLController.text =
                  providerInfo['base_url'] as String? ?? '';
            }
          } else {
            baseURLController.text = providerInfo['base_url'] as String? ?? '';
          }
        }
        providerModels = [];
        selectedModelController.text = '';
      } finally {
        _isSyncingProviderFields = false;
      }
    });
  }

  void _handleSubProviderTextChanged(String value) {
    if (_isSyncingProviderFields) return;

    final subProviders =
        providersInfo[providerController.text]?['sub_providers']
            as Map<String, Map>;
    setState(() {
      _isCustomProvider = !subProviders.containsKey(value);
      if (!_isCustomProvider) {
        baseURLController.text =
            subProviders[value]?['base_url'] as String? ?? '';
      }
      providerModels = [];
      selectedModelController.text = '';
    });
  }

  Future<void> _submitBot() async {
    if (_isSubmitting) return;

    final desktopFormValid =
        !widget.embedded ||
        (_desktopFormKey.currentState?.saveAndValidate() ?? false);
    if (!desktopFormValid) {
      _showError(S.of(context).fillRequiredFields);
      return;
    }

    if (!widget.embedded &&
        (nameController.text.trim().isEmpty ||
            apiKeyController.text.trim().isEmpty ||
            baseURLController.text.trim().isEmpty)) {
      _showError(S.of(context).fillRequiredFields);
      return;
    }

    final navigator = Navigator.of(context);
    final providerInfo = providersInfo[providerController.text];
    final apiType =
        (providerInfo?['api_type'] as String?) ?? apiTypeController.text.trim();
    final baseURL = baseURLController.text.trim();
    final selectedModelInfo = _modelInfoById(selectedModelController.text);

    final now = DateTime.now();
    final newBot = const BuildBot()(
      BotDraft(
        id: _botId,
        name: nameController.text,
        avatar: avatarImage?.path ?? '',
        provider: providerController.text,
        baseUrl: baseURL,
        apiKey: apiKeyController.text,
        apiType: apiType,
        model: selectedModelController.text,
        systemPrompt: systemPromptController.text,
        supportsMcp: _selectedModelSupportsMcp,
        supportsAutomaticSkillActivation:
            _selectedModelSupportsAutomaticSkillActivation,
        supportsSkills: selectedModelInfo?.supportsSkills,
        contextWindowTokens: selectedModelInfo?.contextWindowTokens,
        inputModalities: selectedModelInfo?.inputModalities ?? const [],
        outputModalities: selectedModelInfo?.outputModalities ?? const [],
        mcpServerIds: _mcpServerIds,
        mcpTools: _mcpToolConfigurations,
        createdAt: now,
        modifiedAt: now,
      ),
    );

    setState(() => _isSubmitting = true);
    try {
      await widget.onBotAdded(
        newBot,
        widget.embedded
            ? widget.skillViewModel?.bindings ?? const []
            : const [],
      );
      if (!widget.embedded && mounted) {
        navigator.pop();
      }
    } on Object catch (error) {
      if (mounted) _showError(safeFailureMessage(context, error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;

    if (widget.embedded) {
      return _buildEmbeddedDesktop(context);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          S.of(context).addBot,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 64,
                      backgroundColor:
                          avatarImage == null
                              ? getFrostedProviderColor(
                                providerController.text,
                                Theme.of(context).colorScheme.primary,
                              )
                              : Theme.of(context).colorScheme.primary,
                      backgroundImage:
                          avatarImage != null ? FileImage(avatarImage!) : null,
                      child:
                          avatarImage == null
                              ? buildProviderLogo(
                                context,
                                '',
                                providerController.text,
                                64,
                              )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 基本信息分组
                buildSectionContainer(context, S.of(context).basicInformation, [
                  _buildNameInput(fontSize),
                ]),
                const SizedBox(height: 16),

                // API提供商分组
                buildSectionContainer(
                  context,
                  S.of(context).providerInformation,
                  [
                    _buildProviderInput(fontSize),
                    if (providerController.text == 'HuggingFace')
                      _buildSubProviderInput(fontSize),

                    _buildApiTypeSelector(fontSize),
                    _buildApiAddressInput(fontSize),
                    _buildApiKeyInput(fontSize),
                  ],
                ),
                const SizedBox(height: 16),

                // API提供商分组
                buildSectionContainer(
                  context,
                  S.of(context).modelConfiguration,
                  [
                    _buildModelsInput(fontSize),
                    _buildSystemPromptInput(fontSize),
                  ],
                ),
                if (_selectedModelSupportsMcp) ...[
                  const SizedBox(height: 16),
                  buildSectionContainer(context, S.of(context).mcpServers, [
                    _buildMcpServerPicker(),
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.onSurface,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
              side: BorderSide.none,
            ),
          ),
          onPressed: _isSubmitting ? null : _submitBot,
          child:
              _isSubmitting
                  ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(
                    S.of(context).addBot,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
        ),
      ),
    );
  }
}
