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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

          // 个人信息分组
          Container(
            margin: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    '个人信息',
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 名称区域
                _buildSettingItem(
                  context,
                  Icons.person_rounded,
                  S.of(context).name,
                  _name,
                  _showEditNameDialog,
                ),
              ],
            ),
          ),

          // 外观设置分组
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    '系统设置',
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 主题设置
                _buildSettingItem(
                  context,
                  Icons.brightness_6_rounded,
                  S.of(context).themeSettings,
                  _themeMode == ThemeMode.system
                      ? S.of(context).followSystem
                      : _themeMode == ThemeMode.light
                      ? S.of(context).lightMode
                      : S.of(context).darkMode,
                  _showThemeOptions,
                ),
                const SizedBox(height: 8.0),
                // 语言设置
                _buildSettingItem(
                  context,
                  Icons.language_rounded,
                  S.of(context).languageSettings,
                  getLanguageName(_language),
                  _showLanguageOptions,
                ),
                const SizedBox(height: 8.0),
                // 字体大小设置
                _buildSettingItem(
                  context,
                  Icons.text_fields_rounded,
                  S.of(context).fontSizeSettings,
                  S.of(context).adjustAppFontSize,
                  _showFontSizeDialog,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                    right: 8.0,
                    top: 4.0,
                  ),
                  child: Slider(
                    value: _fontSize,
                    min: 12.0,
                    max: 24.0,
                    divisions: 12,
                    activeColor: Theme.of(context).colorScheme.onSurface,
                    inactiveColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
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
              ],
            ),
          ),

          // 帮助与支持分组
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    '帮助与支持',
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 帮助与反馈
                _buildSettingItem(
                  context,
                  Icons.help_rounded,
                  S.of(context).helpAndFeedback,
                  S.of(context).provideFeedback,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FeedbackPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8.0),
                // 关于
                _buildSettingItem(
                  context,
                  Icons.info_rounded,
                  S.of(context).about,
                  S.of(context).version,
                  _showCustomAboutDialog,
                ),
              ],
            ),
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
              decoration: InputDecoration(
                hintText: S.of(context).enterBotName,
                hintStyle: TextStyle(
                  fontSize: _fontSize,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
                prefixIcon: Icon(
                  Icons.person_rounded,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(width: 0, style: BorderStyle.none),
                  borderRadius: BorderRadius.all(Radius.circular(24.0)),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.secondary,
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
    final themes = [
      {
        'title': Text(S.of(context).followSystem),
        'mode': ThemeMode.system,
        'icon': Icons.brightness_6_rounded,
      },
      {
        'title': Text(S.of(context).lightMode),
        'mode': ThemeMode.light,
        'icon': Icons.brightness_5_rounded,
      },
      {
        'title': Text(S.of(context).darkMode),
        'mode': ThemeMode.dark,
        'icon': Icons.brightness_2_rounded,
      },
    ];
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
                          ...themes
                              .map(
                                (theme) => RadioListTile<ThemeMode>(
                                  title: Row(
                                    children: [
                                      Icon(theme['icon'] as IconData),
                                      const SizedBox(width: 12),
                                      theme['title'] as Text,
                                    ],
                                  ),
                                  activeColor:
                                      Theme.of(context).colorScheme.onSurface,
                                  value: theme['mode'] as ThemeMode,
                                  groupValue: _themeMode,
                                  onChanged: (value) {
                                    setState(() {
                                      _themeMode = value!;
                                    });
                                    _saveProfile(); // 保存设置

                                    // 通知应用程序更新主题
                                    ProfileService.notifyThemeChanged(
                                      _themeMode,
                                    );
                                    Navigator.pop(context);
                                  },
                                ),
                              )
                              .toList(),
                          SizedBox(height: 24),
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
                        divisions: 12,
                        activeColor: Theme.of(context).colorScheme.onSurface,
                        inactiveColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
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
                          SizedBox(height: 24),
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

  // 构建设置项目
  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool showSlider = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24.0,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: _fontSize - 2,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (!showSlider)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.0,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
          ],
        ),
      ),
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
