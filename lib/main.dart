import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/services/profile_service.dart';
import 'package:stars/services/bot_service.dart';
import 'package:stars/model/model.dart';
import 'package:stars/pages/chats.dart';
import 'package:stars/pages/bots.dart';
import 'package:stars/pages/profile.dart';
import 'package:stars/utils/utils.dart';
import 'package:stars/services/database_service.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/utils/dot_curved_bottom_nav.dart';
import 'package:stars/pages/desktop_layout.dart';
import 'package:stars/utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    databaseFactory = databaseFactoryFfi;
  }
  Intl.defaultLocale = 'zh';
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
    final theme = buildAppTheme(brightness: Brightness.light, fontSize: 16);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
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
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor:
            _themeMode == ThemeMode.dark
                ? Colors.grey.shade900
                : Colors.grey.shade100,
        statusBarIconBrightness:
            _themeMode == ThemeMode.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness:
            _themeMode == ThemeMode.dark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlayStyle();
    return MaterialApp(
      title: 'Stars',
      theme: buildAppTheme(brightness: Brightness.light, fontSize: _fontSize),
      darkTheme: buildAppTheme(
        brightness: Brightness.dark,
        fontSize: _fontSize,
      ),
      highContrastTheme: buildAppTheme(
        brightness: Brightness.light,
        fontSize: _fontSize,
        highContrast: true,
        reduceTransparency: true,
      ),
      highContrastDarkTheme: buildAppTheme(
        brightness: Brightness.dark,
        fontSize: _fontSize,
        highContrast: true,
        reduceTransparency: true,
      ),
      themeMode: _themeMode,

      // 国际化配置
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        S.delegate,
      ],
      supportedLocales: supportedLocales,
      locale: _locale,
      localeResolutionCallback: (locale, supportedLocales) {
        // 如果设备语言在支持的语言列表中，则使用设备语言
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        // 否则使用第一个支持的语言（简体中文）
        return supportedLocales.first;
      },

      home: const MainPage(),
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
                onCreateChat:
                    () => _chatListKey.currentState?.openNewChatDialog(),
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
  void _onChatSelected(String chatId, Bot bot) {
    setState(() {
      _selectedChatId = chatId;
      _selectedChatBot = bot;
      _currentIndex = 0;
    });
  }

  void _onBotSelected(Bot bot) {
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

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
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
