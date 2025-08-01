import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:lumina/pages/auth_page.dart';
import 'package:lumina/pages/home_page.dart';
import 'package:lumina/pages/profile_page.dart';
import 'package:lumina/pages/settings_page.dart';
import 'package:lumina/pages/debug_page.dart';
import 'package:lumina/pages/file_explorer_page.dart';
import 'package:lumina/services/language_service.dart';
import 'package:lumina/services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // iOS Simulator için keychain kullanımını devre dışı bırak
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
      phoneNumber: null,
      smsCode: null,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: LuminaApp(),
    ),
  );
}

class LuminaApp extends StatefulWidget {
  const LuminaApp({super.key});

  @override
  State<LuminaApp> createState() => _LuminaAppState();
}

class _LuminaAppState extends State<LuminaApp> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    await Future.wait([
      languageService.loadLanguage(),
      themeService.loadTheme(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ThemeService>(
      builder: (context, languageService, themeService, child) {
        return MaterialApp(
          title: 'Lumina',
          debugShowCheckedModeBanner: false,
          locale: languageService.currentLocale,
          theme: themeService.lightTheme,
          darkTheme: themeService.darkTheme,
          themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => AuthPage(),
            '/home': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments as String? ??
                  'Kullanıcı';
              return HomePage(userName: args);
            },
            '/profile': (context) => const ProfilePage(),
            '/settings': (context) => const SettingsPage(),
            '/debug': (context) => DebugPage(),
            '/file-explorer': (context) => FileExplorerPage(),
          },
        );
      },
    );
  }
}
