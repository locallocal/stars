import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bubble/services/profile_service.dart';
import 'package:bubble/utils/utils.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/l10n/app_localizations.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/pages/user_agreement.dart';
import 'package:bubble/pages/privacy_policy.dart';
import 'package:bubble/pages/feedback_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Profile? _profile;
  bool _isLoading = true;
  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'zh_CN'; // 语言设置

  // 随机英文名称列表
  final List<String> _randomNames = [
    'Alex',
    'Blake',
    'Casey',
    'Dana',
    'Eden',
    'Finley',
    'Gray',
    'Harper',
    'Jordan',
    'Kelly',
    'Logan',
    'Morgan',
    'Noah',
    'Parker',
    'Quinn',
    'Riley',
    'Skyler',
    'Taylor',
    'Avery',
    'Bailey',
  ];

  // 获取随机英文名称
  String get _randomName => _randomNames[Random().nextInt(_randomNames.length)];
  // 获取用户名
  String get _name => _profile?.name ?? _randomName;
  // 获取头像路径
  String get _avatar => _profile?.avatar ?? "";
  // 获取字体大小
  double get _fontSize => _profile?.fontSize ?? 16.0;

  @override
  void initState() {
    super.initState();
    _loadProfileInfo();
  }

  Future<void> _loadProfileInfo() async {
    setState(() {
      _isLoading = true;
    });

    final loadedProfile = await ProfileService.getProfile();

    setState(() {
      _profile = loadedProfile;
      _themeMode = intToThemeMode(loadedProfile.themeMode);
      _language = loadedProfile.language; // 加载语言设置
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        // 修复可空属性赋值问题
        if (_profile != null) {
          _profile = Profile(
            name: _name,
            avatar: pickedFile.path,
            fontSize: _fontSize,
            language: _language,
            themeMode: themeModeToInt(_themeMode),
            createTimestamp: _profile!.createTimestamp,
            modifyTimestamp: DateTime.now(),
          );
          _saveProfile(); // 保存头像设置
        }
      });
    }
  }

  // 保存设置
  Future<void> _saveProfile() async {
    if (_profile == null) return;

    final profile = Profile(
      name: _name,
      avatar: _avatar,
      fontSize: _fontSize,
      themeMode: themeModeToInt(_themeMode),
      language: _language, // 添加语言设置
      createTimestamp: _profile!.createTimestamp,
      modifyTimestamp: DateTime.now(),
    );
    await ProfileService.updateProfile(profile);
    _profile = profile; // 更新本地缓存
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.surface),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          S.of(context).profile,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSize),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0, // 防止滚动时背景色变化
        elevation: 0, // 移除阴影
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          // 头像区域
          Padding(
            padding: const EdgeInsets.only(top: 30.0, bottom: 20.0),
            child: Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      backgroundImage:
                          _avatar.isNotEmpty
                              ? FileImage(File(_avatar))
                              : const AssetImage(
                                    'assets/images/profile/avatar.png',
                                  )
                                  as ImageProvider,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // 名称区域
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: Text(
              S.of(context).name,
              style: TextStyle(fontSize: _fontSize),
            ),
            subtitle: Text(_name, style: TextStyle(fontSize: _fontSize - 2)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              _showEditNameDialog();
            },
          ),
          Divider(color: Theme.of(context).dividerColor.withOpacity(0.3)),

          // 主题切换
          ListTile(
            leading: const Icon(Icons.brightness_6_rounded),
            title: Text(
              S.of(context).themeSettings,
              style: TextStyle(fontSize: _fontSize),
            ),
            subtitle: Text(
              _themeMode == ThemeMode.system
                  ? S.of(context).followSystem
                  : _themeMode == ThemeMode.light
                  ? S.of(context).lightMode
                  : S.of(context).darkMode,
              style: TextStyle(fontSize: _fontSize - 2),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              _showThemeOptions();
            },
          ),

          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(
              S.of(context).languageSettings,
              style: TextStyle(fontSize: _fontSize),
            ),
            subtitle: Text(
              getLanguageName(_language),
              style: TextStyle(fontSize: _fontSize - 2),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              _showLanguageOptions();
            },
          ),

          ListTile(
            leading: const Icon(Icons.text_fields_rounded),
            title: Text(
              S.of(context).fontSizeSettings,
              style: TextStyle(fontSize: _fontSize),
            ),
            subtitle: Text(
              S.of(context).adjustAppFontSize,
              style: TextStyle(fontSize: _fontSize - 2),
            ),
            onTap: () {
              _showFontSizeDialog();
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Slider(
              value: _fontSize,
              min: 12.0,
              max: 24.0,
              divisions: 6,
              activeColor: Theme.of(context).colorScheme.onSurface,
              inactiveColor: Theme.of(context).colorScheme.secondary,
              label: _fontSize.round().toString(),
              onChanged: (value) {
                setState(() {
                  _profile = Profile(
                    name: _name,
                    avatar: _avatar,
                    fontSize: value,
                    themeMode: themeModeToInt(_themeMode),
                    language: _language,
                    createTimestamp: _profile!.createTimestamp,
                    modifyTimestamp: DateTime.now(),
                  );
                });
                _saveProfile(); // 保存设置
              },
            ),
          ),
          Divider(color: Theme.of(context).dividerColor.withOpacity(0.3)),

          // 帮助与反馈
          ListTile(
            leading: const Icon(Icons.help_rounded),
            title: Text(
              S.of(context).helpAndFeedback,
              style: TextStyle(fontSize: _fontSize),
            ),
            subtitle: Text(
              S.of(context).provideFeedback,
              style: TextStyle(fontSize: _fontSize - 2),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackPage()),
              );
            },
          ),

          // 关于
          ListTile(
            leading: const Icon(Icons.info_rounded),
            title: Text(
              S.of(context).about,
              style: TextStyle(fontSize: _fontSize),
            ),
            subtitle: Text(
              S.of(context).version,
              style: TextStyle(fontSize: _fontSize - 2),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              // 显示自定义关于信息对话框
              _showCustomAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  // 显示编辑名称对话框
  void _showEditNameDialog() {
    final TextEditingController controller = TextEditingController(text: _name);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Center(
              child: Text(
                S.of(context).editName,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            content: TextField(
              controller: controller,
              style: TextStyle(fontSize: _fontSize),
              decoration: InputDecoration(
                hintText: S.of(context).enterNewName,
                labelStyle: TextStyle(fontSize: _fontSize - 2),
                hintStyle: TextStyle(fontSize: _fontSize - 2),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  S.of(context).cancel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _profile = Profile(
                      name:
                          controller.text.trim().isEmpty
                              ? _randomName
                              : controller.text.trim(),
                      avatar: _avatar,
                      fontSize: _fontSize,
                      themeMode: themeModeToInt(_themeMode),
                      language: _language,
                      createTimestamp: _profile!.createTimestamp,
                      modifyTimestamp: DateTime.now(),
                    );
                  });
                  _saveProfile(); // 保存设置
                  Navigator.pop(context);
                },
                child: Text(
                  S.of(context).save,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // 显示主题选项
  void _showThemeOptions() {
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
                        S.of(context).selectTheme,
                        style: TextStyle(
                          fontSize: _fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<ThemeMode>(
                            title: Text(S.of(context).followSystem),
                            activeColor:
                                Theme.of(context).colorScheme.onSurface,
                            value: ThemeMode.system,
                            groupValue: _themeMode,
                            onChanged: (value) {
                              setState(() {
                                _themeMode = value!;
                              });
                              _saveProfile(); // 保存设置

                              // 通知应用程序更新主题
                              ProfileService.notifyThemeChanged(_themeMode);
                              Navigator.pop(context);
                            },
                          ),
                          RadioListTile<ThemeMode>(
                            title: Text(S.of(context).lightMode),
                            activeColor:
                                Theme.of(context).colorScheme.onSurface,
                            value: ThemeMode.light,
                            groupValue: _themeMode,
                            onChanged: (value) {
                              setState(() {
                                _themeMode = value!;
                              });
                              _saveProfile();

                              ProfileService.notifyThemeChanged(_themeMode);
                              Navigator.pop(context);
                            },
                          ),
                          RadioListTile<ThemeMode>(
                            title: Text(S.of(context).darkMode),
                            activeColor:
                                Theme.of(context).colorScheme.onSurface,
                            value: ThemeMode.dark,
                            groupValue: _themeMode,
                            onChanged: (value) {
                              setState(() {
                                _themeMode = value!;
                              });
                              _saveProfile();

                              ProfileService.notifyThemeChanged(_themeMode);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 显示字体大小对话框
  void _showFontSizeDialog() {
    double tempFontSize = _fontSize;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Center(
                    child: Text(
                      S.of(context).adjustFontSize,
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        S.of(context).previewText,
                        style: TextStyle(fontSize: tempFontSize),
                      ),
                      const SizedBox(height: 20),
                      Slider(
                        value: tempFontSize,
                        min: 12.0,
                        max: 24.0,
                        divisions: 6,
                        activeColor: Theme.of(context).colorScheme.onSurface,
                        inactiveColor: Theme.of(context).colorScheme.secondary,
                        label: tempFontSize.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            tempFontSize = value;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        S.of(context).cancel,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        this.setState(() {
                          _profile = Profile(
                            name: _name,
                            avatar: _avatar,
                            fontSize: tempFontSize,
                            language: _language,
                            themeMode: themeModeToInt(_themeMode),
                            createTimestamp: _profile!.createTimestamp,
                            modifyTimestamp: DateTime.now(),
                          );
                        });
                        _saveProfile(); // 保存设置
                        Navigator.pop(context);
                      },
                      child: Text(
                        S.of(context).save,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  // 显示自定义关于对话框
  void _showCustomAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Center(
              child: Text(
                S.of(context).aboutApp,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BubbleLogo(size: 60),
                const SizedBox(height: 24),
                Text(
                  S.of(context).appTitle,
                  style: TextStyle(
                    fontSize: _fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context).version,
                  style: TextStyle(fontSize: _fontSize - 2),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  S.of(context).appDescription,
                  style: TextStyle(fontSize: _fontSize),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 16),
                Text(
                  S.of(context).copyright,
                  style: TextStyle(fontSize: _fontSize),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserAgreementPage(),
                          ),
                        );
                      },
                      child: Text(
                        S.of(context).userAgreement,
                        style: TextStyle(
                          fontSize: _fontSize,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyPage(),
                          ),
                        );
                      },
                      child: Text(
                        S.of(context).privacyPolicy,
                        style: TextStyle(
                          fontSize: _fontSize,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  S.of(context).confirm,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: _fontSize,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // 显示语言选项
  void _showLanguageOptions() {
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
                        S.of(context).selectLanguage,
                        style: TextStyle(
                          fontSize: _fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLanguageOption('zh_CN', '简体中文'),
                          _buildLanguageOption('en_US', 'English'),
                          _buildLanguageOption('zh_TW', '繁體中文'),
                          _buildLanguageOption('ja_JP', '日本語'),
                          _buildLanguageOption('fr_FR', 'Français'),
                          _buildLanguageOption('de_DE', 'Deutsch'),
                          _buildLanguageOption('ko_KR', '한국어'),
                          _buildLanguageOption('ru_RU', 'Русский'),
                          _buildLanguageOption('es_ES', 'Español'),
                          _buildLanguageOption('hi_IN', 'हिन्दी'),
                          _buildLanguageOption('pt_BR', 'Português'),
                          _buildLanguageOption('it_IT', 'Italiano'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 构建语言选项
  Widget _buildLanguageOption(String code, String name) {
    return RadioListTile<String>(
      title: Text(name),
      activeColor: Theme.of(context).colorScheme.onSurface,
      value: code,
      groupValue: _language,
      onChanged: (value) {
        setState(() {
          _language = value!;
        });
        _saveProfile(); // 保存设置

        // 通知应用程序更新语言
        ProfileService.notifyLanguageChanged(_language);
        Navigator.pop(context);
      },
    );
  }
}

// 自定义Logo组件
class BubbleLogo extends StatelessWidget {
  final double size;

  const BubbleLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/icon/app_icon.png',
          width: size * 0.7,
          height: size * 0.7,
        ),
      ),
    );
  }
}
