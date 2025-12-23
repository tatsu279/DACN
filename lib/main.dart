import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import 'screens/home_screen.dart';
import 'screens/convert_screen.dart';
import 'screens/settings_screen.dart';
import 'services/recognition_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🟢 Init Easy Localization
  await EasyLocalization.ensureInitialized();

  print("🟢 App starting once...");
  await RecognitionService.loadModel();

  // 🔹 Load theme từ SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      path: 'assets/lang',
      fallbackLocale: const Locale('vi'),
      child: MyApp(isDarkMode: isDarkMode),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  const MyApp({super.key, required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  // 🔹 Chế độ sáng/tối
  void _updateTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    setState(() => _isDarkMode = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nhận diện tiền tệ VN',
      debugShowCheckedModeBanner: false,

      // 🟢 Đa ngôn ngữ
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // 🟢 Giao diện
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),

      home: MainPage(onThemeChanged: _updateTheme),
    );
  }
}

class MainPage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const MainPage({super.key, required this.onThemeChanged});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      const ConvertScreen(),
      SettingsScreen(onThemeChanged: widget.onThemeChanged),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'bottom_home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.currency_exchange),
            label: 'bottom_convert'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: 'bottom_settings'.tr(),
          ),
        ],
      ),
    );
  }
}
