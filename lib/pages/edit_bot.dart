import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/model/model.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/pages/common/logo.dart';
import 'package:stars/pages/common/common.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';

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
  bool _isSaving = false;
  bool _isDeleting = false;
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
      key:
          widget.embedded
              ? const ValueKey<String>('desktop-bot-detail-scaffold')
              : null,
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
          key:
              widget.embedded
                  ? const ValueKey<String>('desktop-bot-detail-content')
                  : null,
          constraints: BoxConstraints(
            maxWidth:
                widget.embedded
                    ? DesktopThemeTokens.formContentMaxWidth +
                        DesktopThemeTokens.formPagePadding.horizontal
                    : 800,
          ),
          child: SingleChildScrollView(
            padding:
                widget.embedded
                    ? DesktopThemeTokens.formPagePadding
                    : const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.embedded) ...[
                  Row(
                    children: [
                      ShadTooltip(
                        builder: (context) => Text(S.of(context).botAvatar),
                        child: ShadButton.ghost(
                          width: 56,
                          height: 56,
                          padding: EdgeInsets.zero,
                          onPressed: _pickImage,
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
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ShadSeparator.horizontal(),
                  ColoredBox(
                    key: const ValueKey<String>(
                      'desktop-bot-save-bar-background',
                    ),
                    color: DesktopThemeTokens.workspaceSurface(context),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ShadButton(
                            enabled: !_isSaving && !_isDeleting,
                            onPressed:
                                _isSaving || _isDeleting ? null : _saveBot,
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
                                    : const Icon(Icons.check_rounded, size: 17),
                            child: Text(S.of(context).saveChanges),
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
    if (_isSaving || _isDeleting) return;
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

    setState(() => _isSaving = true);
    try {
      await widget.onBotUpdated(updatedBot);
      if (!widget.embedded && mounted) {
        navigator.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildDesktopInput({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    Widget? trailing,
    String? placeholder,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
  }) {
    final shadTheme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: shadTheme.textTheme.small),
        const SizedBox(height: 6),
        ShadInput(
          controller: controller,
          placeholder: placeholder == null ? null : Text(placeholder),
          leading: Icon(icon, size: 17),
          trailing: trailing,
          obscureText: obscureText,
          textInputAction: TextInputAction.next,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDesktopTextarea({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? placeholder,
  }) {
    final shadTheme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: shadTheme.textTheme.small),
        const SizedBox(height: 6),
        ShadTextarea(
          controller: controller,
          placeholder: placeholder == null ? null : Text(placeholder),
          leading: Icon(icon, size: 17),
          minHeight: 112,
          maxHeight: 220,
        ),
      ],
    );
  }

  Widget _desktopInputAction({
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
        width: 28,
        height: 28,
        padding: EdgeInsets.zero,
      ),
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
      if (_isDeleting || _isSaving) return;
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
      setState(() => _isDeleting = true);
      try {
        await widget.onBotDeleted();
        if (!widget.embedded && mounted) {
          Navigator.pop(context);
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }

    if (widget.embedded) {
      return ShadTooltip(
        builder: (context) => Text(S.of(context).deleteBot),
        child: ShadIconButton.destructive(
          enabled: !_isSaving && !_isDeleting,
          width: 34,
          height: 34,
          padding: EdgeInsets.zero,
          iconSize: 18,
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: _isSaving || _isDeleting ? null : deleteBot,
        ),
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

  Widget _buildNameInput(double? fontSize) {
    if (widget.embedded) {
      return _buildDesktopInput(
        label: S.of(context).botName,
        icon: Icons.auto_awesome_outlined,
        controller: nameController,
        placeholder: S.of(context).enterBotName,
      );
    }
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
    if (widget.embedded) {
      return _buildDesktopInput(
        label: S.of(context).provider,
        icon: Icons.business_outlined,
        controller: providerController,
        onChanged: (value) => setState(() => selectedProvider = value),
      );
    }
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
    if (widget.embedded) {
      return _buildDesktopInput(
        label: S.of(context).apiType,
        icon: Icons.category_outlined,
        controller: apiTypeController,
      );
    }
    return TextField(
      controller: apiTypeController,
      decoration: _fieldDecoration(
        label: S.of(context).apiType,
        icon: Icons.category_outlined,
      ),
    );
  }

  Widget _buildApiAddressInput(double? fontSize) {
    if (widget.embedded) {
      return _buildDesktopInput(
        label: S.of(context).apiAddress,
        icon: Icons.link_rounded,
        controller: baseURLController,
      );
    }
    return TextField(
      controller: baseURLController,
      decoration: _fieldDecoration(
        label: S.of(context).apiAddress,
        icon: Icons.link_rounded,
      ),
    );
  }

  Widget _buildApiKeyInput(double? fontSize) {
    if (widget.embedded) {
      return _buildDesktopInput(
        label: S.of(context).apiKey,
        icon: Icons.key_outlined,
        controller: apiKeyController,
        obscureText: !_isPasswordVisible,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _desktopInputAction(
              tooltip: S.of(context).copyApiKey,
              icon: Icons.copy_outlined,
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
    if (widget.embedded) {
      return _buildDesktopInput(
        label: S.of(context).model,
        icon: Icons.memory_outlined,
        controller: selectedModelController,
      );
    }
    return TextField(
      controller: selectedModelController,
      decoration: _fieldDecoration(
        label: S.of(context).model,
        icon: Icons.memory_outlined,
      ),
    );
  }

  Widget _buildSystemPromptInput(double? fontSize) {
    if (widget.embedded) {
      return _buildDesktopTextarea(
        label: S.of(context).systemPrompt.replaceAll(':', ''),
        icon: Icons.subject_rounded,
        controller: systemPromptController,
        placeholder: S.of(context).enterSystemPrompt,
      );
    }
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
