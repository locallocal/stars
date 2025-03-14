import 'package:flutter/material.dart';
import 'package:dot_curved_bottom_nav/dot_curved_bottom_nav.dart';
import 'package:bubble/pages/chat_list.dart';
import 'package:bubble/pages/bots.dart';
import 'package:bubble/pages/profile.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/profile_service.dart';
import 'package:bubble/utils/utils.dart';
import 'package:bubble/services/database_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据库
  await DatabaseService.initDatabase();

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
  late ThemeMode _themeMode;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _themeMode = intToThemeMode(widget.initialProfile.themeMode);
    _fontSize = widget.initialProfile.fontSize;

    // 注册主题变化监听
    ProfileService.onThemeChanged = (ThemeMode newThemeMode) {
      setState(() {
        _themeMode = newThemeMode;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI助手',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          secondary: Colors.grey.shade300,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: _fontSize),
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
          secondary: Colors.grey.shade600,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: _fontSize),
        )
      ),
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
        hideOnScroll: true,
        indicatorColor: Theme.of(context).colorScheme.onSurface,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.ease,
        selectedIndex: _currentIndex,
        indicatorSize: 5,
        borderRadius: 24,
        height: 70,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: [
          Icon(
              Icons.chat_bubble_rounded,
              color: _currentIndex == 0 ? Theme.of(context).colorScheme.onSurface: Theme.of(context).colorScheme.onSurface,
          ),
          Icon(
              Icons.smart_toy_rounded,
              color: _currentIndex == 1 ? Theme.of(context).colorScheme.onSurface: Theme.of(context).colorScheme.onSurface,
          ),
          Icon(
              Icons.person,
              color: _currentIndex == 2 ? Theme.of(context).colorScheme.onSurface: Theme.of(context).colorScheme.onSurface,
          ),
        ],
    ),
    );
  }
}
