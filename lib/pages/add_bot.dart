import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/chat_models.dart';

class AddBotPage extends StatefulWidget {
  final Function(Bot) onBotAdded;

  const AddBotPage({super.key, required this.onBotAdded});

  @override
  State<AddBotPage> createState() => _AddBotPageState();
}

class _AddBotPageState extends State<AddBotPage> {
  final nameController = TextEditingController();
  final apiKeyController = TextEditingController();
  final baseURLController = TextEditingController();
  final systemPromptController = TextEditingController(
    text: '你是一个有用的AI助手，请用中文回答问题。',
  );
  final customProviderController = TextEditingController(); // 添加自定义供应商控制器

  String selectedProvider = 'OpenAI';
  bool isCustomProvider = false; // 添加标志位
  String selectedModel = 'gpt-3.5-turbo';
  File? avatarImage;

  final providers = [
    'OpenAI',
    'Anthropic',
    'Gemini',
    'DeepSeek',
    'Ollama',
    'HuggingFace',
    'ChatGLM',
    'Grok',
    '百度文心',
  ];
  final modelsByProvider = {
    'OpenAI': {
      'api_type': Bot.apiTypeOpenAI,
      'base_url': 'https://api.openai.com',
      'models': [],
    },
    'Anthropic': {
      'api_type': Bot.apiTypeAnthropic,
      'base_url': 'https://api.anthropic.com',
    },
    'Gemini': {
      'api_type': Bot.apiTypeGemini,
      'base_url': 'https://generativelanguage.googleapis.com',
    },
    'DeepSeek': {
      'api_type': Bot.apiTypeDeepseek,
      'base_url': 'https://api.deepseek.com',
    },
    'Ollama': {
      'api_type': Bot.apiTypeOllama,
      'base_url': 'http://localhost:11434',
    },
    'HuggingFace': {
      'api_type': Bot.apiTypeHuggingface,
      'base_url': 'https://api-inference.huggingface.co',
    },
    'ChatGLM': {
      'api_type': Bot.apiTypeOpenAI,
      'base_url': 'http://localhost:8000',
    },
    'Grok': {'api_type': Bot.apiTypeGrok, 'base_url': 'https://api.grok.ai'},
    '百度文心': {
      'api_type': Bot.apiTypeOpenAI,
      'base_url': 'https://aip.baidubce.com',
    },
  };

  List<String> get currentModels {
    final providerInfo = modelsByProvider[selectedProvider];
    if (providerInfo != null && providerInfo.containsKey('models')) {
      return List<String>.from(providerInfo['models'] as List);
    }
    return [];
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

  bool _isLoadingModels = false; // 添加加载状态变量

  // 添加获取模型列表的方法
  Future<void> _fetchModels() async {
    if (apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入API密钥')),
      );
      return;
    }

    setState(() {
      _isLoadingModels = true;
    });

    try {
      final providerInfo = modelsByProvider[selectedProvider];
      final apiType = providerInfo?['api_type'] as String;
      final baseURL = baseURLController.text.trim(); // 使用baseURLController的值

      // 创建临时Bot对象
      final tempBot = Bot(
        id: 'temp_bot',
        name: 'Temp Bot',
        avatar: '',
        provider: selectedProvider,
        baseURL: baseURL, // 使用用户输入的baseURL
        apiKey: apiKeyController.text.trim(),
        apiType: apiType,
        model: '',
        systemPrompt: '',
        createTimestamp: DateTime.now(),
        modifyTimestamp: DateTime.now(),
      );

      // 创建ChatModel并获取模型列表
      final chatModel = ChatModel.create(tempBot);
      final models = await chatModel.listModels();

      if (models.isNotEmpty) {
        setState(() {
          modelsByProvider[selectedProvider]?['models'] = models;
          selectedModel = models.first;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功获取${models.length}个模型'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('未获取到模型列表'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('获取模型列表失败: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() {
        _isLoadingModels = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // 初始化baseURLController
    baseURLController.text =
        modelsByProvider[selectedProvider]?['base_url'] as String? ?? '';
  }

  @override
  void dispose() {
    // 释放控制器资源
    nameController.dispose();
    apiKeyController.dispose();
    baseURLController.dispose();
    systemPromptController.dispose();
    customProviderController.dispose();
    super.dispose();
  }

  // 修改onChanged方法
  void _onProviderChanged(String? value) {
    if (value != null) {
      setState(() {
        selectedProvider = value;
        // 更新baseURLController的值
        baseURLController.text =
            modelsByProvider[selectedProvider]?['base_url'] as String? ?? '';

        final models = currentModels;
        selectedModel = models.isNotEmpty ? models[0] : '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('添加智能体', style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
        )),
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                  backgroundColor: Theme.of(context).colorScheme.onSurface,
                  backgroundImage:
                      avatarImage != null ? FileImage(avatarImage!) : null,
                  child:
                      avatarImage == null
                          ? const Icon(
                            Icons.add_a_photo,
                            size: 40,
                          )
                          : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('点击添加头像'),
            ),
            const SizedBox(height: 24),

            // 机器人名称
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: '名称...',
                  fillColor: Theme.of(context).colorScheme.secondary,
                  focusColor: Theme.of(context).colorScheme.secondary,
                  hoverColor: Theme.of(context).colorScheme.secondary,
                  prefixIcon: const Icon(Icons.smart_toy),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // 选择提供商
            const Text('选择提供商:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (!isCustomProvider)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  borderRadius: BorderRadius.circular(24.0),
                  isExpanded: true,
                  value: selectedProvider,
                  underline: const SizedBox(),
                  items: [
                    ...providers.map((provider) {
                      return DropdownMenuItem<String>(
                        value: provider,
                        child: Text(provider),
                      );
                    }),
                    const DropdownMenuItem<String>(
                      value: 'custom',
                      child: Text('自定义供应商...'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == 'custom') {
                      setState(() {
                        isCustomProvider = true;
                        customProviderController.text = '';
                      });
                    } else if (value != null) {
                      _onProviderChanged(value);
                    }
                  },
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: TextField(
                        controller: customProviderController,
                        decoration: const InputDecoration(
                          hintText: '输入供应商名称...',
                          prefixIcon: Icon(Icons.shop),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedProvider = value;
                            if (!modelsByProvider.containsKey(value)) {
                              modelsByProvider[value] = {
                                'api_type': Bot.apiTypeOpenAI,
                                'base_url': '',
                                'models': [],
                              };
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        isCustomProvider = false;
                        selectedProvider = providers.first;
                        _onProviderChanged(selectedProvider);
                      });
                    },
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // 添加供应商地址输入
            const Text('API地址:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                controller: baseURLController,
                decoration: const InputDecoration(
                  hintText: '输入API地址...',
                  prefixIcon: Icon(Icons.link),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  // 当用户修改地址时，更新modelsByProvider中的base_url
                  // 不做任何验证
                },
              ),
            ),
            const SizedBox(height: 16),

            // API密钥
            const Text('API密钥:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                controller: apiKeyController,
                decoration: InputDecoration(
                  hintText: '输入API密钥...',
                  prefixIcon: const Icon(Icons.key),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  suffixIcon:
                      _isLoadingModels
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: '获取模型列表',
                            onPressed: _fetchModels,
                          ),
                ),
                obscureText: true,
              ),
            ),
            const SizedBox(height: 16),

            // 选择模型
            const Text('选择模型:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value:
                    currentModels.contains(selectedModel)
                        ? selectedModel
                        : (currentModels.isNotEmpty ? currentModels.first : ''),
                hint: const Text('请先获取模型列表'),
                underline: const SizedBox(),
                items:
                    currentModels.isEmpty
                        ? [
                          DropdownMenuItem<String>(
                            value: '',
                            child: Text(
                              '请先获取模型列表',
                              style: TextStyle(
                                fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                              ),
                            ),
                          ),
                        ]
                        : currentModels.map((model) {
                          return DropdownMenuItem<String>(
                            value: model,
                            child: Text(model),
                          );
                        }).toList(),
                onChanged: (value) {
                  if (value != null && value.isNotEmpty) {
                    setState(() {
                      selectedModel = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // 系统提示词
            const Text('系统提示词:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                controller: systemPromptController,
                decoration: const InputDecoration(
                  hintText: '输入系统提示词...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12
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
            if (nameController.text.trim().isNotEmpty &&
                apiKeyController.text.trim().isNotEmpty &&
                baseURLController.text.trim().isNotEmpty) {
              final providerInfo = modelsByProvider[selectedProvider];
              final apiType = providerInfo?['api_type'] as String;
              // 使用baseURLController的值而不是providerInfo中的base_url
              final baseURL = baseURLController.text.trim();

              final newBot = Bot(
                id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text.trim(),
                avatar: avatarImage?.path ?? '',
                provider: selectedProvider,
                baseURL: baseURL, // 使用用户输入的baseURL
                apiKey: apiKeyController.text.trim(),
                apiType: apiType,
                model: selectedModel,
                systemPrompt: systemPromptController.text.trim(),
                createTimestamp: DateTime.now(),
                modifyTimestamp: DateTime.now(),
              );

              widget.onBotAdded(newBot);
              Navigator.pop(context);

              // 显示成功提示
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('智能体 "${nameController.text.trim()}" 已添加'),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              );
            } else {
              // 显示错误提示
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('请填写智能体名称、API地址和API密钥'),
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                ),
              );
            }
          },
          child: Text('添加智能体', style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
            color: Theme.of(context).colorScheme.surface,
          ),),
        ),
      ),
    );
  }
}
