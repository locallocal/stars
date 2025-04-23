import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/pages/common/logo.dart';
import 'package:bubble/pages/common/common.dart';

class EditBotPage extends StatefulWidget {
  final Bot bot;
  final Function(Bot) onBotUpdated;
  final VoidCallback onBotDeleted;

  const EditBotPage({
    super.key,
    required this.bot,
    required this.onBotUpdated,
    required this.onBotDeleted,
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
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          S.of(context).editBot,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0, // 防止滚动时背景色变化
        elevation: 0, // 移除阴影
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: () {
              showDialog(
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
                        S.of(context).confirmDeleteBot(widget.bot.name),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            S.of(context).cancel,
                            style: TextStyle(
                              fontSize: fontSize,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onBotDeleted();
                            Navigator.pop(context);
                          },
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
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像选择
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
                      avatarImage != null ? FileImage(avatarImage!) : null,
                  child:
                      avatarImage == null
                          ? buildProviderLogo(context, '', selectedProvider, 64)
                          : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: S.of(context).enterBotName,
                hintStyle: TextStyle(fontSize: fontSize),
                prefixIcon: const Icon(Icons.smart_toy_rounded),
                border: OutlineInputBorder(
                  borderSide: BorderSide(width: 0, style: BorderStyle.none),
                  borderRadius: BorderRadius.all(Radius.circular(24.0)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 32),

            // 提供商（禁用编辑）
            Text(
              '${S.of(context).provider}:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: providerController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.business_rounded),
                border: OutlineInputBorder(
                  borderSide: BorderSide(width: 0, style: BorderStyle.none),
                  borderRadius: BorderRadius.all(Radius.circular(24.0)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.secondary,
                enabled: false,
              ),
            ),
            const SizedBox(height: 16),

            // API类型（禁用编辑）
            Text(
              S.of(context).apiType,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: apiTypeController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.category_rounded),
                border: OutlineInputBorder(
                  borderSide: BorderSide(width: 0, style: BorderStyle.none),
                  borderRadius: BorderRadius.all(Radius.circular(24.0)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.secondary,
                enabled: false,
              ),
            ),
            const SizedBox(height: 16),

            // API地址（禁用编辑）
            Text(
              S.of(context).apiAddress,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: baseURLController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.link_rounded),
                border: OutlineInputBorder(
                  borderSide: BorderSide(width: 0, style: BorderStyle.none),
                  borderRadius: BorderRadius.all(Radius.circular(24.0)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.secondary,
                enabled: false,
              ),
            ),
            const SizedBox(height: 16),

            // API密钥（禁用编辑）
            Text(
              '${S.of(context).apiKey}:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: apiKeyController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.key_rounded),
                border: OutlineInputBorder(
                  borderSide: BorderSide(width: 0, style: BorderStyle.none),
                  borderRadius: BorderRadius.all(Radius.circular(24.0)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),

            // 选择模型（禁用编辑）
            Text(
              '${S.of(context).model}:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: selectedModelController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.auto_awesome_rounded),
                border: OutlineInputBorder(
                  borderSide: BorderSide(width: 0, style: BorderStyle.none),
                  borderRadius: BorderRadius.all(Radius.circular(24.0)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),

            // 系统提示词（允许编辑）
            Text(
              S.of(context).systemPrompt,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: systemPromptController,
              decoration: InputDecoration(
                hintText: S.of(context).enterSystemPrompt,
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
                fillColor: Theme.of(context).colorScheme.secondary,
              ),
              maxLines: 6,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.onSurface,
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: () {
            if (nameController.text.trim().isNotEmpty) {
              final updatedBot = Bot(
                id: widget.bot.id,
                name: nameController.text.trim(),
                avatar: avatarImage?.path ?? widget.bot.avatar,
                provider: widget.bot.provider, // 保持原值
                baseURL: widget.bot.baseURL, // 保持原值
                apiKey: widget.bot.apiKey, // 保持原值
                apiType: widget.bot.apiType, // 保持原值
                model: widget.bot.model, // 保持原值
                systemPrompt: systemPromptController.text.trim(),
                createTimestamp: widget.bot.createTimestamp,
                modifyTimestamp: DateTime.now(),
              );

              widget.onBotUpdated(updatedBot);
              Navigator.pop(context);
            } else {
              showSnackBar(context, S.of(context).fillRequiredFields);
            }
          },
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
