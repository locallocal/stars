import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/utils/utils.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/services/stars_system_prompt.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/feedback/views/feedback_page.dart';
import 'package:stars/ui/features/profile/view_models/profile_view_model.dart';
import 'package:stars/ui/features/profile/views/privacy_policy.dart';
import 'package:stars/ui/features/profile/views/user_agreement.dart';
import 'package:stars/utils/theme.dart';

part 'profile_settings_controls.dart';
part 'profile_dialogs.dart';
part 'profile_about_section.dart';
part 'profile_logo.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.selectedSection = 0,
    this.initialProfile,
    this.onProfileSaved,
    this.viewModel,
    this.avatarPicker,
    this.applicationPromptProvider,
    required this.onOpenSkillLibrary,
    required this.onOpenMcpServers,
  });

  final int selectedSection;
  final Profile? initialProfile;
  final Future<void> Function(Profile profile)? onProfileSaved;
  final ProfileViewModel? viewModel;
  final Future<String?> Function()? avatarPicker;
  final String Function()? applicationPromptProvider;
  final VoidCallback onOpenSkillLibrary;
  final VoidCallback onOpenMcpServers;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _updateState(VoidCallback callback) => setState(callback);

  Profile? _profile;
  bool _isLoading = true;
  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'zh_CN'; // 语言设置
  ProfileViewModel? _resolvedViewModel;
  bool _loadStarted = false;
  final List<GlobalKey> _desktopSectionKeys = List<GlobalKey>.generate(
    5,
    (_) => GlobalKey(),
  );

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
  bool get _showExecutionStatus => _profile?.showExecutionStatus ?? true;
  String get _applicationInjectedPrompt =>
      (widget.applicationPromptProvider?.call() ?? currentStarsSystemPrompt())
          .trim();

  @override
  void initState() {
    super.initState();
    final initialProfile = widget.initialProfile;
    if (initialProfile == null) {
      if (widget.viewModel != null) _loadProfileInfo();
    } else {
      _profile = initialProfile;
      _themeMode = intToThemeMode(initialProfile.themeMode);
      _language = initialProfile.language;
      _isLoading = false;
      _scheduleSelectedSectionScroll();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profile != null || _loadStarted) return;
    _resolvedViewModel ??= AppScope.of(context).createProfileViewModel();
    _loadProfileInfo();
  }

  @override
  void dispose() {
    _resolvedViewModel?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSection != widget.selectedSection) {
      _scheduleSelectedSectionScroll();
    }
  }

  Future<void> _loadProfileInfo() async {
    if (_loadStarted) return;
    _loadStarted = true;
    setState(() {
      _isLoading = true;
    });

    final viewModel = widget.viewModel ?? _resolvedViewModel!;
    if (viewModel.profile == null) await viewModel.load();
    final loadedProfile = viewModel.profile;

    if (!mounted) return;
    if (loadedProfile == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _profile = loadedProfile;
      _themeMode = intToThemeMode(loadedProfile.themeMode);
      _language = loadedProfile.language; // 加载语言设置
      _isLoading = false;
    });
    _scheduleSelectedSectionScroll();
  }

  void _scheduleSelectedSectionScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !isDesktopPlatform(context)) return;

      final index = widget.selectedSection.clamp(
        0,
        _desktopSectionKeys.length - 1,
      );
      final sectionContext = _desktopSectionKeys[index].currentContext;
      if (sectionContext == null) return;

      final disableAnimations = MediaQuery.disableAnimationsOf(context);
      Scrollable.ensureVisible(
        sectionContext,
        alignment: 0.08,
        duration:
            disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _pickImage() async {
    final pickAvatar =
        widget.avatarPicker ??
        widget.viewModel?.pickAvatar ??
        _resolvedViewModel?.pickAvatar;
    final imagePath = await pickAvatar?.call();

    if (imagePath != null && mounted) {
      setState(() {
        if (_profile != null) {
          _profile = Profile(
            name: _name,
            avatar: imagePath,
            fontSize: _fontSize,
            language: _language,
            themeMode: themeModeToInt(_themeMode),
            showExecutionStatus: _showExecutionStatus,
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
      showExecutionStatus: _showExecutionStatus,
      createTimestamp: _profile!.createTimestamp,
      modifyTimestamp: DateTime.now(),
    );
    final onProfileSaved = widget.onProfileSaved;
    if (onProfileSaved != null) {
      await onProfileSaved(profile);
    } else {
      await (widget.viewModel ?? _resolvedViewModel!).save(profile);
    }
    _profile = profile; // 更新本地缓存
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDesktopPlatform(context);

    if (_isLoading) {
      if (isDesktop) {
        return const Center(child: CircularProgressIndicator());
      }
      return Scaffold(
        appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.surface),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (isDesktop) {
      return _buildDesktopBody(context);
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
      body: _buildMobileBody(context),
    );
  }

  Widget _buildMobileBody(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
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
                        backgroundImage: _buildAvatarImageProvider(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            _buildSettingsSection(
              context,
              title: S.of(context).desktopPersonalInformation,
              children: [
                _buildSettingItem(
                  context,
                  Icons.person_rounded,
                  S.of(context).name,
                  _name,
                  _showEditNameDialog,
                ),
              ],
            ),
            _buildSettingsSection(
              context,
              title: S.of(context).desktopAppearanceAndLanguage,
              children: [
                _buildSettingItem(
                  context,
                  Icons.brightness_6_rounded,
                  S.of(context).themeSettings,
                  _themeLabel(context),
                  _showThemeOptions,
                ),
                const SizedBox(height: 8),
                _buildSettingItem(
                  context,
                  Icons.language_rounded,
                  S.of(context).languageSettings,
                  getLanguageName(_language),
                  _showLanguageOptions,
                ),
                const SizedBox(height: 8),
                _buildSettingItem(
                  context,
                  Icons.text_fields_rounded,
                  S.of(context).fontSizeSettings,
                  S.of(context).adjustAppFontSize,
                  _showFontSizeDialog,
                ),
                _buildFontSizeSlider(context),
              ],
            ),
            _buildSettingsSection(
              context,
              title: S.of(context).desktopGeneral,
              children: [
                _buildSettingItem(
                  context,
                  Icons.build_rounded,
                  S.of(context).skillLibrary,
                  S.of(context).skillLibraryDescription,
                  widget.onOpenSkillLibrary,
                  key: const ValueKey<String>('profile-skill-library'),
                ),
                const SizedBox(height: 8),
                _buildSettingItem(
                  context,
                  Icons.hub_outlined,
                  S.of(context).mcpServers,
                  S.of(context).mcpServersDescription,
                  widget.onOpenMcpServers,
                  key: const ValueKey<String>('profile-mcp-servers'),
                ),
                const SizedBox(height: 12),
                _buildApplicationInjectedPrompt(context, desktop: false),
              ],
            ),
            _buildSettingsSection(
              context,
              title: S.of(context).desktopHelpAndSupport,
              children: [
                _buildSettingItem(
                  context,
                  Icons.help_rounded,
                  S.of(context).helpAndFeedback,
                  S.of(context).provideFeedback,
                  _openFeedbackPage,
                ),
                const SizedBox(height: 8),
                _buildSettingItem(
                  context,
                  Icons.info_rounded,
                  S.of(context).about,
                  S.of(context).version,
                  _showCustomAboutDialog,
                  key: const ValueKey<String>('profile-about'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopBody(BuildContext context) {
    return ColoredBox(
      color: StarsDesktopThemeSpec.workspaceSurface(context),
      child: SingleChildScrollView(
        padding: StarsDesktopThemeSpec.formPagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: StarsDesktopThemeSpec.formContentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).profile,
                  style: StarsDesktopThemeSpec.pageTitleStyle(context),
                ),
                const SizedBox(height: 6),
                Text(
                  S.of(context).desktopSettingsDescription,
                  style: StarsDesktopThemeSpec.bodyStyle(
                    context,
                  )?.copyWith(color: StarsDesktopThemeSpec.mutedText(context)),
                ),
                const SizedBox(height: 32),
                _buildDesktopSettingsSection(
                  context,
                  sectionKey: _desktopSectionKeys[0],
                  title: S.of(context).desktopPersonalInformation,
                  description: S.of(context).desktopEditProfileDescription,
                  children: [_buildDesktopProfileRow(context)],
                ),
                const SizedBox(height: 32),
                _buildDesktopSettingsSection(
                  context,
                  sectionKey: _desktopSectionKeys[1],
                  title: S.of(context).desktopAppearanceAndLanguage,
                  description: S.of(context).desktopSavedImmediatelyDescription,
                  children: [
                    _buildDesktopSettingRow(
                      context,
                      icon: Icons.brightness_6_outlined,
                      title: S.of(context).themeSettings,
                      value: _themeLabel(context),
                      onTap: _showThemeOptions,
                    ),
                    _buildDesktopSettingRow(
                      context,
                      icon: Icons.language_outlined,
                      title: S.of(context).languageSettings,
                      value: getLanguageName(_language),
                      onTap: _showLanguageOptions,
                    ),
                    _buildDesktopFontSizeControl(context),
                  ],
                ),
                const SizedBox(height: 32),
                _buildDesktopSettingsSection(
                  context,
                  sectionKey: _desktopSectionKeys[2],
                  title: S.of(context).desktopGeneral,
                  description: S.of(context).desktopSavedImmediatelyDescription,
                  children: [
                    _buildDesktopSettingRow(
                      context,
                      key: const ValueKey<String>('profile-skill-library'),
                      icon: LucideIcons.wrench,
                      title: S.of(context).skillLibrary,
                      subtitle: S.of(context).skillLibraryDescription,
                      onTap: widget.onOpenSkillLibrary,
                    ),
                    _buildDesktopSettingRow(
                      context,
                      key: const ValueKey<String>('profile-mcp-servers'),
                      icon: Icons.hub_outlined,
                      title: S.of(context).mcpServers,
                      subtitle: S.of(context).mcpServersDescription,
                      onTap: widget.onOpenMcpServers,
                    ),
                    _buildDesktopExecutionStatusControl(context),
                    _buildApplicationInjectedPrompt(context, desktop: true),
                  ],
                ),
                const SizedBox(height: 32),
                _buildDesktopSettingsSection(
                  context,
                  sectionKey: _desktopSectionKeys[3],
                  title: S.of(context).desktopHelpAndSupport,
                  children: [
                    _buildDesktopSettingRow(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: S.of(context).helpAndFeedback,
                      subtitle: S.of(context).provideFeedback,
                      onTap: _openFeedbackPage,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildDesktopSettingsSection(
                  context,
                  sectionKey: _desktopSectionKeys[4],
                  title: S.of(context).desktopAboutAndLegal,
                  children: [
                    _buildDesktopSettingRow(
                      context,
                      key: const ValueKey<String>('profile-about'),
                      icon: Icons.info_outline_rounded,
                      title: S.of(context).about,
                      subtitle: S.of(context).version,
                      onTap: _showCustomAboutDialog,
                    ),
                    _buildDesktopSettingRow(
                      context,
                      icon: Icons.description_outlined,
                      title: S.of(context).userAgreement,
                      onTap: _openUserAgreementPage,
                    ),
                    _buildDesktopSettingRow(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      title: S.of(context).privacyPolicy,
                      onTap: _openPrivacyPolicyPage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
