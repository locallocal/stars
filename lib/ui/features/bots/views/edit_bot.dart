import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/models/provider_catalog.dart';
import 'package:stars/domain/use_cases/bot_commands.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/core/view_models/token_usage_timeline.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/core/widgets/logo.dart';
import 'package:stars/ui/core/widgets/model_modalities.dart';
import 'package:stars/ui/core/widgets/token_usage_indicator.dart';
import 'package:stars/ui/features/bots/view_models/bot_token_usage_view_model.dart';
import 'package:stars/ui/features/bots/view_models/bot_skill_view_model.dart';
import 'package:stars/ui/features/bots/view_models/bot_form_view_model.dart';
import 'package:stars/ui/features/bots/views/bot_mcp_tool_picker.dart';
import 'package:stars/ui/features/bots/views/bot_token_usage.dart';
import 'package:stars/ui/features/bots/views/skill_description_test_dialog.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';

part 'edit_bot_skills.dart';
part 'edit_bot_commands.dart';
part 'edit_bot_inputs.dart';

class EditBotPage extends StatefulWidget {
  final Bot bot;
  final Future<void> Function(Bot) onBotUpdated;
  final Future<void> Function() onBotDeleted;
  final Future<String?> Function()? avatarPicker;
  final bool embedded;
  final bool readOnly;
  final BotSkillViewModel? skillViewModel;
  final Future<BotMcpCatalog> Function()? mcpCatalogLoader;

  const EditBotPage({
    super.key,
    required this.bot,
    required this.onBotUpdated,
    required this.onBotDeleted,
    this.avatarPicker,
    this.embedded = false,
    this.readOnly = false,
    this.skillViewModel,
    this.mcpCatalogLoader,
  });

  @override
  State<EditBotPage> createState() => _EditAIBotPageState();
}

class _EditAIBotPageState extends State<EditBotPage> {
  final _skillSearchController = TextEditingController();
  late final TextEditingController nameController;
  late final TextEditingController providerController;
  late final TextEditingController apiTypeController;
  late final TextEditingController apiKeyController;
  late final TextEditingController baseURLController;
  late final TextEditingController selectedModelController;
  late final TextEditingController systemPromptController;

  late String selectedProvider;
  late String selectedModel;
  bool _isPasswordVisible = false;
  bool _isSaving = false;
  bool _isSaved = false;
  bool _isDeleting = false;
  AppFailure? _commandFailure;
  int _editRevision = 0;
  File? avatarImage;
  BotTokenUsageViewModel? _tokenUsageViewModel;
  BotSkillViewModel? _skillViewModel;
  bool _ownsSkillViewModel = false;
  List<McpServer> _mcpServers = const [];
  Map<String, List<McpToolDescriptor>> _mcpToolsByServer = const {};
  late Set<String> _mcpServerIds;
  late Set<McpToolConfiguration> _mcpToolConfigurations;
  late bool _modelSupportsMcp;
  late bool _initialModelSupportsMcp;
  late bool _modelSupportsAutomaticSkillActivation;
  late bool _initialModelSupportsAutomaticSkillActivation;
  bool _isLoadingMcpServers = false;
  bool _startedLoadingMcpServers = false;
  bool _resolvedInitialMcpCapability = false;
  bool _startedLoadingModelInfo = false;
  AiModelInfo? _modelInfo;
  List<InputModality> _providerInputModalities = const [InputModality.text];
  List<OutputModality> _providerOutputModalities = const [OutputModality.text];
  BotFormViewModel? _formViewModel;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.bot.name);
    providerController = TextEditingController(text: widget.bot.provider);
    apiTypeController = TextEditingController(text: widget.bot.apiType);
    apiKeyController = TextEditingController(text: widget.bot.apiKey);
    baseURLController = TextEditingController(text: widget.bot.baseURL);
    selectedModelController = TextEditingController(text: widget.bot.model);
    systemPromptController = TextEditingController(
      text: widget.bot.systemPrompt.isNotEmpty ? widget.bot.systemPrompt : '',
    );
    selectedProvider = widget.bot.provider;
    selectedModel = widget.bot.model;
    _mcpServerIds = widget.bot.mcpServerIds;
    _mcpToolConfigurations = widget.bot.mcpTools;
    _modelSupportsMcp = widget.bot.configuredSupportsMcp ?? false;
    _initialModelSupportsMcp = _modelSupportsMcp;
    _modelSupportsAutomaticSkillActivation =
        widget.bot.configuredSupportsAutomaticSkillActivation ?? false;
    _initialModelSupportsAutomaticSkillActivation =
        _modelSupportsAutomaticSkillActivation;
    if (widget.bot.avatar.isNotEmpty) {
      avatarImage = File(widget.bot.avatar);
    }
    final injectedSkillViewModel = widget.skillViewModel;
    if (injectedSkillViewModel != null) {
      _skillViewModel =
          injectedSkillViewModel..addListener(_handleSkillChanged);
      _modelSupportsAutomaticSkillActivation =
          injectedSkillViewModel.supportsAutoActivation;
      _initialModelSupportsAutomaticSkillActivation =
          _modelSupportsAutomaticSkillActivation;
      unawaited(injectedSkillViewModel.load());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dependencies = AppScope.maybeOf(context);
    _formViewModel ??= dependencies?.createBotFormViewModel();
    if (!_startedLoadingMcpServers) {
      final loader = widget.mcpCatalogLoader ?? _formViewModel?.loadMcpCatalog;
      if (loader != null) {
        _startedLoadingMcpServers = true;
        unawaited(_loadMcpCatalog(loader));
      }
    }
    if (dependencies == null) return;
    if (widget.readOnly &&
        !_startedLoadingModelInfo &&
        (widget.bot.configuredContextWindowTokens == null ||
            widget.bot.configuredSupportsSkills == null ||
            widget.bot.configuredSupportsMcp == null ||
            widget.bot.configuredInputModalities == null ||
            widget.bot.configuredOutputModalities == null)) {
      _startedLoadingModelInfo = true;
      unawaited(
        _loadModelInfo(() => _formViewModel!.loadModelInfo(widget.bot)),
      );
    }
    if (!_resolvedInitialMcpCapability) {
      _resolvedInitialMcpCapability = true;
      final capabilities = _formViewModel!.resolveCapabilities(widget.bot);
      final supportsMcp = capabilities.supportsMcp;
      _providerInputModalities = capabilities.inputModalities;
      _providerOutputModalities = capabilities.outputModalities;
      final supportsAutomaticSkillActivation =
          capabilities.supportsAutomaticSkillActivation;
      _initialModelSupportsMcp = supportsMcp;
      _initialModelSupportsAutomaticSkillActivation =
          supportsAutomaticSkillActivation;
      if (supportsMcp != _modelSupportsMcp) {
        _modelSupportsMcp = supportsMcp;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
      if (supportsAutomaticSkillActivation !=
          _modelSupportsAutomaticSkillActivation) {
        _modelSupportsAutomaticSkillActivation =
            supportsAutomaticSkillActivation;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    }
    if (widget.readOnly && _tokenUsageViewModel == null) {
      _tokenUsageViewModel = dependencies.createBotTokenUsageViewModel(
        widget.bot.id,
      )..addListener(_handleTokenUsageChanged);
      unawaited(_tokenUsageViewModel!.load());
    }
    if (_skillViewModel == null) {
      _ownsSkillViewModel = true;
      _skillViewModel = dependencies.createBotSkillViewModel(widget.bot)
        ..addListener(_handleSkillChanged);
      unawaited(_skillViewModel!.load());
    }
    _skillViewModel?.updateSupportsAutoActivation(
      _modelSupportsAutomaticSkillActivation,
    );
  }

  void _handleTokenUsageChanged() {
    if (mounted) setState(() {});
  }

  void _handleSkillChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadModelInfo(Future<AiModelInfo?> Function() loader) async {
    try {
      final modelInfo = await loader();
      if (mounted) setState(() => _modelInfo = modelInfo);
    } on Object {
      // Stored metadata remains available when the provider cannot be queried.
    }
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

  Future<void> _pickImage() async {
    if (widget.readOnly) return;
    final imagePath = await widget.avatarPicker?.call();

    if (imagePath != null && mounted) {
      setState(() {
        avatarImage = File(imagePath);
        _editRevision += 1;
        _isSaved = false;
      });
    }
  }

  @override
  void dispose() {
    _skillSearchController.dispose();
    nameController.dispose();
    providerController.dispose();
    apiTypeController.dispose();
    apiKeyController.dispose();
    baseURLController.dispose();
    selectedModelController.dispose();
    systemPromptController.dispose();
    _tokenUsageViewModel
      ?..removeListener(_handleTokenUsageChanged)
      ..dispose();
    _skillViewModel?.removeListener(_handleSkillChanged);
    if (_ownsSkillViewModel) _skillViewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    return Scaffold(
      key:
          widget.embedded
              ? const ValueKey<String>('desktop-bot-detail-scaffold')
              : null,
      backgroundColor:
          widget.embedded
              ? StarsDesktopThemeSpec.workspaceSurface(context)
              : null,
      appBar:
          widget.embedded
              ? null
              : AppBar(
                centerTitle: true,
                title: Text(
                  widget.readOnly
                      ? S.of(context).details
                      : S.of(context).editBot,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                scrolledUnderElevation: 0,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                actions: [if (!widget.readOnly) _buildDeleteButton(fontSize)],
              ),
      body: Center(
        child: ConstrainedBox(
          key:
              widget.embedded
                  ? const ValueKey<String>('desktop-bot-detail-content')
                  : null,
          constraints: BoxConstraints(
            maxWidth:
                widget.embedded
                    ? StarsDesktopThemeSpec.formContentMaxWidth +
                        StarsDesktopThemeSpec.formPagePadding.horizontal
                    : 800,
          ),
          child: SingleChildScrollView(
            padding:
                widget.embedded
                    ? StarsDesktopThemeSpec.formPagePadding
                    : const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_commandFailure case final failure?) ...[
                  StarsInlineErrorAlert(
                    error: safeFailureMessage(context, failure),
                    isDesktop: widget.embedded,
                    onDismiss: () => setState(() => _commandFailure = null),
                    alertKey: const ValueKey<String>('edit-bot-command-error'),
                  ),
                  const SizedBox(height: 8),
                ],
                if (providerMigrationFor(widget.bot) case final migration?) ...[
                  ShadAlert.destructive(
                    key: const ValueKey<String>('provider-migration-notice'),
                    icon: const Icon(LucideIcons.circleAlert),
                    title: Text(S.of(context).unavailableBot),
                    description: Text(
                      migration.replacementBaseUrl ??
                          migration.replacementApiType ??
                          migration.code,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (widget.embedded) ...[
                  Row(
                    children: [
                      ShadTooltip(
                        builder: (context) => Text(S.of(context).botAvatar),
                        child: ShadButton.ghost(
                          width: 56,
                          height: 56,
                          padding: EdgeInsets.zero,
                          enabled: !widget.readOnly,
                          onPressed: widget.readOnly ? null : _pickImage,
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                avatarImage == null
                                    ? getFrostedProviderColor(
                                      selectedProvider,
                                      Theme.of(context).colorScheme.primary,
                                    )
                                    : Theme.of(context).colorScheme.primary,
                            backgroundImage:
                                avatarImage != null
                                    ? FileImage(avatarImage!)
                                    : null,
                            child:
                                avatarImage == null
                                    ? buildProviderLogo(
                                      context,
                                      '',
                                      selectedProvider,
                                      28,
                                    )
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.bot.name,
                              style: StarsDesktopThemeSpec.pageTitleStyle(
                                context,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${widget.bot.provider} · ${widget.bot.model}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: StarsDesktopThemeSpec.metaStyle(context),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.readOnly) _buildDeleteButton(fontSize),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                // 头像选择
                if (!widget.embedded) ...[
                  Center(
                    child: GestureDetector(
                      onTap: widget.readOnly ? null : _pickImage,
                      child: CircleAvatar(
                        radius: 64,
                        backgroundColor:
                            avatarImage == null
                                ? getFrostedProviderColor(
                                  selectedProvider,
                                  Theme.of(context).colorScheme.primary,
                                )
                                : Theme.of(context).colorScheme.primary,
                        backgroundImage:
                            avatarImage != null
                                ? FileImage(avatarImage!)
                                : null,
                        child:
                            avatarImage == null
                                ? buildProviderLogo(
                                  context,
                                  '',
                                  selectedProvider,
                                  64,
                                )
                                : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 基本信息分组
                _buildFormSection(
                  context,
                  S.of(context).basicInformation,
                  [
                    _buildNameInput(fontSize),
                    if (widget.readOnly) ...[
                      _buildCreationTimeDetail(),
                      _buildModificationTimeDetail(),
                    ],
                  ],
                  sectionKey: const ValueKey<String>(
                    'desktop-bot-basic-section',
                  ),
                ),
                SizedBox(height: widget.embedded ? 20 : 16),

                // API提供商分组
                _buildFormSection(
                  context,
                  S.of(context).providerInformation,
                  [
                    _buildProviderInput(fontSize),
                    _buildApiTypeInput(fontSize),
                    _buildApiAddressInput(fontSize),
                    _buildApiKeyInput(fontSize),
                  ],
                  sectionKey: const ValueKey<String>(
                    'desktop-bot-provider-section',
                  ),
                ),
                SizedBox(height: widget.embedded ? 20 : 16),

                // API提供商分组
                _buildFormSection(
                  context,
                  S.of(context).modelConfiguration,
                  [
                    _buildModelsInput(fontSize),
                    if (widget.readOnly) ...[
                      _buildModelContextWindowDetail(),
                      _buildModelModalitiesDetail(
                        key: const ValueKey<String>(
                          'bot-detail-model-modalities-input',
                        ),
                        label: S.of(context).modelInputModalities,
                        icon: Icons.input_rounded,
                        value: ModelInputModalityIcons(
                          modalities: _resolvedInputModalities,
                          keyPrefix: 'bot-detail-input-modality',
                          alignment:
                              widget.embedded
                                  ? WrapAlignment.end
                                  : WrapAlignment.start,
                        ),
                      ),
                      _buildModelModalitiesDetail(
                        key: const ValueKey<String>(
                          'bot-detail-model-modalities-output',
                        ),
                        label: S.of(context).modelOutputModalities,
                        icon: Icons.output_rounded,
                        value: ModelOutputModalityIcons(
                          modalities: _resolvedOutputModalities,
                          keyPrefix: 'bot-detail-output-modality',
                          alignment:
                              widget.embedded
                                  ? WrapAlignment.end
                                  : WrapAlignment.start,
                        ),
                      ),
                      _buildModelCapabilityDetail(
                        key: const ValueKey<String>(
                          'bot-detail-supports-skills',
                        ),
                        label: S.of(context).supportsSkills,
                        icon: LucideIcons.wrench,
                        supported: _resolvedSupportsSkills,
                      ),
                      _buildModelCapabilityDetail(
                        key: const ValueKey<String>('bot-detail-supports-mcp'),
                        label: S.of(context).supportsMcp,
                        icon: Icons.hub_outlined,
                        supported: _resolvedSupportsMcp,
                      ),
                    ],
                    _buildSystemPromptInput(fontSize),
                  ],
                  sectionKey: const ValueKey<String>(
                    'desktop-bot-model-section',
                  ),
                ),
                if (_modelSupportsMcp) ...[
                  SizedBox(height: widget.embedded ? 20 : 16),
                  _buildFormSection(
                    context,
                    S.of(context).mcpServers,
                    [_buildMcpToolPicker()],
                    sectionKey: const ValueKey<String>(
                      'desktop-bot-mcp-section',
                    ),
                  ),
                ],
                if (_modelSupportsAutomaticSkillActivation) ...[
                  SizedBox(height: widget.embedded ? 20 : 16),
                  _buildFormSection(
                    context,
                    S.of(context).botSkills,
                    [_buildBotSkills()],
                    sectionKey: const ValueKey<String>(
                      'desktop-bot-skills-section',
                    ),
                  ),
                ],
                if (widget.readOnly) ...[
                  SizedBox(height: widget.embedded ? 20 : 16),
                  _buildFormSection(
                    context,
                    S.of(context).tokenUsage,
                    [_buildTokenUsage()],
                    sectionKey: const ValueKey<String>(
                      'desktop-bot-token-usage-section',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          widget.readOnly
              ? null
              : widget.embedded
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ShadSeparator.horizontal(),
                  ColoredBox(
                    key: const ValueKey<String>(
                      'desktop-bot-save-bar-background',
                    ),
                    color: StarsDesktopThemeSpec.workspaceSurface(context),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ShadButton(
                            key: const ValueKey<String>('desktop-bot-save'),
                            enabled: !_isSaving && !_isSaved && !_isDeleting,
                            onPressed:
                                _isSaving || _isSaved || _isDeleting
                                    ? null
                                    : _saveBot,
                            leading:
                                _isSaving
                                    ? SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            ShadTheme.of(
                                              context,
                                            ).colorScheme.primaryForeground,
                                      ),
                                    )
                                    : Icon(
                                      _isSaved
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.check_rounded,
                                      size: 17,
                                    ),
                            child: Text(
                              _isSaving
                                  ? S.of(context).savingChanges
                                  : _isSaved
                                  ? S.of(context).changesSaved
                                  : S.of(context).saveChanges,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onSurface,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: _saveBot,
                  child: Text(
                    S.of(context).saveChanges,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              ),
    );
  }
}
