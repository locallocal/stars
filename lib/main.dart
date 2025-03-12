import 'package:flutter/material.dart';
import 'pages/chat_list.dart';
import 'pages/bots.dart';
import 'pages/profile.dart';
import 'model/model.dart';
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
        )
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          secondary: Colors.grey.shade600,
        ),
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

  final List<Widget> _pages = [
    const ChatListPage(),
    const ContactsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: Theme.of(context).textTheme.bodyLarge?.fontSize??16,
        unselectedFontSize: Theme.of(context).textTheme.bodyLarge?.fontSize??16,
        selectedItemColor: Theme.of(context).colorScheme.onSurface,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts_outlined),
            activeIcon: Icon(Icons.contacts),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '',
          ),
        ],
      ),
    );
  }
}
