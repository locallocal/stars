import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/models/provider_catalog.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/logo.dart';
import 'package:stars/utils/theme.dart';

class AddBotDialog extends StatelessWidget {
  const AddBotDialog({
    super.key,
    required this.onBotAdded,
    this.modelLoader,
    this.avatarPicker,
  });

  final Future<void> Function(Bot) onBotAdded;
  final Future<List<String>> Function(Bot)? modelLoader;
  final Future<String?> Function()? avatarPicker;

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
        ),
      ),
    );
  }
}

class AddBotPage extends StatefulWidget {
  final Future<void> Function(Bot) onBotAdded;
  final Future<List<String>> Function(Bot)? modelLoader;
  final Future<String?> Function()? avatarPicker;
  final bool embedded;

  const AddBotPage({
    super.key,
    required this.onBotAdded,
    this.modelLoader,
    this.avatarPicker,
    this.embedded = false,
  });

  @override
  State<AddBotPage> createState() => _AddBotPageState();
}

class _AddBotPageState extends State<AddBotPage> {
  static const double _desktopFieldWidth =
      DesktopThemeTokens.addBotFormFieldWidth;
  static const double _desktopDropdownButtonSize = 30;
  static const double _desktopProviderMenuWidth = 256;
  static const double _desktopSectionPadding =
      DesktopThemeTokens.botFormSectionPadding;
  static const double _desktopSectionBorderWidth =
      DesktopThemeTokens.botFormSectionBorderWidth;
  static const double _desktopFormWidth =
      _desktopFieldWidth +
      _desktopSectionPadding * 2 +
      _desktopSectionBorderWidth * 2;
  static const BoxConstraints _desktopInputConstraints = BoxConstraints(
    minHeight: DesktopThemeTokens.botFormFieldHeight,
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

  bool _isLoadingModels = false;
  bool _isSubmitting = false;
  bool _isCustomProvider = false;
  bool _isSyncingProviderFields = false;
  bool _isPasswordVisible = false;
  File? avatarImage;
  List<String> providerModels = [];

  Future<void> _pickImage() async {
    final imagePath = await widget.avatarPicker?.call();

    if (imagePath != null && mounted) {
      setState(() {
        avatarImage = File(imagePath);
      });
    }
  } // 添加加载状态变量

  // 添加获取模型列表的方法
  Future<void> _fetchModels() async {
    if (apiKeyController.text.trim().isEmpty) {
      showSnackBar(context, S.of(context).pleaseEnterApiKey);
      return;
    }
    if (baseURLController.text.trim().isEmpty) {
      showSnackBar(context, S.of(context).enterApiAddress);
      return;
    }
    setState(() {
      _isLoadingModels = true;
    });

    try {
      final apiType = apiTypeController.text.trim();
      final baseURL = baseURLController.text.trim(); // 使用baseURLController的值

      // 创建临时Bot对象
      final tempBot = Bot(
        id: 'temp_bot',
        name: 'Temp Bot',
        avatar: '',
        provider: providerController.text,
        baseURL: baseURL, // 使用用户输入的baseURL
        apiKey: apiKeyController.text.trim(),
        apiType: apiType,
        model: '',
        systemPrompt: '',
        createTimestamp: DateTime.now(),
        modifyTimestamp: DateTime.now(),
      );

      final modelLoader = widget.modelLoader;
      if (modelLoader == null) {
        throw StateError('No AI provider model loader was injected.');
      }
      final models = await modelLoader(tempBot);
      if (models.isNotEmpty && mounted) {
        setState(() {
          providerModels = models;
          selectedModelController.text = models.first;
        });
      } else if (mounted) {
        showSnackBar(context, S.of(context).noModelsRetrieved);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, e.toString());
      }
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
    if (!desktopFormValid) return;

    if (!widget.embedded &&
        (nameController.text.trim().isEmpty ||
            apiKeyController.text.trim().isEmpty ||
            baseURLController.text.trim().isEmpty)) {
      showWarningSnackBar(context, S.of(context).fillRequiredFields);
      return;
    }

    final navigator = Navigator.of(context);
    final providerInfo = providersInfo[providerController.text];
    final apiType =
        (providerInfo?['api_type'] as String?) ?? apiTypeController.text.trim();
    final baseURL = baseURLController.text.trim();

    final newBot = Bot(
      id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      name: nameController.text.trim(),
      avatar: avatarImage?.path ?? '',
      provider: providerController.text,
      baseURL: baseURL,
      apiKey: apiKeyController.text.trim(),
      apiType: apiType,
      model: selectedModelController.text,
      systemPrompt: systemPromptController.text.trim(),
      createTimestamp: DateTime.now(),
      modifyTimestamp: DateTime.now(),
    );

    setState(() => _isSubmitting = true);
    try {
      await widget.onBotAdded(newBot);
      if (!widget.embedded && mounted) {
        navigator.pop();
      }
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
                      maxWidth: _desktopFormWidth,
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
                          Icons.edit_rounded,
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
                  style: DesktopThemeTokens.pageTitleStyle(context),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.botInformation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesktopThemeTokens.metaStyle(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ShadTooltip(
            builder:
                (context) =>
                    Text(MaterialLocalizations.of(context).closeButtonTooltip),
            child: ShadIconButton.ghost(
              enabled: !_isSubmitting,
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).pop(),
              width: 36,
              height: 36,
              iconSize: 17,
              icon: const Icon(Icons.close_rounded),
            ),
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
      padding: const EdgeInsets.all(_desktopSectionPadding),
      backgroundColor: tokens.raisedSurface,
      border: ShadBorder.all(
        color: tokens.separator,
        width: _desktopSectionBorderWidth,
      ),
      columnCrossAxisAlignment: CrossAxisAlignment.stretch,
      title: Text(title, style: DesktopThemeTokens.sectionTitleStyle(context)),
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
        const ShadSeparator.horizontal(),
        ColoredBox(
          color: shadTheme.colorScheme.background,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _desktopFormWidth,
                  ),
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
                        enabled: !_isSubmitting,
                        onPressed: _isSubmitting ? null : _submitBot,
                        leading:
                            _isSubmitting
                                ? SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        shadTheme.colorScheme.primaryForeground,
                                  ),
                                )
                                : const Icon(Icons.add_rounded, size: 17),
                        child: Text(S.of(context).addBot),
                      ),
                    ],
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
    return ShadTooltip(
      builder: (context) => Text(tooltip),
      child: ShadIconButton.ghost(
        enabled: onPressed != null,
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 16,
        width: _desktopDropdownButtonSize,
        height: _desktopDropdownButtonSize,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _desktopInputLeading(IconData icon) {
    return SizedBox(
      width: 17,
      height: 30,
      child: Center(child: Icon(icon, size: 17)),
    );
  }

  Widget _desktopMenuAnchor({
    required List<String> options,
    required String selectedValue,
    required Widget Function(MenuController controller) fieldBuilder,
    required ValueChanged<String> onSelected,
    Widget Function(String value)? leadingBuilder,
    double? menuWidth,
    bool alignEnd = false,
  }) {
    assert(!alignEnd || menuWidth != null);
    final tokens = StarsDesktopTokens.of(context);
    return MenuAnchor(
      alignmentOffset: Offset(
        alignEnd ? _desktopDropdownButtonSize - menuWidth! : 0,
        4,
      ),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(tokens.raisedSurface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: tokens.highContrast ? 0 : 0.18),
        ),
        elevation: WidgetStatePropertyAll(tokens.highContrast ? 0 : 6),
        minimumSize:
            menuWidth == null
                ? null
                : WidgetStatePropertyAll(Size(menuWidth, 0)),
        maximumSize: WidgetStatePropertyAll(Size(menuWidth ?? 420, 360)),
        side: WidgetStatePropertyAll(
          BorderSide(color: tokens.separator, width: 0),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: DesktopThemeTokens.containerRadius,
          ),
        ),
      ),
      menuChildren: [
        for (final option in options)
          MenuItemButton(
            leadingIcon: leadingBuilder?.call(option),
            trailingIcon:
                option == selectedValue
                    ? Icon(Icons.check_rounded, size: 16, color: tokens.accent)
                    : const SizedBox.square(dimension: 16),
            onPressed: () => onSelected(option),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 180),
              child: Text(option, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
      ],
      builder: (context, controller, child) => fieldBuilder(controller),
    );
  }

  void _toggleMenu(MenuController controller) {
    controller.isOpen ? controller.close() : controller.open();
  }

  Widget _buildDesktopNameInput() {
    return ShadInputFormField(
      key: const ValueKey<String>('add-bot-name'),
      id: 'name',
      controller: nameController,
      textInputAction: TextInputAction.next,
      label: Text(S.of(context).botName),
      placeholder: Text(S.of(context).enterBotName),
      leading: _desktopInputLeading(Icons.auto_awesome_outlined),
      constraints: _desktopInputConstraints,
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
      textInputAction: TextInputAction.next,
      label: Text(S.of(context).provider),
      placeholder: Text(S.of(context).selectProvider),
      leading: _desktopInputLeading(Icons.business_outlined),
      constraints: _desktopInputConstraints,
      onChanged: _handleProviderTextChanged,
      trailing: _desktopMenuAnchor(
        options: providersInfo.keys.toList(growable: false),
        selectedValue: providerController.text,
        onSelected: _onProviderChanged,
        menuWidth: _desktopProviderMenuWidth,
        alignEnd: true,
        leadingBuilder:
            (provider) => buildProviderLogo(context, '', provider, 18),
        fieldBuilder:
            (menuController) => _desktopIconButton(
              tooltip: S.of(context).selectProvider,
              icon: Icons.expand_more_rounded,
              onPressed: () => _toggleMenu(menuController),
            ),
      ),
    );
  }

  Widget _buildDesktopSubProviderInput() {
    final subProviders =
        providersInfo[providerController.text]?['sub_providers']
            as Map<String, Map>;
    return _desktopMenuAnchor(
      options: subProviders.keys.toList(growable: false),
      selectedValue: subProviderController.text,
      onSelected: _onSubProviderChanged,
      leadingBuilder:
          (provider) => buildProviderLogo(context, '', provider, 18),
      fieldBuilder:
          (menuController) => ShadInputFormField(
            key: const ValueKey<String>('add-bot-sub-provider'),
            id: 'subProvider',
            controller: subProviderController,
            textInputAction: TextInputAction.next,
            label: Text('${S.of(context).provider} (HuggingFace)'),
            placeholder: Text(S.of(context).selectProvider),
            leading: _desktopInputLeading(Icons.hub_outlined),
            constraints: _desktopInputConstraints,
            onChanged: _handleSubProviderTextChanged,
            trailing: _desktopIconButton(
              tooltip: S.of(context).selectProvider,
              icon: Icons.expand_more_rounded,
              onPressed: () => _toggleMenu(menuController),
            ),
          ),
    );
  }

  Widget _buildDesktopApiTypeSelector() {
    return _desktopMenuAnchor(
      options: Bot.getAllApiTypes(),
      selectedValue: apiTypeController.text,
      onSelected: (value) {
        setState(() => apiTypeController.text = value);
      },
      fieldBuilder:
          (menuController) => ShadInputFormField(
            key: const ValueKey<String>('add-bot-api-type'),
            id: 'apiType',
            controller: apiTypeController,
            enabled: _isCustomProvider,
            textInputAction: TextInputAction.next,
            label: Text(S.of(context).apiType),
            leading: _desktopInputLeading(Icons.category_outlined),
            constraints: _desktopInputConstraints,
            trailing: _desktopIconButton(
              tooltip: S.of(context).apiType,
              icon: Icons.expand_more_rounded,
              onPressed:
                  _isCustomProvider ? () => _toggleMenu(menuController) : null,
            ),
          ),
    );
  }

  Widget _buildDesktopApiAddressInput() {
    return ShadInputFormField(
      key: const ValueKey<String>('add-bot-base-url'),
      id: 'baseUrl',
      controller: baseURLController,
      textInputAction: TextInputAction.next,
      label: Text(S.of(context).apiAddress),
      leading: _desktopInputLeading(Icons.link_rounded),
      constraints: _desktopInputConstraints,
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
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.next,
      label: Text(S.of(context).apiKey),
      leading: _desktopInputLeading(Icons.key_outlined),
      constraints: _desktopInputConstraints,
      validator:
          (value) =>
              value.trim().isEmpty ? S.of(context).pleaseEnterApiKey : null,
      trailing: _desktopIconButton(
        tooltip:
            _isPasswordVisible
                ? S.of(context).hideApiKey
                : S.of(context).showApiKey,
        icon: _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
        onPressed: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
      ),
    );
  }

  Widget _buildDesktopModelsInput() {
    return _desktopMenuAnchor(
      options: providerModels,
      selectedValue: selectedModelController.text,
      onSelected: (value) {
        setState(() => selectedModelController.text = value);
      },
      fieldBuilder:
          (menuController) => ShadInputFormField(
            key: const ValueKey<String>('add-bot-model'),
            id: 'model',
            controller: selectedModelController,
            textInputAction: TextInputAction.next,
            label: Text(S.of(context).model),
            placeholder: Text(S.of(context).selectModel),
            leading: _desktopInputLeading(Icons.memory_outlined),
            constraints: _desktopInputConstraints,
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
                          icon: Icons.refresh_rounded,
                          onPressed: _fetchModels,
                        )
                    : _desktopIconButton(
                      tooltip: S.of(context).selectModel,
                      icon: Icons.expand_more_rounded,
                      onPressed: () => _toggleMenu(menuController),
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
      leading: const Icon(Icons.notes_rounded, size: 17),
      minHeight: 96,
      maxHeight: 96,
      resizable: false,
    );
  }

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
                      child: RadioGroup<String>(
                        groupValue: selectedModelController.text,
                        onChanged: (value) {
                          if (value == null) return;
                          selectedModelController.text = value;
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
                                        return RadioListTile<String>(
                                          title: Text(model),
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
