import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/utils/utils.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/features/feedback/views/feedback_page.dart';
import 'package:stars/ui/features/profile/view_models/profile_view_model.dart';
import 'package:stars/ui/features/profile/views/privacy_policy.dart';
import 'package:stars/ui/features/profile/views/user_agreement.dart';
import 'package:stars/utils/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.selectedSection = 0,
    this.initialProfile,
    this.onProfileSaved,
    this.viewModel,
    this.avatarPicker,
  });

  final int selectedSection;
  final Profile? initialProfile;
  final Future<void> Function(Profile profile)? onProfileSaved;
  final ProfileViewModel? viewModel;
  final Future<String?> Function()? avatarPicker;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const double _defaultFontSize = 16.0;

  Profile? _profile;
  bool _isLoading = true;
  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'zh_CN'; // 语言设置
  ProfileViewModel? _resolvedViewModel;
  bool _loadStarted = false;
  final List<GlobalKey> _desktopSectionKeys = List<GlobalKey>.generate(
    4,
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
      color: DesktopThemeTokens.workspaceSurface(context),
      child: SingleChildScrollView(
        padding: DesktopThemeTokens.formPagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DesktopThemeTokens.formContentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).profile,
                  style: DesktopThemeTokens.pageTitleStyle(context),
                ),
                const SizedBox(height: 6),
                Text(
                  S.of(context).desktopSettingsDescription,
                  style: DesktopThemeTokens.bodyStyle(
                    context,
                  )?.copyWith(color: DesktopThemeTokens.mutedText(context)),
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
                  sectionKey: _desktopSectionKeys[3],
                  title: S.of(context).desktopAboutAndLegal,
                  children: [
                    _buildDesktopSettingRow(
                      context,
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

  Widget _buildDesktopSettingsSection(
    BuildContext context, {
    required GlobalKey sectionKey,
    required String title,
    String? description,
    required List<Widget> children,
  }) {
    return KeyedSubtree(
      key: sectionKey,
      child: ShadCard(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        title: Text(title),
        description: description == null ? null : Text(description),
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1)
                  const ShadSeparator.horizontal(
                    margin: EdgeInsetsDirectional.only(start: 40),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopProfileRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        children: [
          ShadTooltip(
            builder: (context) => Text(S.of(context).changeAvatar),
            child: ShadButton.ghost(
              width: 56,
              height: 56,
              padding: EdgeInsets.zero,
              onPressed: _pickImage,
              child: Semantics(
                label: S.of(context).changeAvatar,
                image: true,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: DesktopThemeTokens.secondarySurface(context),
                  backgroundImage: _buildAvatarImageProvider(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: DesktopThemeTokens.bodyStyle(
                    context,
                  )?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  S.of(context).name,
                  style: DesktopThemeTokens.metaStyle(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ShadButton.outline(
            onPressed: _showEditNameDialog,
            leading: const Icon(Icons.edit_outlined, size: 16),
            child: Text(S.of(context).editName),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSettingRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? value,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: title,
      value: value ?? subtitle,
      child: ShadButton.ghost(
        width: double.infinity,
        height: 0,
        expands: true,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        mainAxisAlignment: MainAxisAlignment.start,
        onPressed: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 38),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Icon(
                  icon,
                  size: 18,
                  color: DesktopThemeTokens.mutedText(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: DesktopThemeTokens.bodyStyle(context)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: DesktopThemeTokens.metaStyle(context),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesktopThemeTokens.metaStyle(context),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: DesktopThemeTokens.softText(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopFontSizeControl(BuildContext context) {
    final isDefault = (_fontSize - _defaultFontSize).abs() < 0.01;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                child: Icon(
                  Icons.text_fields_outlined,
                  size: 18,
                  color: DesktopThemeTokens.mutedText(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  S.of(context).fontSizeSettings,
                  style: DesktopThemeTokens.bodyStyle(context),
                ),
              ),
              Text(
                '${_fontSize.round()} px',
                style: DesktopThemeTokens.metaStyle(
                  context,
                )?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              ShadButton.ghost(
                enabled: !isDefault,
                size: ShadButtonSize.sm,
                onPressed: () => _commitFontSize(_defaultFontSize),
                leading: const Icon(Icons.restart_alt_rounded, size: 16),
                child: Text(S.of(context).resetToDefault),
              ),
            ],
          ),
          Slider(
            value: _fontSize,
            min: 12,
            max: 24,
            divisions: 12,
            label: _fontSize.round().toString(),
            onChanged: _previewFontSize,
            onChangeEnd: _commitFontSize,
            semanticFormatterCallback:
                (value) => '${value.round()} ${S.of(context).fontSizeSettings}',
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: DesktopThemeTokens.statusDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).previewText,
                  style: DesktopThemeTokens.metaStyle(context),
                ),
                const SizedBox(height: 6),
                Text(
                  desktopConversationText(
                    context,
                    S.of(context).appDescription,
                  ),
                  style: TextStyle(
                    color: DesktopThemeTokens.text(context),
                    fontSize: _fontSize,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
              title,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _previewFontSize(double value) {
    if (_profile == null || (_fontSize - value).abs() < 0.01) return;

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
  }

  Future<void> _commitFontSize(double value) async {
    _previewFontSize(value);
    await _saveProfile();
  }

  Widget _buildFontSizeSlider(BuildContext context) {
    final slider = Slider(
      value: _fontSize,
      min: 12.0,
      max: 24.0,
      divisions: 12,
      activeColor: Theme.of(context).colorScheme.onSurface,
      inactiveColor: Theme.of(
        context,
      ).colorScheme.onSurface.withValues(alpha: 0.3),
      label: _fontSize.round().toString(),
      onChanged: _previewFontSize,
      onChangeEnd: _commitFontSize,
    );

    if (isDesktopPlatform(context)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: DesktopThemeTokens.statusDecoration(context),
        child: slider,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 4.0),
      child: slider,
    );
  }

  String _themeLabel(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return S.of(context).followSystem;
    }
    if (_themeMode == ThemeMode.light) {
      return S.of(context).lightMode;
    }
    return S.of(context).darkMode;
  }

  List<({String title, ThemeMode mode, IconData icon})> _themeChoices(
    BuildContext context,
  ) => [
    (
      title: S.of(context).followSystem,
      mode: ThemeMode.system,
      icon: Icons.brightness_6_rounded,
    ),
    (
      title: S.of(context).lightMode,
      mode: ThemeMode.light,
      icon: Icons.brightness_5_rounded,
    ),
    (
      title: S.of(context).darkMode,
      mode: ThemeMode.dark,
      icon: Icons.brightness_2_rounded,
    ),
  ];

  ImageProvider _buildAvatarImageProvider() {
    if (_avatar.isNotEmpty) {
      return FileImage(File(_avatar));
    }
    return const ResizeImage(
      AssetImage('assets/images/profile/avatar.png'),
      width: 256,
      height: 256,
    );
  }

  void _openFeedbackPage() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const FeedbackPage()),
    );
  }

  void _openUserAgreementPage() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const UserAgreementPage()),
    );
  }

  void _openPrivacyPolicyPage() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const PrivacyPolicyPage()),
    );
  }

  // 显示编辑名称对话框
  void _showEditNameDialog() {
    final TextEditingController controller = TextEditingController(text: _name);

    void saveName(BuildContext dialogContext) {
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
      _saveProfile();
      Navigator.pop(dialogContext);
    }

    if (isDesktopPlatform(context)) {
      showShadDialog<void>(
        context: context,
        builder:
            (dialogContext) => ShadDialog(
              title: Text(S.of(dialogContext).editName),
              description: Text(S.of(dialogContext).enterBotName),
              actions: [
                ShadButton.outline(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(S.of(dialogContext).cancel),
                ),
                ShadButton(
                  onPressed: () => saveName(dialogContext),
                  child: Text(S.of(dialogContext).save),
                ),
              ],
              child: SizedBox(
                width: 380,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ShadInput(
                    controller: controller,
                    autofocus: true,
                    placeholder: Text(S.of(dialogContext).enterBotName),
                    leading: const Padding(
                      padding: EdgeInsetsDirectional.only(end: 8),
                      child: Icon(Icons.person_outline_rounded, size: 18),
                    ),
                    onSubmitted: (_) => saveName(dialogContext),
                  ),
                ),
              ),
            ),
      ).whenComplete(controller.dispose);
      return;
    }

    showDialog<void>(
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
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
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
                onPressed: () => saveName(context),
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
    final themes = _themeChoices(context);
    if (isDesktopPlatform(context)) {
      showShadDialog<void>(
        context: context,
        builder: (dialogContext) {
          final tokens = StarsDesktopTokens.of(dialogContext);
          return ShadDialog(
            title: Text(S.of(dialogContext).selectTheme),
            description: Text(
              S.of(dialogContext).desktopSavedImmediatelyDescription,
            ),
            child: SizedBox(
              width: 380,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  key: const ValueKey<String>('profile-theme-options'),
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: tokens.raisedSurface,
                    borderRadius: DesktopThemeTokens.containerRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final theme in themes)
                        MenuItemButton(
                          key: ValueKey<String>(
                            'profile-theme-option-${theme.mode.name}',
                          ),
                          leadingIcon: Icon(
                            theme.icon,
                            size: 18,
                            color: tokens.secondaryText,
                          ),
                          trailingIcon:
                              theme.mode == _themeMode
                                  ? Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: tokens.accent,
                                  )
                                  : const SizedBox.square(dimension: 16),
                          onPressed: () {
                            setState(() => _themeMode = theme.mode);
                            _saveProfile();
                            Navigator.pop(dialogContext);
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 180),
                            child: Text(
                              theme.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
      return;
    }
    showDialog<void>(
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
                    child: RadioGroup<ThemeMode>(
                      groupValue: _themeMode,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _themeMode = value;
                        });
                        _saveProfile();
                        Navigator.pop(context);
                      },
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...themes.map(
                              (theme) => RadioListTile<ThemeMode>(
                                title: Row(
                                  children: [
                                    Icon(theme.icon),
                                    const SizedBox(width: 12),
                                    Text(theme.title),
                                  ],
                                ),
                                activeColor:
                                    Theme.of(context).colorScheme.onSurface,
                                value: theme.mode,
                              ),
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
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

    showDialog<void>(
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
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
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
    if (isDesktopPlatform(context)) {
      showShadDialog<void>(
        context: context,
        builder:
            (dialogContext) => ShadDialog(
              title: Text(S.of(dialogContext).aboutApp),
              actions: [
                ShadButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(S.of(dialogContext).confirm),
                ),
              ],
              child: SizedBox(
                width: 440,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StarsLogo(size: 60),
                      const SizedBox(height: 20),
                      Text(
                        desktopConversationText(
                          dialogContext,
                          S.of(dialogContext).appTitle,
                        ),
                        style: ShadTheme.of(dialogContext).textTheme.h4,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        S.of(dialogContext).version,
                        style: ShadTheme.of(dialogContext).textTheme.muted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        desktopConversationText(
                          dialogContext,
                          S.of(dialogContext).appDescription,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        S.of(dialogContext).copyright,
                        style: ShadTheme.of(dialogContext).textTheme.muted,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          ShadButton.link(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              _openUserAgreementPage();
                            },
                            child: Text(S.of(dialogContext).userAgreement),
                          ),
                          ShadButton.link(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              _openPrivacyPolicyPage();
                            },
                            child: Text(S.of(dialogContext).privacyPolicy),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
      );
      return;
    }
    showDialog<void>(
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
                const StarsLogo(size: 60),
                const SizedBox(height: 24),
                Text(
                  desktopConversationText(context, S.of(context).appTitle),
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
                  desktopConversationText(
                    context,
                    S.of(context).appDescription,
                  ),
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
                          MaterialPageRoute<void>(
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
                          MaterialPageRoute<void>(
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
    const languages = [
      (code: 'zh_CN', name: '简体中文'),
      (code: 'en_US', name: 'English'),
      (code: 'zh_TW', name: '繁體中文'),
      (code: 'ja_JP', name: '日本語'),
      (code: 'fr_FR', name: 'Français'),
      (code: 'de_DE', name: 'Deutsch'),
      (code: 'ko_KR', name: '한국어'),
      (code: 'ru_RU', name: 'Русский'),
      (code: 'es_ES', name: 'Español'),
      (code: 'hi_IN', name: 'हिन्दी'),
      (code: 'pt_BR', name: 'Português'),
      (code: 'it_IT', name: 'Italiano'),
    ];
    if (isDesktopPlatform(context)) {
      showShadDialog<void>(
        context: context,
        builder: (dialogContext) {
          final tokens = StarsDesktopTokens.of(dialogContext);
          return ShadDialog(
            title: Text(S.of(dialogContext).selectLanguage),
            description: Text(
              S.of(dialogContext).desktopSavedImmediatelyDescription,
            ),
            child: SizedBox(
              width: 380,
              height: 440,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  key: const ValueKey<String>('profile-language-options'),
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: tokens.raisedSurface,
                    borderRadius: DesktopThemeTokens.containerRadius,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final language in languages)
                          MenuItemButton(
                            key: ValueKey<String>(
                              'profile-language-option-${language.code}',
                            ),
                            trailingIcon:
                                language.code == _language
                                    ? Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: tokens.accent,
                                    )
                                    : const SizedBox.square(dimension: 16),
                            onPressed: () {
                              setState(() => _language = language.code);
                              _saveProfile();
                              Navigator.pop(dialogContext);
                            },
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 180),
                              child: Text(
                                language.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
      return;
    }
    showDialog<void>(
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
                    child: RadioGroup<String>(
                      groupValue: _language,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _language = value;
                        });
                        _saveProfile();
                        Navigator.pop(context);
                      },
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
    final isDesktop = isDesktopPlatform(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isDesktop ? 14.0 : 16.0),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isDesktop ? 12.0 : 8.0,
          horizontal: isDesktop ? 12.0 : 0.0,
        ),
        child: Row(
          children: [
            Container(
              width: isDesktop ? 36.0 : 24.0,
              height: isDesktop ? 36.0 : 24.0,
              decoration:
                  isDesktop
                      ? BoxDecoration(
                        color: DesktopThemeTokens.selectedFill(context),
                        borderRadius: BorderRadius.circular(12),
                      )
                      : null,
              child: Icon(
                icon,
                size: 20.0,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        isDesktop
                            ? DesktopThemeTokens.bodyStyle(context)?.copyWith(
                              fontSize: _fontSize,
                              fontWeight: FontWeight.w600,
                            )
                            : TextStyle(
                              fontSize: _fontSize,
                              fontWeight: FontWeight.w500,
                            ),
                  ),
                  Text(
                    subtitle,
                    style:
                        isDesktop
                            ? DesktopThemeTokens.metaStyle(
                              context,
                            )?.copyWith(fontSize: _fontSize - 2)
                            : TextStyle(
                              fontSize: _fontSize - 2,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
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
class StarsLogo extends StatelessWidget {
  final double size;

  const StarsLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
