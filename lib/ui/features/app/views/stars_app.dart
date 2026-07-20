import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/utils/utils.dart';
import 'package:stars/utils/dot_curved_bottom_nav.dart';
import 'package:stars/ui/core/dependency_injection/app_dependencies.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/app/view_models/app_view_model.dart';
import 'package:stars/ui/features/app/view_models/main_shell_view_model.dart';
import 'package:stars/ui/features/app/view_models/startup_view_model.dart';
import 'package:stars/ui/features/app/views/desktop_layout.dart';
import 'package:stars/ui/features/bots/view_models/bot_list_view_model.dart';
import 'package:stars/ui/features/bots/views/bots.dart';
import 'package:stars/ui/features/chats/view_models/chat_list_view_model.dart';
import 'package:stars/ui/features/chats/views/chats.dart';
import 'package:stars/ui/features/profile/view_models/profile_view_model.dart';
import 'package:stars/ui/features/profile/views/profile.dart';
import 'package:stars/utils/theme.dart';

class StarsBootstrapApp extends StatefulWidget {
  const StarsBootstrapApp({super.key, this.dependencies});

  final AppDependencies? dependencies;

  @override
  State<StarsBootstrapApp> createState() => _StarsBootstrapAppState();
}

class _StarsBootstrapAppState extends State<StarsBootstrapApp> {
  late final AppDependencies _dependencies;
  late final StartupViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _dependencies = widget.dependencies ?? AppDependencies.production();
    _viewModel = _dependencies.createStartupViewModel()..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _retryBootstrap() => _viewModel.load();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return const StartupShell(title: 'Stars', message: '正在启动...');
        }

        final profile = _viewModel.profile;
        if (_viewModel.hasError || profile == null) {
          return StartupShell(
            title: 'Stars',
            message: '启动失败，请重试',
            details: _viewModel.error?.toString(),
            onRetry: _retryBootstrap,
          );
        }

        return MyApp(dependencies: _dependencies, initialProfile: profile);
      },
    );
  }
}

class StartupShell extends StatelessWidget {
  final String title;
  final String message;
  final String? details;
  final VoidCallback? onRetry;

  const StartupShell({
    super.key,
    required this.title,
    required this.message,
    this.details,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDesktopPlatform(context)) {
      final theme = buildLegacyMobileTheme(
        brightness: Brightness.light,
        fontSize: 16,
      );
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: _buildHome(theme),
      );
    }

    return ShadApp.custom(
      theme: buildStarsShadTheme(brightness: Brightness.light, fontSize: 16),
      appBuilder: (context) {
        final theme = buildShadMaterialBridgeTheme(
          context: context,
          fontSize: 16,
        );
        final highContrastTheme = buildShadMaterialBridgeTheme(
          context: context,
          fontSize: 16,
          highContrast: true,
          reduceTransparency: true,
        );
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          highContrastTheme: highContrastTheme,
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final shadTheme = buildStarsShadTheme(
              brightness: Theme.of(context).brightness,
              fontSize: 16,
              highContrast: MediaQuery.highContrastOf(context),
            );
            return ShadTheme(
              data: shadTheme,
              child: ShadAppBuilder(child: child!),
            );
          },
          home: _buildHome(theme),
        );
      },
    );
  }

  Widget _buildHome(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Builder(
              builder:
                  (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 72,
                          height: 72,
                          cacheWidth: 144,
                          cacheHeight: 144,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (details == null) ...[
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(),
                      ] else ...[
                        const SizedBox(height: 12),
                        Text(
                          details!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (onRetry != null) ...[
                          const SizedBox(height: 20),
                          if (isDesktopPlatform(context))
                            ShadButton(
                              onPressed: onRetry,
                              child: const Text('重试'),
                            )
                          else
                            FilledButton(
                              onPressed: onRetry,
                              child: const Text('重试'),
                            ),
                        ],
                      ],
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final Profile initialProfile;
  final AppDependencies dependencies;

  const MyApp({
    super.key,
    required this.initialProfile,
    required this.dependencies,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.dependencies.createAppViewModel(widget.initialProfile);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _setSystemUIOverlayStyle() {
    final isDark = switch (_viewModel.themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark,
    };
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor:
            isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        _setSystemUIOverlayStyle();
        return AppScope(
          dependencies: widget.dependencies,
          child:
              !isDesktopPlatform(context)
                  ? _buildMobileApp()
                  : _buildDesktopApp(),
        );
      },
    );
  }

  Widget _buildMobileApp() {
    return MaterialApp(
      title: 'Stars',
      theme: buildLegacyMobileTheme(
        brightness: Brightness.light,
        fontSize: _viewModel.fontSize,
      ),
      darkTheme: buildLegacyMobileTheme(
        brightness: Brightness.dark,
        fontSize: _viewModel.fontSize,
      ),
      highContrastTheme: buildLegacyMobileTheme(
        brightness: Brightness.light,
        fontSize: _viewModel.fontSize,
        highContrast: true,
        reduceTransparency: true,
      ),
      highContrastDarkTheme: buildLegacyMobileTheme(
        brightness: Brightness.dark,
        fontSize: _viewModel.fontSize,
        highContrast: true,
        reduceTransparency: true,
      ),
      themeMode: _viewModel.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        S.delegate,
      ],
      supportedLocales: supportedLocales,
      locale: _viewModel.locale,
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      home: const MainPage(),
    );
  }

  Widget _buildDesktopApp() {
    return ShadApp.custom(
      themeMode: _viewModel.themeMode,
      theme: buildStarsShadTheme(
        brightness: Brightness.light,
        fontSize: _viewModel.fontSize,
      ),
      darkTheme: buildStarsShadTheme(
        brightness: Brightness.dark,
        fontSize: _viewModel.fontSize,
      ),
      appBuilder: (context) {
        final theme = buildShadMaterialBridgeTheme(
          context: context,
          fontSize: _viewModel.fontSize,
        );
        final highContrastTheme = buildShadMaterialBridgeTheme(
          context: context,
          fontSize: _viewModel.fontSize,
          highContrast: true,
          reduceTransparency: true,
        );
        return MaterialApp(
          title: 'Stars',
          theme: theme,
          highContrastTheme: highContrastTheme,
          themeMode: ThemeMode.light,
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            S.delegate,
          ],
          supportedLocales: supportedLocales,
          locale: _viewModel.locale,
          localeResolutionCallback: (locale, supportedLocales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale?.languageCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          builder: (context, child) {
            final shadTheme = buildStarsShadTheme(
              brightness: Theme.of(context).brightness,
              fontSize: _viewModel.fontSize,
              highContrast: MediaQuery.highContrastOf(context),
            );
            return ShadTheme(
              data: shadTheme,
              child: ShadAppBuilder(child: child!),
            );
          },
          home: const MainPage(),
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ChatListPageState> _chatListKey =
      GlobalKey<ChatListPageState>();
  final GlobalKey<ContactsPageState> _botListKey =
      GlobalKey<ContactsPageState>();
  late final AppDependencies _dependencies;
  late final MainShellViewModel _viewModel;
  late final ChatListViewModel _chatListViewModel;
  late final BotListViewModel _botListViewModel;
  late final ProfileViewModel _profileViewModel;
  bool _initialized = false;
  Future<bool>? _activeRunGuardFuture;
  int _navigationIntent = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _dependencies = AppScope.of(context);
    _viewModel = _dependencies.createMainShellViewModel();
    _chatListViewModel = _dependencies.createChatListViewModel()..load();
    _botListViewModel = _dependencies.createBotListViewModel()..load();
    _profileViewModel = _dependencies.createProfileViewModel()..load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_initialized) {
      _viewModel.dispose();
      _chatListViewModel.dispose();
      _botListViewModel.dispose();
      _profileViewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final isDesktopOrTablet = isDesktopOrTabletPlatform(context);
    final pages = <Widget>[
      ChatListPage(
        key: _chatListKey,
        viewModel: _chatListViewModel,
        sidebarMode: isDesktopOrTablet,
        selectedChatId: _viewModel.selectedChatId,
        onChatSelected: _onChatSelected,
        onSelectionCleared: _viewModel.clearSelectedChat,
      ),
      ContactsPage(
        key: _botListKey,
        viewModel: _botListViewModel,
        selectedBotId: _viewModel.selectedBot?.id,
        onBotSelected: _onBotSelected,
        onChatCreated: _onChatSelected,
        onSelectionCleared: _viewModel.clearSelectedBot,
      ),
      ProfilePage(
        viewModel: _profileViewModel,
        avatarPicker: _profileViewModel.pickAvatar,
        selectedSection: _viewModel.selectedProfileSection,
      ),
    ];

    return Scaffold(
      body:
          isDesktopOrTablet
              ? DesktopLayout(
                currentIndex: _viewModel.currentIndex,
                onPageChanged: _onPageChanged,
                pages: pages,
                selectedChatId: _viewModel.selectedChatId,
                selectedChatBot: _viewModel.selectedChatBot,
                selectedBot: _viewModel.selectedBot,
                selectedProfileSection: _viewModel.selectedProfileSection,
                onProfileSectionChanged: _viewModel.selectProfileSection,
                onCreateChat: _requestCreateChat,
                onAddBot: () {
                  _botListKey.currentState?.openAddBotPage();
                },
                onSearchRequested: _focusCurrentListSearch,
                avatarPicker: _botListViewModel.pickAvatar,
                onBotUpdated: _onBotUpdated,
                onBotDeleted: _onBotDeleted,
              )
              : IndexedStack(index: _viewModel.currentIndex, children: pages),
      bottomNavigationBar:
          isDesktopOrTablet
              ? null
              : DotCurvedBottomNav(
                margin: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  top: 8,
                ),
                scrollController: _scrollController,
                hideOnScroll: false,
                indicatorColor: Theme.of(context).colorScheme.onSurface,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                animationDuration: const Duration(milliseconds: 200), // 缩短动画时间
                animationCurve: Curves.easeInOut, // 使用更平滑的动画曲线
                selectedIndex: _viewModel.currentIndex,
                borderRadius: 24,
                height: 70,
                onTap: (index) {
                  // 添加震动反馈
                  HapticFeedback.lightImpact();
                  _viewModel.selectPage(index);
                },
                items: [
                  Icon(
                    Icons.wechat_rounded,
                    color:
                        _viewModel.currentIndex == 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                  ),
                  Icon(
                    Icons.smart_toy_rounded,
                    color:
                        _viewModel.currentIndex == 1
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                  ),
                  Icon(
                    Icons.person_rounded,
                    color:
                        _viewModel.currentIndex == 2
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
    );
  }

  // 新增：处理聊天选择的回调
  Future<void> _onChatSelected(String chatId, Bot bot) async {
    if (_viewModel.selectedChatId != chatId && !await _guardActiveChatRun()) {
      return;
    }
    if (!mounted) return;
    _viewModel.selectChat(chatId, bot);
  }

  Future<void> _onBotSelected(Bot bot) async {
    if (!await _guardActiveChatRun()) return;
    if (!mounted) return;
    _viewModel.selectBot(bot);
  }

  Future<void> _onPageChanged(int index) async {
    if (index != 0 && !await _guardActiveChatRun()) return;
    if (!mounted) return;
    _viewModel.selectPage(index);
  }

  Future<void> _requestCreateChat() async {
    if (!await _guardActiveChatRun()) return;
    _chatListKey.currentState?.openNewChatDialog();
  }

  Future<bool> _guardActiveChatRun() async {
    if (!isDesktopOrTabletPlatform(context)) return true;
    final intent = ++_navigationIntent;
    final pending = _activeRunGuardFuture;
    final Future<bool> guard;
    if (pending != null) {
      guard = pending;
    } else {
      guard = _performActiveRunGuard();
      _activeRunGuardFuture = guard;
    }

    final canContinue = await guard;
    if (identical(_activeRunGuardFuture, guard)) {
      _activeRunGuardFuture = null;
    }
    return canContinue && intent == _navigationIntent;
  }

  Future<bool> _performActiveRunGuard() async {
    final registry = _dependencies.generationRegistry;
    if (!registry.hasBlockingRun(_viewModel.selectedChatId)) return true;

    if (!registry.supportsCancellationForRun(_viewModel.selectedChatId)) {
      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast.destructive(
            title: Text(S.of(context).activeRequestCannotStop),
            description: Text(S.of(context).waitForGenerationBeforeLeaving),
          ),
        );
      }
      return false;
    }

    final shouldStop = await showChatShadDialog<bool>(
      context: context,
      variant: ShadDialogVariant.alert,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      builder:
          (dialogContext) => ShadDialog.alert(
            title: Text(S.of(dialogContext).stopGenerationBeforeLeaving),
            description: Text(
              S.of(dialogContext).stopGenerationBeforeLeavingDescription,
            ),
            actions: [
              ShadButton.outline(
                autofocus: true,
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(S.of(dialogContext).cancel),
              ),
              ShadButton.secondary(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                leading: const Icon(LucideIcons.square, size: 16),
                child: Text(S.of(dialogContext).stopAndContinue),
              ),
            ],
          ),
    );
    if (shouldStop != true || !mounted) return false;

    final canContinue = await registry.stopForNavigation(
      _viewModel.selectedChatId,
    );
    if (!canContinue && mounted) {
      ShadSonner.of(context).show(
        ShadToast.destructive(
          title: Text(S.of(context).activeRequestCannotStop),
          description: Text(S.of(context).waitForGenerationBeforeLeaving),
        ),
      );
    }
    return canContinue;
  }

  void _focusCurrentListSearch() {
    if (_viewModel.currentIndex == 0) {
      _chatListKey.currentState?.focusSearch();
    } else if (_viewModel.currentIndex == 1) {
      _botListKey.currentState?.focusSearch();
    }
  }

  Future<void> _onBotUpdated(Bot bot) => _viewModel.updateBot(bot);

  Future<void> _onBotDeleted() async {
    final botId = _viewModel.selectedBot?.id;
    if (botId == null) return;

    if (_viewModel.selectedChatBot?.id == botId &&
        !await _guardActiveChatRun()) {
      return;
    }
    await _viewModel.deleteSelectedBot();
  }
}
