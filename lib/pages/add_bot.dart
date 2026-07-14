import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stars/model/model.dart';
import 'package:stars/services/providers/providers.dart';
import 'package:stars/model/providers.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/pages/common/logo.dart';
import 'package:stars/pages/common/common.dart';
import 'package:stars/utils/theme.dart';

class AddBotDialog extends StatelessWidget {
  const AddBotDialog({super.key, required this.onBotAdded});

  final Future<void> Function(Bot) onBotAdded;

  @override
  Widget build(BuildContext context) {
    final windowSize = MediaQuery.sizeOf(context);
    final inset =
        windowSize.width < 900 || windowSize.height < 760 ? 16.0 : 24.0;
    final dialogWidth =
        (windowSize.width - inset * 2).clamp(0.0, 840.0).toDouble();
    final dialogHeight =
        (windowSize.height - inset * 2).clamp(0.0, 720.0).toDouble();

    return Dialog(
      insetPadding: EdgeInsets.all(inset),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: StarsGlassSurface(
          role: StarsGlassRole.popover,
          child: AddBotPage(embedded: true, onBotAdded: onBotAdded),
        ),
      ),
    );
  }
}

class AddBotPage extends StatefulWidget {
  final Future<void> Function(Bot) onBotAdded;
  final bool embedded;

  const AddBotPage({
    super.key,
    required this.onBotAdded,
    this.embedded = false,
  });

  @override
  State<AddBotPage> createState() => _AddBotPageState();
}

class _AddBotPageState extends State<AddBotPage> {
  final _desktopFormKey = GlobalKey<FormState>();
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
  bool _isPasswordVisible = false;
  File? avatarImage;
  List<String> providerModels = [];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        avatarImage = File(pickedFile.path);
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

      // 创建ChatModel并获取模型列表
      final provider = Provider.create(tempBot);
      final models = await provider.listModels();
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
    if (value != null) {
      setState(() {
        providerController.text = value;
        baseURLController.text =
            providersInfo[value]?['base_url'] as String? ?? '';
        apiTypeController.text =
            providersInfo[value]?['api_type'] as String? ?? '';
        providerModels = [];
        selectedModelController.text = '';
        _isCustomProvider = !providersInfo.keys.contains(value);
      });
    }
  }

  void _onSubProviderChanged(String? value) {
    if (value != null) {
      setState(() {
        final subProviders =
            providersInfo[providerController.text]?['sub_providers']
                as Map<String, Map>;
        subProviderController.text = value;
        baseURLController.text =
            subProviders[value]?['base_url'] as String? ?? '';
        providerModels = [];
        selectedModelController.text = '';
        _isCustomProvider = !subProviders.keys.contains(value);
      });
    }
  }

  Future<void> _submitBot() async {
    if (_isSubmitting) return;

    final desktopFormValid =
        !widget.embedded || (_desktopFormKey.currentState?.validate() ?? false);
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
          Divider(
            height: 1,
            thickness: 0,
            color: DesktopThemeTokens.divider(context),
          ),
          Expanded(
            child: Scrollbar(
              controller: _desktopScrollController,
              child: SingleChildScrollView(
                controller: _desktopScrollController,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Form(
                      key: _desktopFormKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: FocusTraversalGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDesktopSection(
                              context,
                              S.of(context).basicInformation,
                              [_buildDesktopNameInput()],
                            ),
                            const SizedBox(height: 20),
                            _buildDesktopSection(
                              context,
                              S.of(context).providerInformation,
                              [
                                _buildDesktopFieldPair(
                                  _buildDesktopProviderInput(),
                                  isHuggingFace
                                      ? _buildDesktopSubProviderInput()
                                      : _buildDesktopApiTypeSelector(),
                                ),
                                if (isHuggingFace)
                                  _buildDesktopFieldPair(
                                    _buildDesktopApiTypeSelector(),
                                    _buildDesktopApiAddressInput(),
                                  )
                                else
                                  _buildDesktopFieldPair(
                                    _buildDesktopApiAddressInput(),
                                    _buildDesktopApiKeyInput(),
                                  ),
                                if (isHuggingFace) _buildDesktopApiKeyInput(),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildDesktopSection(
                              context,
                              S.of(context).modelConfiguration,
                              [
                                _buildDesktopModelsInput(),
                                _buildDesktopSystemPromptInput(),
                              ],
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
          Tooltip(
            message: strings.botAvatar,
            excludeFromSemantics: true,
            child: Semantics(
              button: true,
              label: strings.botAvatar,
              child: InkWell(
                onTap: _pickImage,
                customBorder: const CircleBorder(),
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
          StarsToolbarButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: DesktopThemeTokens.sectionTitleStyle(context)),
        const SizedBox(height: 12),
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildDesktopFieldPair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledBody = MediaQuery.textScalerOf(context).scale(14);
        if (constraints.maxWidth < 600 || scaledBody > 18) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 12), second],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _buildDesktopFooter(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesktopThemeTokens.raisedSurface(context),
        border: Border(
          top: BorderSide(color: DesktopThemeTokens.divider(context), width: 0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                    style: DesktopThemeTokens.secondaryButtonStyle(context),
                    child: Text(S.of(context).cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitBot,
                    style: DesktopThemeTokens.primaryButtonStyle(context),
                    icon:
                        _isSubmitting
                            ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.add_rounded, size: 17),
                    label: Text(S.of(context).addBot),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _desktopInputDecoration({
    required String labelText,
    required IconData icon,
    String? hintText,
    Widget? suffixIcon,
    bool multiline = false,
  }) {
    final tokens = StarsDesktopTokens.of(context);
    final enabledBorder = OutlineInputBorder(
      borderRadius: DesktopThemeTokens.controlRadius,
      borderSide: BorderSide(color: tokens.separator, width: 0),
    );
    final disabledBorder = OutlineInputBorder(
      borderRadius: DesktopThemeTokens.controlRadius,
      borderSide: BorderSide(
        color: tokens.separator.withValues(alpha: 0.55),
        width: 0,
      ),
    );

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      alignLabelWithHint: multiline,
      isDense: true,
      filled: true,
      fillColor: tokens.controlFill,
      contentPadding:
          multiline
              ? const EdgeInsets.fromLTRB(10, 12, 10, 12)
              : const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      prefixIcon: Icon(icon, size: 17, color: tokens.secondaryText),
      prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 44),
      border: enabledBorder,
      enabledBorder: enabledBorder,
      disabledBorder: disabledBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: DesktopThemeTokens.controlRadius,
        borderSide: BorderSide(
          color: tokens.focusRing,
          width: tokens.highContrast ? 2 : 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: DesktopThemeTokens.controlRadius,
        borderSide: BorderSide(color: tokens.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: DesktopThemeTokens.controlRadius,
        borderSide: BorderSide(color: tokens.danger, width: 1.5),
      ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    );
  }

  Widget _desktopIconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      iconSize: 16,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
    );
  }

  Widget _desktopMenuAnchor({
    required List<String> options,
    required String selectedValue,
    required Widget Function(MenuController controller) fieldBuilder,
    required ValueChanged<String> onSelected,
    Widget Function(String value)? leadingBuilder,
  }) {
    final tokens = StarsDesktopTokens.of(context);
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(tokens.raisedSurface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: tokens.highContrast ? 0 : 0.18),
        ),
        elevation: WidgetStatePropertyAll(tokens.highContrast ? 0 : 6),
        maximumSize: const WidgetStatePropertyAll(Size(420, 360)),
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
    return TextFormField(
      controller: nameController,
      textInputAction: TextInputAction.next,
      validator:
          (value) =>
              value == null || value.trim().isEmpty
                  ? S.of(context).fillRequiredFields
                  : null,
      decoration: _desktopInputDecoration(
        labelText: S.of(context).botName,
        hintText: S.of(context).enterBotName,
        icon: Icons.auto_awesome_outlined,
      ),
    );
  }

  Widget _buildDesktopProviderInput() {
    return _desktopMenuAnchor(
      options: providersInfo.keys.toList(growable: false),
      selectedValue: providerController.text,
      onSelected: _onProviderChanged,
      leadingBuilder:
          (provider) => buildProviderLogo(context, '', provider, 18),
      fieldBuilder:
          (menuController) => TextField(
            controller: providerController,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              setState(() {
                _isCustomProvider = !providersInfo.keys.contains(value);
                providerModels = [];
                selectedModelController.text = '';
              });
            },
            decoration: _desktopInputDecoration(
              labelText: S.of(context).provider,
              hintText: S.of(context).selectProvider,
              icon: Icons.business_outlined,
              suffixIcon: _desktopIconButton(
                tooltip: S.of(context).selectProvider,
                icon: Icons.expand_more_rounded,
                onPressed: () => _toggleMenu(menuController),
              ),
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
          (menuController) => TextField(
            controller: subProviderController,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              setState(() {
                _isCustomProvider = !subProviders.keys.contains(value);
                providerModels = [];
                selectedModelController.text = '';
              });
            },
            decoration: _desktopInputDecoration(
              labelText: '${S.of(context).provider} (HuggingFace)',
              hintText: S.of(context).selectProvider,
              icon: Icons.hub_outlined,
              suffixIcon: _desktopIconButton(
                tooltip: S.of(context).selectProvider,
                icon: Icons.expand_more_rounded,
                onPressed: () => _toggleMenu(menuController),
              ),
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
          (menuController) => TextField(
            controller: apiTypeController,
            enabled: _isCustomProvider,
            textInputAction: TextInputAction.next,
            decoration: _desktopInputDecoration(
              labelText: S.of(context).apiType,
              icon: Icons.category_outlined,
              suffixIcon: _desktopIconButton(
                tooltip: S.of(context).apiType,
                icon: Icons.expand_more_rounded,
                onPressed:
                    _isCustomProvider
                        ? () => _toggleMenu(menuController)
                        : null,
              ),
            ),
          ),
    );
  }

  Widget _buildDesktopApiAddressInput() {
    return TextFormField(
      controller: baseURLController,
      textInputAction: TextInputAction.next,
      validator:
          (value) =>
              value == null || value.trim().isEmpty
                  ? S.of(context).enterApiAddress
                  : null,
      decoration: _desktopInputDecoration(
        labelText: S.of(context).apiAddress,
        icon: Icons.link_rounded,
      ),
    );
  }

  Widget _buildDesktopApiKeyInput() {
    return TextFormField(
      controller: apiKeyController,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.next,
      validator:
          (value) =>
              value == null || value.trim().isEmpty
                  ? S.of(context).pleaseEnterApiKey
                  : null,
      decoration: _desktopInputDecoration(
        labelText: S.of(context).apiKey,
        icon: Icons.key_outlined,
        suffixIcon: _desktopIconButton(
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
          (menuController) => TextField(
            controller: selectedModelController,
            textInputAction: TextInputAction.next,
            decoration: _desktopInputDecoration(
              labelText: S.of(context).model,
              hintText: S.of(context).selectModel,
              icon: Icons.memory_outlined,
              suffixIcon:
                  providerModels.isEmpty
                      ? _isLoadingModels
                          ? const SizedBox.square(
                            dimension: 44,
                            child: Center(
                              child: SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
          ),
    );
  }

  Widget _buildDesktopSystemPromptInput() {
    return TextField(
      controller: systemPromptController,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      minLines: 3,
      maxLines: 4,
      decoration: _desktopInputDecoration(
        labelText: S.of(context).systemPrompt,
        icon: Icons.notes_rounded,
        multiline: true,
      ),
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
    showDialog(
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
    showDialog(
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
    showDialog(
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
    showDialog(
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
