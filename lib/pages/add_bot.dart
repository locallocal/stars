import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stars/model/model.dart';
import 'package:stars/services/providers/providers.dart';
import 'package:stars/model/providers.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/pages/common/logo.dart';
import 'package:stars/pages/common/common.dart';

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
  final nameController = TextEditingController();
  final providerController = TextEditingController(text: 'OpenAI');
  final subProviderController = TextEditingController(text: 'HF-Inference');
  final apiTypeController = TextEditingController();
  final baseURLController = TextEditingController();
  final apiKeyController = TextEditingController();
  final selectedModelController = TextEditingController();
  final systemPromptController = TextEditingController();

  bool _isLoadingModels = false;
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
    if (nameController.text.trim().isEmpty ||
        apiKeyController.text.trim().isEmpty ||
        baseURLController.text.trim().isEmpty) {
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

    await widget.onBotAdded(newBot);
    if (!widget.embedded && mounted) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;

    if (widget.embedded) {
      return _buildEmbeddedDesktop(context, fontSize);
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
          onPressed: _submitBot,
          child: Text(
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

  Widget _buildEmbeddedDesktop(BuildContext context, double? fontSize) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHuggingFace = providerController.text == 'HuggingFace';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: FocusTraversalGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDesktopHeader(context),
                          const SizedBox(height: 24),
                          _buildDesktopSection(
                            context,
                            S.of(context).basicInformation,
                            [_buildDesktopNameInput()],
                          ),
                          const SizedBox(height: 24),
                          _buildDesktopSection(
                            context,
                            S.of(context).providerInformation,
                            [
                              _buildDesktopFieldPair(
                                _buildDesktopProviderInput(fontSize),
                                isHuggingFace
                                    ? _buildDesktopSubProviderInput(fontSize)
                                    : _buildDesktopApiTypeSelector(fontSize),
                              ),
                              if (isHuggingFace)
                                _buildDesktopFieldPair(
                                  _buildDesktopApiTypeSelector(fontSize),
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
                          const SizedBox(height: 24),
                          _buildDesktopSection(
                            context,
                            S.of(context).modelConfiguration,
                            [
                              _buildDesktopModelsInput(fontSize),
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
          _buildDesktopFooter(context),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    final theme = Theme.of(context);
    final strings = S.of(context);

    return Row(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
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
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor:
                        avatarImage == null
                            ? getFrostedProviderColor(
                              providerController.text,
                              theme.colorScheme.primary,
                            )
                            : theme.colorScheme.primary,
                    backgroundImage:
                        avatarImage != null ? FileImage(avatarImage!) : null,
                    child:
                        avatarImage == null
                            ? buildProviderLogo(
                              context,
                              '',
                              providerController.text,
                              32,
                            )
                            : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.botAvatar,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            strings.addBot,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
        const SizedBox(height: 14),
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildDesktopFieldPair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 14), second],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 14),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _buildDesktopFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
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
                  FilledButton(
                    onPressed: _submitBot,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(96, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(S.of(context).addBot),
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
    String? hintText,
    Widget? suffixIcon,
    bool multiline = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );
    final disabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.55),
      ),
    );

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      alignLabelWithHint: multiline,
      isDense: true,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding:
          multiline
              ? const EdgeInsets.fromLTRB(12, 14, 12, 12)
              : const EdgeInsets.fromLTRB(12, 10, 8, 10),
      border: enabledBorder,
      enabledBorder: enabledBorder,
      disabledBorder: disabledBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error, width: 1.4),
      ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    );
  }

  Widget _buildDesktopNameInput() {
    return TextField(
      controller: nameController,
      textInputAction: TextInputAction.next,
      decoration: _desktopInputDecoration(
        labelText: S.of(context).botName,
        hintText: S.of(context).enterBotName,
      ),
    );
  }

  Widget _buildDesktopProviderInput(double? fontSize) {
    return TextField(
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
        suffixIcon: _desktopIconButton(
          tooltip: S.of(context).selectProvider,
          icon: Icons.expand_more_rounded,
          onPressed: () => _showProvidersOptions(fontSize),
        ),
      ),
    );
  }

  Widget _buildDesktopSubProviderInput(double? fontSize) {
    return TextField(
      controller: subProviderController,
      textInputAction: TextInputAction.next,
      onChanged: (value) {
        setState(() {
          _isCustomProvider = providersInfo.keys.contains(value);
          providerModels = [];
          selectedModelController.text = '';
        });
      },
      decoration: _desktopInputDecoration(
        labelText: '${S.of(context).provider} (HuggingFace)',
        hintText: S.of(context).selectProvider,
        suffixIcon: _desktopIconButton(
          tooltip: S.of(context).selectProvider,
          icon: Icons.expand_more_rounded,
          onPressed: () => _showSubProvidersOptions(fontSize),
        ),
      ),
    );
  }

  Widget _buildDesktopApiTypeSelector(double? fontSize) {
    return TextField(
      controller: apiTypeController,
      enabled: _isCustomProvider,
      textInputAction: TextInputAction.next,
      decoration: _desktopInputDecoration(
        labelText: S.of(context).apiType,
        suffixIcon: _desktopIconButton(
          tooltip: S.of(context).apiType,
          icon: Icons.expand_more_rounded,
          onPressed:
              _isCustomProvider ? () => _showApiTypeOptions(fontSize) : null,
        ),
      ),
    );
  }

  Widget _buildDesktopApiAddressInput() {
    return TextField(
      controller: baseURLController,
      textInputAction: TextInputAction.next,
      decoration: _desktopInputDecoration(labelText: S.of(context).apiAddress),
    );
  }

  Widget _buildDesktopApiKeyInput() {
    return TextField(
      controller: apiKeyController,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.next,
      decoration: _desktopInputDecoration(
        labelText: S.of(context).apiKey,
        suffixIcon: _desktopIconButton(
          tooltip: S.of(context).apiKey,
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

  Widget _buildDesktopModelsInput(double? fontSize) {
    final suffixIcon =
        providerModels.isEmpty
            ? _isLoadingModels
                ? const SizedBox.square(
                  dimension: 36,
                  child: Center(
                    child: SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
                : _desktopIconButton(
                  tooltip: S.of(context).selectModel,
                  icon: Icons.refresh_rounded,
                  onPressed: _fetchModels,
                )
            : _desktopIconButton(
              tooltip: S.of(context).selectModel,
              icon: Icons.expand_more_rounded,
              onPressed: () => _showModelsOptions(fontSize),
            );

    return TextField(
      controller: selectedModelController,
      textInputAction: TextInputAction.next,
      decoration: _desktopInputDecoration(
        labelText: S.of(context).model,
        hintText: S.of(context).selectModel,
        suffixIcon: suffixIcon,
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
