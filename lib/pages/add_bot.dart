import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/models/chat_models.dart';
import 'package:bubble/model/providers.dart';
import 'package:bubble/generated/l10n.dart';

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
  final systemPromptController = TextEditingController();
  final customProviderController = TextEditingController();

  bool _isLoadingModels = false; 
  String selectedProvider = 'OpenAI';
  bool isCustomProvider = false;
  String selectedModel = '';
  File? avatarImage;

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
  }// 添加加载状态变量

  // 添加获取模型列表的方法
  Future<void> _fetchModels() async {
    if (apiKeyController.text.trim().isEmpty) {
      _showSnackBar(S.of(context).pleaseEnterApiKey);
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

      if (models.isNotEmpty && mounted) { 
        setState(() {
          modelsByProvider[selectedProvider]?['models'] = models;
          selectedModel = models.first;
        });
        _showSnackBar(S.of(context).modelsRetrievedSuccess(models.length.toString()));
      } else if (mounted){
        _showSnackBar(S.of(context).noModelsRetrieved);
      }
    } catch (e) {
      _showSnackBar(e.toString());
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
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          S.of(context).addBot,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 64,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage:
                      avatarImage != null ? FileImage(avatarImage!) : null,
                  child:
                      avatarImage == null
                          ? Icon(
                            Icons.smart_toy_rounded,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface,
                          )
                          : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: S.of(context).enterBotName,
                  hintStyle: TextStyle(
                    fontSize: fontSize,
                  ),
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

            Text(
              S.of(context).selectProvider,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (!isCustomProvider)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<String>(
                        borderRadius: BorderRadius.circular(24.0),
                        isExpanded: true,
                        value: selectedProvider,
                        underline: const SizedBox(),
                        items: [
                          ...providers.map((provider) {
                            return DropdownMenuItem<String>(
                              value: provider,
                              child: Text(
                                provider,
                                style: TextStyle(
                                  fontSize: fontSize,
                                ),
                              ),
                            );
                          }),
                          DropdownMenuItem<String>(
                            value: 'custom',
                            child: Text(
                              S.of(context).customProvider,
                              style: TextStyle(
                                fontSize: fontSize,
                              ),
                            ),
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
                    ),
                  ],
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
                        decoration: InputDecoration(
                          hintText: S.of(context).enterProviderName,
                          prefixIcon: const Icon(Icons.business),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                isCustomProvider = false;
                                selectedProvider = providers.first;
                                _onProviderChanged(selectedProvider);
                              });
                            },
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
                ],
              ),
            const SizedBox(height: 16),

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
                  const Icon(Icons.category_outlined),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<String>(
                      borderRadius: BorderRadius.circular(24.0),
                      isExpanded: true,
                      value:
                          modelsByProvider[selectedProvider]?['api_type']
                              as String? ??
                          Bot.apiTypeOpenAI,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem<String>(
                          value: Bot.apiTypeOpenAI,
                          child: Text(
                            'OpenAI',
                            style: TextStyle(
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: Bot.apiTypeAnthropic,
                          child: Text(
                            'Anthropic',
                            style: TextStyle(
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: Bot.apiTypeGemini,
                          child: Text(
                            'Gemini',
                            style: TextStyle(
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: Bot.apiTypeDeepseek,
                          child: Text(
                            'DeepSeek',
                            style: TextStyle(
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: Bot.apiTypeOllama,
                          child: Text(
                            'Ollama',
                            style: TextStyle(
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: Bot.apiTypeHuggingface,
                          child: Text(
                            'HuggingFace',
                            style: TextStyle(
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: Bot.apiTypeGrok,
                          child: Text(
                            'Grok',
                            style: TextStyle(
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: Bot.apiTypeVolcanoEngine,
                          child: Text(
                            'VolcanoEngine',
                            style: TextStyle(
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: Bot.apiTypeTencent,
                          child: Text(
                            'Tencent',
                            style: TextStyle(
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: Bot.apiTypeBaidu,
                          child: Text(
                            'Baidu',
                            style: TextStyle(
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                      ],
                      onChanged:
                          isCustomProvider
                              ? (value) {
                                if (value != null) {
                                  setState(() {
                                    modelsByProvider[selectedProvider]?['api_type'] =
                                        value;
                                  });
                                }
                              }
                              : null, // 非自定义供应商时禁用更改
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 添加供应商地址输入
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
                controller: baseURLController,
                decoration: InputDecoration(
                  hintText: S.of(context).enterApiAddress,
                  prefixIcon: const Icon(Icons.link),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {},
              ),
            ),
            const SizedBox(height: 16),

            // API密钥
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
                decoration: InputDecoration(
                  hintText: S.of(context).enterApiKey,
                  prefixIcon: const Icon(Icons.key),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon:
                      _isLoadingModels
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                          : IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: S.of(context).fetchModelList,
                            onPressed: _fetchModels,
                          ),
                ),
                obscureText: true,
              ),
            ),
            const SizedBox(height: 16),

            // 选择模型
            Text(
              S.of(context).selectModel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<String>(
                      borderRadius: BorderRadius.circular(24.0),
                      isExpanded: true,
                      value:
                          currentModels.contains(selectedModel)
                              ? selectedModel
                              : (currentModels.isNotEmpty
                                  ? currentModels.first
                                  : ''),
                      hint: Text(
                        S.of(context).fetchModelListFirst,
                        style: TextStyle(
                          fontSize: fontSize,
                        ),
                      ),
                      underline: const SizedBox(),
                      items:
                          currentModels.isEmpty
                              ? [
                                DropdownMenuItem<String>(
                                  value: '',
                                  child: Text(
                                    S.of(context).fetchModelListFirst,
                                    style: TextStyle(
                                      fontSize: fontSize,
                                    ),
                                  ),
                                ),
                              ]
                              : currentModels.map((model) {
                                return DropdownMenuItem<String>(
                                  value: model,
                                  child: Text(
                                    model,
                                    style: TextStyle(
                                      fontSize: fontSize,
                                    ),
                                  ),
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 系统提示词
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
                decoration: InputDecoration(
                  hintText: S.of(context).enterSystemPrompt,
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
              _showSnackBar(S.of(context).botAddedSuccess(nameController.text.trim()));
            } else {
              _showSnackBar(S.of(context).fillRequiredFields);
            }
          },
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

  // 显示提示信息
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
