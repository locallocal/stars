import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/providers/providers.dart';
import 'package:bubble/model/providers.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/pages/common/logo.dart';
import 'package:bubble/pages/common/common.dart';

class AddBotPage extends StatefulWidget {
  final Function(Bot) onBotAdded;

  const AddBotPage({super.key, required this.onBotAdded});

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
      showSnackBar(context, '请输入API地址');
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

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;

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
      body: SingleChildScrollView(
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
            _buildNameInput(fontSize),
            const SizedBox(height: 32),

            // provider
            Text(
              S.of(context).selectProvider,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildProviderInput(fontSize),
            // sub provider
            if (providerController.text == 'HuggingFace') ...[
              const SizedBox(height: 16),
              _buildSubProviderInput(fontSize),
            ],
            const SizedBox(height: 16),

            // api type
            Text(
              S.of(context).apiType,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildApiTypeSelector(fontSize),
            const SizedBox(height: 16),

            // provider base url
            Text(
              S.of(context).apiAddress,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildApiAddressInput(fontSize),
            const SizedBox(height: 16),

            // api key
            Text(
              S.of(context).apiKey,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildApiKeyInput(fontSize),
            const SizedBox(height: 16),

            // provider models
            Text(
              S.of(context).selectModel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildModelsInput(fontSize),
            const SizedBox(height: 16),

            // system prompt
            Text(
              S.of(context).systemPrompt,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildSystemPromptInput(fontSize),
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
              final providerInfo = providersInfo[providerController.text];
              final apiType = providerInfo?['api_type'] as String;
              // 使用baseURLController的值而不是providerInfo中的base_url
              final baseURL = baseURLController.text.trim();

              final newBot = Bot(
                id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text.trim(),
                avatar: avatarImage?.path ?? '',
                provider: providerController.text,
                baseURL: baseURL, // 使用用户输入的baseURL
                apiKey: apiKeyController.text.trim(),
                apiType: apiType,
                model: selectedModelController.text,
                systemPrompt: systemPromptController.text.trim(),
                createTimestamp: DateTime.now(),
                modifyTimestamp: DateTime.now(),
              );

              widget.onBotAdded(newBot);
              Navigator.pop(context);
            } else {
              showSnackBar(context, S.of(context).fillRequiredFields);
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

  Widget _buildNameInput(double? fontSize) {
    return TextField(
      controller: nameController,
      decoration: InputDecoration(
        hintText: S.of(context).enterBotName,
        hintStyle: TextStyle(fontSize: fontSize),
        prefixIcon: const Icon(Icons.smart_toy_rounded),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        filled: true,
        fillColor: Theme.of(context).colorScheme.secondary,
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
        hintText: S.of(context).enterBotName,
        hintStyle: TextStyle(fontSize: fontSize),
        prefixIcon: const Icon(Icons.business_rounded),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        filled: true,
        fillColor: Theme.of(context).colorScheme.secondary,
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
                                  groupValue: providerController.text,
                                  onChanged: (value) {
                                    _onProviderChanged(value);
                                    Navigator.pop(context);
                                  },
                                );
                              }).toList(),
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
        hintStyle: TextStyle(fontSize: fontSize),
        prefixIcon: const Icon(Icons.business_rounded),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        filled: true,
        fillColor: Theme.of(context).colorScheme.secondary,
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
                                  groupValue: subProviderController.text,
                                  onChanged: (value) {
                                    _onSubProviderChanged(value);
                                    Navigator.pop(context);
                                  },
                                );
                              }).toList(),
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
        hintText: 'api类型',
        hintStyle: TextStyle(fontSize: fontSize),
        prefixIcon: const Icon(Icons.category_rounded),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        filled: true,
        fillColor: Theme.of(context).colorScheme.secondary,
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
                                  groupValue: apiTypeController.text,
                                  onChanged: (value) {
                                    apiTypeController.text = value!;
                                    Navigator.pop(context);
                                  },
                                );
                              }).toList(),
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
        hintText: S.of(context).enterApiAddress,
        hintStyle: TextStyle(fontSize: fontSize),
        prefixIcon: const Icon(Icons.link_rounded),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        filled: true,
        fillColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  // 构建API密钥输入框
  Widget _buildApiKeyInput(double? fontSize) {
    return TextField(
      controller: apiKeyController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: S.of(context).enterApiKey,
        hintStyle: TextStyle(fontSize: fontSize),
        prefixIcon: const Icon(Icons.key_rounded),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        filled: true,
        fillColor: Theme.of(context).colorScheme.secondary,
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
        hintStyle: TextStyle(fontSize: fontSize),
        prefixIcon: const Icon(Icons.auto_awesome_rounded),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        filled: true,
        fillColor: Theme.of(context).colorScheme.secondary,
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
                                        groupValue:
                                            selectedModelController.text,
                                        onChanged: (value) {
                                          selectedModelController.text = value!;
                                          Navigator.pop(context);
                                        },
                                      );
                                    }).toList(),
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
    );
  }
}
