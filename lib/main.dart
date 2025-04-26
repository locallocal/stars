import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bubble/l10n/app_localizations.dart';
import 'package:bubble/services/profile_service.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/pages/chats.dart';
import 'package:bubble/pages/bots.dart';
import 'package:bubble/pages/profile.dart';
import 'package:bubble/utils/utils.dart';
import 'package:bubble/services/database_service.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/utils/dot_curved_bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化数据库
  await DatabaseService.initDatabase();
  Intl.defaultLocale = 'zh';

  // 加载初始设置
  final profile = await ProfileService.getProfile();
  runApp(MyApp(initialProfile: profile));
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
    _loadSettings();

    // 监听主题变化
    ProfileService.themeStream.listen((ThemeMode themeMode) {
      setState(() {
        _themeMode = themeMode;
        _setSystemUIOverlayStyle();
      });
    });

    // 监听语言变化
    ProfileService.languageStream.listen((String language) {
      setState(() {
        final parts = language.split('_');
        if (parts.length == 2) {
          _locale = Locale(parts[0], parts[1]);
          S.load(_locale);
        }
      });
    });

    // 监听字体大小变化
    ProfileService.fontSizeStream.listen((double fontSize) {
      setState(() {
        _fontSize = fontSize;
      });
    });
  }

  Future<void> _loadSettings() async {
    final profile = await ProfileService.getProfile();
    setState(() {
      _themeMode = intToThemeMode(profile.themeMode);
      _fontSize = profile.fontSize;

      if (profile.language.isNotEmpty) {
        final parts = profile.language.split('_');
        if (parts.length == 2) {
          S.load(_locale);
          _locale = Locale(parts[0], parts[1]);
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
                ? Colors
                    .grey
                    .shade900 // 暗色模式下与surface颜色一致
                : Colors.grey.shade100,
        statusBarIconBrightness:
            _themeMode == ThemeMode.dark
                ? Brightness
                    .light // 暗色模式下状态栏图标为亮色
                : Brightness.dark, // 亮色模式下状态栏图标为暗色
        systemNavigationBarIconBrightness:
            _themeMode == ThemeMode.dark
                ? Brightness
                    .light // 暗色模式下导航栏图标为亮色
                : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlayStyle();
    return MaterialApp(
      title: 'Bubble',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          surface: Colors.grey.shade100,
          tertiary: Colors.grey.shade300,
          primary: Colors.blue.shade300,
          secondary: Colors.white,
          error: Colors.red.shade400,
        ),
        textTheme: TextTheme(
          // 根据用户设置调整字体大小
          bodyLarge: TextStyle(fontSize: _fontSize),
          bodyMedium: TextStyle(fontSize: _fontSize - 2),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.all(Colors.grey.shade600),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          surface: Colors.grey.shade900,
          tertiary: Colors.grey.shade700,
          primary: Colors.blue.shade600,
          secondary: Colors.grey.shade600,
          error: Colors.red.shade500,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: _fontSize),
          bodyMedium: TextStyle(fontSize: _fontSize - 2),
        ),
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

  final List<Widget> _pages = [
    const ChatListPage(),
    const ContactsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: DotCurvedBottomNav(
        scrollController: _scrollController,
        hideOnScroll: false,
        indicatorColor: Theme.of(context).colorScheme.onSurface,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        animationDuration: const Duration(milliseconds: 200), // 缩短动画时间
        animationCurve: Curves.easeInOut, // 使用更平滑的动画曲线
        selectedIndex: _currentIndex,
        indicatorSize: 5,
        borderRadius: 24,
        height: 70,
        onTap: (index) {
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
}
