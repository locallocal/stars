import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stars/model/model.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/pages/common/logo.dart';
import 'package:stars/pages/common/common.dart';
import 'package:stars/utils/theme.dart';

class EditBotPage extends StatefulWidget {
  final Bot bot;
  final Future<void> Function(Bot) onBotUpdated;
  final Future<void> Function() onBotDeleted;
  final bool embedded;

  const EditBotPage({
    super.key,
    required this.bot,
    required this.onBotUpdated,
    required this.onBotDeleted,
    this.embedded = false,
  });

  @override
  State<EditBotPage> createState() => _EditAIBotPageState();
}

class _EditAIBotPageState extends State<EditBotPage> {
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
  File? avatarImage;

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
    if (widget.bot.avatar.isNotEmpty) {
      avatarImage = File(widget.bot.avatar);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        avatarImage = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    providerController.dispose();
    apiTypeController.dispose();
    apiKeyController.dispose();
    baseURLController.dispose();
    selectedModelController.dispose();
    systemPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    return Scaffold(
      backgroundColor:
          widget.embedded ? DesktopThemeTokens.workspaceSurface(context) : null,
      appBar:
          widget.embedded
              ? null
              : AppBar(
                centerTitle: true,
                title: Text(
                  S.of(context).editBot,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                scrolledUnderElevation: 0,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                actions: [_buildDeleteButton(fontSize)],
              ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.embedded ? 760 : 800),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              widget.embedded ? 28 : 16,
              widget.embedded ? 24 : 16,
              widget.embedded ? 28 : 16,
              widget.embedded ? 32 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.embedded) ...[
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
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
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.bot.name,
                              style: DesktopThemeTokens.pageTitleStyle(context),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${widget.bot.provider} · ${widget.bot.model}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DesktopThemeTokens.metaStyle(context),
                            ),
                          ],
                        ),
                      ),
                      _buildDeleteButton(fontSize),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                // 头像选择
                if (!widget.embedded) ...[
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
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
                _buildFormSection(context, S.of(context).basicInformation, [
                  _buildNameInput(fontSize),
                ]),
                const SizedBox(height: 16),

                // API提供商分组
                _buildFormSection(context, S.of(context).providerInformation, [
                  _buildProviderInput(fontSize),
                  _buildApiTypeInput(fontSize),
                  _buildApiAddressInput(fontSize),
                  _buildApiKeyInput(fontSize),
                ]),
                const SizedBox(height: 16),

                // API提供商分组
                _buildFormSection(context, S.of(context).modelConfiguration, [
                  _buildModelsInput(fontSize),
                  _buildSystemPromptInput(fontSize),
                ]),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          widget.embedded
              ? Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                decoration: BoxDecoration(
                  color: DesktopThemeTokens.workspaceSurface(context),
                  border: Border(
                    top: BorderSide(
                      width: 0,
                      color: DesktopThemeTokens.divider(context),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      style: DesktopThemeTokens.primaryButtonStyle(context),
                      onPressed: _saveBot,
                      icon: const Icon(Icons.check_rounded, size: 17),
                      label: Text(S.of(context).saveChanges),
                    ),
                  ],
                ),
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

  Widget _buildFormSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    if (!widget.embedded) {
      return buildSectionContainer(context, title, children);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DesktopThemeTokens.sectionTitleStyle(
            context,
          )?.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 12),
        for (final child in children) ...[
          child,
          if (child != children.last) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _saveBot() async {
    if (nameController.text.trim().isEmpty) {
      showSnackBar(context, S.of(context).fillRequiredFields);
      return;
    }
    final navigator = Navigator.of(context);
    final updatedBot = Bot(
      id: widget.bot.id,
      name: nameController.text.trim(),
      avatar: avatarImage?.path ?? widget.bot.avatar,
      provider: providerController.text.trim(),
      baseURL: baseURLController.text.trim(),
      apiKey: apiKeyController.text.trim(),
      apiType: apiTypeController.text.trim(),
      model: selectedModelController.text.trim(),
      systemPrompt: systemPromptController.text.trim(),
      parameters: widget.bot.parameters,
      createTimestamp: widget.bot.createTimestamp,
      modifyTimestamp: DateTime.now(),
    );

    await widget.onBotUpdated(updatedBot);
    if (!widget.embedded && mounted) {
      navigator.pop();
    }
  }

  InputDecoration _desktopFieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: DesktopThemeTokens.controlFill(context),
      border: OutlineInputBorder(
        borderRadius: DesktopThemeTokens.controlRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: DesktopThemeTokens.controlRadius,
        borderSide: BorderSide(
          width: 0,
          color: DesktopThemeTokens.divider(context),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: DesktopThemeTokens.controlRadius,
        borderSide: BorderSide(
          width: 1.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    String? hintText,
  }) {
    if (widget.embedded) {
      return _desktopFieldDecoration(
        label: label,
        icon: icon,
        suffixIcon: suffixIcon,
      ).copyWith(hintText: hintText);
    }
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
    return IconButton(
      tooltip: S.of(context).deleteBot,
      icon: Icon(
        Icons.delete_outline_rounded,
        size: widget.embedded ? 18 : 24,
        color: Theme.of(context).colorScheme.error,
      ),
      onPressed: () async {
        final shouldDelete = await showDialog<bool>(
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
                content: Text(S.of(context).confirmDeleteBot(widget.bot.name)),
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

        if (shouldDelete != true) {
          return;
        }

        await widget.onBotDeleted();
        if (!widget.embedded && mounted) {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _buildNameInput(double? fontSize) {
    return TextField(
      controller: nameController,
      decoration: _fieldDecoration(
        label: S.of(context).botName,
        icon: Icons.auto_awesome_outlined,
        hintText: S.of(context).enterBotName,
      ),
    );
  }

  Widget _buildProviderInput(double? fontSize) {
    return TextField(
      controller: providerController,
      onChanged: (value) => setState(() => selectedProvider = value),
      decoration: _fieldDecoration(
        label: S.of(context).provider,
        icon: Icons.business_outlined,
      ),
    );
  }

  Widget _buildApiTypeInput(double? fontSize) {
    return TextField(
      controller: apiTypeController,
      decoration: _fieldDecoration(
        label: S.of(context).apiType,
        icon: Icons.category_outlined,
      ),
    );
  }

  Widget _buildApiAddressInput(double? fontSize) {
    return TextField(
      controller: baseURLController,
      decoration: _fieldDecoration(
        label: S.of(context).apiAddress,
        icon: Icons.link_rounded,
      ),
    );
  }

  Widget _buildApiKeyInput(double? fontSize) {
    return TextField(
      controller: apiKeyController,
      obscureText: !_isPasswordVisible,
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
    return TextField(
      controller: selectedModelController,
      decoration: _fieldDecoration(
        label: S.of(context).model,
        icon: Icons.memory_outlined,
      ),
    );
  }

  Widget _buildSystemPromptInput(double? fontSize) {
    return TextField(
      controller: systemPromptController,
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
