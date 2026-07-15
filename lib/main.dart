import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/services/profile_service.dart';
import 'package:stars/services/bot_service.dart';
import 'package:stars/model/model.dart';
import 'package:stars/pages/chats.dart';
import 'package:stars/pages/bots.dart';
import 'package:stars/pages/profile.dart';
import 'package:stars/utils/utils.dart';
import 'package:stars/services/database_service.dart';
import 'package:stars/services/chat_generation_controller.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/utils/dot_curved_bottom_nav.dart';
import 'package:stars/pages/desktop_layout.dart';
import 'package:stars/pages/chat/desktop_chat_primitives.dart';
import 'package:stars/utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    databaseFactory = databaseFactoryFfi;
  }
  intl.Intl.defaultLocale = 'zh';
  runApp(const StarsBootstrapApp());
}

class StarsBootstrapApp extends StatefulWidget {
  const StarsBootstrapApp({super.key});

  @override
  State<StarsBootstrapApp> createState() => _StarsBootstrapAppState();
}

class _StarsBootstrapAppState extends State<StarsBootstrapApp> {
  late Future<Profile> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<Profile> _bootstrap() async {
    await DatabaseService.initDatabase();
    return ProfileService.getProfile();
  }

  void _retryBootstrap() {
    setState(() {
      _bootstrapFuture = _bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const StartupShell(title: 'Stars', message: '正在启动...');
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return StartupShell(
            title: 'Stars',
            message: '启动失败，请重试',
            details: snapshot.error?.toString(),
            onRetry: _retryBootstrap,
          );
        }

        return MyApp(initialProfile: snapshot.data!);
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

  const MyApp({super.key, required this.initialProfile});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('zh', 'CN');
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _applyProfile(widget.initialProfile);

    ProfileService.themeStream.listen((ThemeMode themeMode) {
      setState(() {
        _themeMode = themeMode;
        _setSystemUIOverlayStyle();
      });
    });

    ProfileService.languageStream.listen((String language) {
      setState(() {
        final parts = language.split('_');
        if (parts.length == 2) {
          _locale = Locale(parts[0], parts[1]);
          S.load(_locale);
        }
      });
    });

    ProfileService.fontSizeStream.listen((double fontSize) {
      setState(() {
        _fontSize = fontSize;
      });
    });
  }

  void _applyProfile(Profile profile) {
    setState(() {
      _themeMode = intToThemeMode(profile.themeMode);
      _fontSize = profile.fontSize;

      if (profile.language.isNotEmpty) {
        final parts = profile.language.split('_');
        if (parts.length == 2) {
          _locale = Locale(parts[0], parts[1]);
          S.load(_locale);
        }
      }
    });
  }

  void _setSystemUIOverlayStyle() {
    final isDark = switch (_themeMode) {
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
    _setSystemUIOverlayStyle();
    if (!isDesktopPlatform(context)) {
      return MaterialApp(
        title: 'Stars',
        theme: buildLegacyMobileTheme(
          brightness: Brightness.light,
          fontSize: _fontSize,
        ),
        darkTheme: buildLegacyMobileTheme(
          brightness: Brightness.dark,
          fontSize: _fontSize,
        ),
        highContrastTheme: buildLegacyMobileTheme(
          brightness: Brightness.light,
          fontSize: _fontSize,
          highContrast: true,
          reduceTransparency: true,
        ),
        highContrastDarkTheme: buildLegacyMobileTheme(
          brightness: Brightness.dark,
          fontSize: _fontSize,
          highContrast: true,
          reduceTransparency: true,
        ),
        themeMode: _themeMode,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          S.delegate,
        ],
        supportedLocales: supportedLocales,
        locale: _locale,
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

    return ShadApp.custom(
      themeMode: _themeMode,
      theme: buildStarsShadTheme(
        brightness: Brightness.light,
        fontSize: _fontSize,
      ),
      darkTheme: buildStarsShadTheme(
        brightness: Brightness.dark,
        fontSize: _fontSize,
      ),
      appBuilder: (context) {
        final theme = buildShadMaterialBridgeTheme(
          context: context,
          fontSize: _fontSize,
        );
        final highContrastTheme = buildShadMaterialBridgeTheme(
          context: context,
          fontSize: _fontSize,
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
          locale: _locale,
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
              fontSize: _fontSize,
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
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ChatListPageState> _chatListKey =
      GlobalKey<ChatListPageState>();
  final GlobalKey<ContactsPageState> _botListKey =
      GlobalKey<ContactsPageState>();
  String? _selectedChatId;
  Bot? _selectedChatBot;
  Bot? _selectedBot;
  int _selectedProfileSection = 0;
  Future<bool>? _activeRunGuardFuture;
  int _navigationIntent = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktopOrTablet = isDesktopOrTabletPlatform(context);
    final pages = [
      ChatListPage(
        key: _chatListKey,
        selectedChatId: _selectedChatId,
        onChatSelected: _onChatSelected,
        onSelectionCleared: _clearSelectedChat,
      ),
      ContactsPage(
        key: _botListKey,
        selectedBotId: _selectedBot?.id,
        onBotSelected: _onBotSelected,
        onChatCreated: _onChatSelected,
        onSelectionCleared: _clearSelectedBot,
      ),
      ProfilePage(selectedSection: _selectedProfileSection),
    ];

    return Scaffold(
      body:
          isDesktopOrTablet
              ? DesktopLayout(
                currentIndex: _currentIndex,
                onPageChanged: _onPageChanged,
                pages: pages,
                selectedChatId: _selectedChatId,
                selectedChatBot: _selectedChatBot,
                selectedBot: _selectedBot,
                selectedProfileSection: _selectedProfileSection,
                onProfileSectionChanged: (section) {
                  setState(() {
                    _selectedProfileSection = section;
                    _currentIndex = 2;
                  });
                },
                onCreateChat: _requestCreateChat,
                onAddBot: () {
                  _botListKey.currentState?.openAddBotPage();
                },
                onSearchRequested: _focusCurrentListSearch,
                onBotUpdated: _onBotUpdated,
                onBotDeleted: _onBotDeleted,
              )
              : IndexedStack(index: _currentIndex, children: pages),
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
                selectedIndex: _currentIndex,
                borderRadius: 24,
                height: 70,
                onTap: (index) {
                  // 添加震动反馈
                  HapticFeedback.lightImpact();
                  setState(() {
                    _currentIndex = index;
                  });
                },
                items: [
                  Icon(
                    Icons.wechat_rounded,
                    color:
                        _currentIndex == 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                  ),
                  Icon(
                    Icons.smart_toy_rounded,
                    color:
                        _currentIndex == 1
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                  ),
                  Icon(
                    Icons.person_rounded,
                    color:
                        _currentIndex == 2
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
    );
  }

  // 新增：处理聊天选择的回调
  Future<void> _onChatSelected(String chatId, Bot bot) async {
    if (_selectedChatId != chatId && !await _guardActiveChatRun()) return;
    if (!mounted) return;
    setState(() {
      _selectedChatId = chatId;
      _selectedChatBot = bot;
      _currentIndex = 0;
    });
  }

  Future<void> _onBotSelected(Bot bot) async {
    if (!await _guardActiveChatRun()) return;
    if (!mounted) return;
    setState(() {
      _selectedBot = bot;
      _currentIndex = 1;
    });
  }

  void _clearSelectedChat() {
    setState(() {
      _selectedChatId = null;
      _selectedChatBot = null;
    });
  }

  void _clearSelectedBot() {
    setState(() {
      _selectedBot = null;
    });
  }

  Future<void> _onPageChanged(int index) async {
    if (index != 0 && !await _guardActiveChatRun()) return;
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
    });
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
    final registry = ChatGenerationRegistry.instance;
    if (!registry.hasBlockingRun(_selectedChatId)) return true;

    if (!registry.supportsCancellationForRun(_selectedChatId)) {
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

    final canContinue = await registry.stopForNavigation(_selectedChatId);
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
    if (_currentIndex == 0) {
      _chatListKey.currentState?.focusSearch();
    } else if (_currentIndex == 1) {
      _botListKey.currentState?.focusSearch();
    }
  }

  Future<void> _onBotUpdated(Bot bot) async {
    await BotService.updateBot(bot);
    if (!mounted) return;
    setState(() {
      if (_selectedBot?.id == bot.id) {
        _selectedBot = bot;
      }
      if (_selectedChatBot?.id == bot.id) {
        _selectedChatBot = bot;
      }
    });
  }

  Future<void> _onBotDeleted() async {
    final botId = _selectedBot?.id;
    if (botId == null) {
      return;
    }

    if (_selectedChatBot?.id == botId && !await _guardActiveChatRun()) return;
    await BotService.deleteBot(botId);
    if (!mounted) return;
    setState(() {
      if (_selectedChatBot?.id == botId) {
        _selectedChatId = null;
        _selectedChatBot = null;
      }
      _selectedBot = null;
    });
  }
}
