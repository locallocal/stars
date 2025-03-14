import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bubble/model/model.dart';

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
      text:
          widget.bot.systemPrompt.isNotEmpty
              ? widget.bot.systemPrompt
              : '你是一个有用的AI助手，请用中文回答问题。',
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          '编辑智能体',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0, // 防止滚动时背景色变化
        elevation: 0, // 移除阴影
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('删除机器人'),
                      content: Text('确定要删除 "${widget.bot.name}" 吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // 关闭对话框
                            widget.onBotDeleted();
                            Navigator.pop(context); // 返回联系人列表
                          },
                          child: const Text('删除'),
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
                  radius: 50,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage:
                      avatarImage != null ? FileImage(avatarImage!) : null,
                  child:
                      avatarImage == null
                          ? const Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.blue,
                          )
                          : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('点击更换头像')),
            const SizedBox(height: 24),

            // 智能体名称
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '智能体名称',
                prefixIcon: Icon(Icons.smart_toy),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 选择提供商（禁用编辑）
            const Text('提供商:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
            const SizedBox(height: 16),

            // API地址（禁用编辑）
            const Text('API地址:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              // 设置初始值
              controller: baseURLController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.link),
                border: const OutlineInputBorder(),
                filled: true,
              ),
              enabled: false, // 禁用编辑
            ),
            const SizedBox(height: 16),

            // API密钥（禁用编辑）
            const Text('API秘钥:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: apiKeyController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.key),
                border: const OutlineInputBorder(),
                filled: true,
              ),
              obscureText: true,
              enabled: false, // 禁用编辑
            ),
            const SizedBox(height: 16),

            // 选择模型（禁用编辑）
            const Text('模型:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
            const SizedBox(height: 16),

            // 系统提示词（允许编辑）
            const Text('系统提示词:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: systemPromptController,
              decoration: const InputDecoration(
                hintText: '输入系统提示词...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('智能体 "${nameController.text.trim()}" 已更新'),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              );
            } else {
              // 显示错误提示
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('请填写智能体名称')));
            }
          },
          child: const Text('保存修改'),
        ),
      ),
    );
  }
}
