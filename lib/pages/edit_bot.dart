import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/pages/common/logo.dart';

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
  late final TextEditingController apiKeyController;
  late final TextEditingController baseURLController;
  late final TextEditingController systemPromptController;

  late String selectedProvider;
  late String selectedModel;
  File? avatarImage;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.bot.name);
    apiKeyController = TextEditingController(text: widget.bot.apiKey);
    baseURLController = TextEditingController(text: widget.bot.baseURL);
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
    final fontSzie = Theme.of(context).textTheme.bodyLarge?.fontSize;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          S.of(context).editBot,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSzie),
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
                            fontSize: fontSzie,
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
                              fontSize: fontSzie,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // 关闭对话框
                            widget.onBotDeleted();
                            Navigator.pop(context); // 返回联系人列表
                          },
                          child: Text(
                            S.of(context).delete,
                            style: TextStyle(
                              fontSize: fontSzie,
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

            // 智能体名称
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  fillColor: Theme.of(context).colorScheme.secondary,
                  focusColor: Theme.of(context).colorScheme.secondary,
                  hoverColor: Theme.of(context).colorScheme.secondary,
                  prefixIcon: const Icon(Icons.smart_toy),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 选择提供商（禁用编辑）
            Text(
              S.of(context).provider,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(24.0),
              ),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.business_rounded,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedProvider,
                      underline: const SizedBox(),
                      items:
                          [selectedProvider].map((provider) {
                            return DropdownMenuItem<String>(
                              value: provider,
                              child: Text(provider),
                            );
                          }).toList(),
                      onChanged: null, // 禁用更改
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // API类型（禁用编辑）
            Text(
              S.of(context).apiType,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(24.0),
              ),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.category_rounded,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: widget.bot.apiType,
                      underline: const SizedBox(),
                      items:
                          [widget.bot.apiType].map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                      onChanged: null, // 禁用更改
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // API地址（禁用编辑）
            Text(
              S.of(context).apiAddress,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                // 设置初始值
                controller: baseURLController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.link_rounded),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                enabled: false, // 禁用编辑
              ),
            ),
            const SizedBox(height: 16),

            // API密钥（禁用编辑）
            Text(
              S.of(context).apiKey,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.key_rounded),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                enabled: false, // 禁用编辑
                obscureText: true,
              ),
            ),
            const SizedBox(height: 16),

            // 选择模型（禁用编辑）
            Text(
              S.of(context).model,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(24.0),
              ),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Theme.of(context).disabledColor,
                  ), // 添加模型图标
                  const SizedBox(width: 16), // 添
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedModel,
                      underline: const SizedBox(),
                      items:
                          [selectedModel].map((model) {
                            return DropdownMenuItem<String>(
                              value: model,
                              child: Text(model),
                            );
                          }).toList(),
                      onChanged: null, // 禁用更改
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 系统提示词（允许编辑）
            Text(
              S.of(context).systemPrompt,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                controller: systemPromptController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
                maxLines: 5,
              ),
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
              // 显示成功提示
              _showSnackBar(
                S.of(context).botUpdated(nameController.text.trim()),
              );
            } else {
              _showSnackBar(S.of(context).fillRequiredFields);
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

  // 显示提示信息
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
