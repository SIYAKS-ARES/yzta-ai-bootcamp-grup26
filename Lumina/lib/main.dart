import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lumina/pages/auth_page.dart';
import 'package:lumina/pages/home_page.dart';
import 'package:lumina/pages/profile_page.dart';
import 'package:lumina/pages/settings_page.dart';
import 'package:lumina/pages/debug_page.dart';
import 'package:lumina/pages/file_explorer_page.dart';
import 'package:lumina/services/language_service.dart';
import 'package:lumina/services/theme_service.dart';
import 'services/firebase_config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env dosyasını yükle
  await dotenv.load(fileName: ".env");

  // 🔒 GÜVENLİK KONTROLÜ - API anahtarlarını doğrula
  try {
    _validateApiKeys();
    // API anahtarları güvenli şekilde yapılandırıldı
  } catch (e) {
    // Güvenlik uyarısı: API anahtarları yapılandırılmamış
    // Uygulama çalışmaya devam edebilir ama API özellikleri çalışmayacak
  }

  // 🔒 GÜVENLİK KONTROLÜ - Firebase konfigürasyonunu doğrula
  try {
    FirebaseConfigService.validateFirebaseConfig();
    // Firebase konfigürasyonu güvenli şekilde yapılandırıldı
  } catch (e) {
    // Firebase güvenlik uyarısı
    // Firebase olmadan uygulama çalışamaz
    throw Exception('Firebase konfigürasyonu gerekli!');
  }

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

// 🔒 GÜVENLİ: API anahtarlarını doğrudan .env dosyasından kontrol et
void _validateApiKeys() {
  final elevenLabsKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
  final openAIKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  if (elevenLabsKey.isEmpty ||
      elevenLabsKey == 'YOUR_ELEVENLABS_API_KEY_HERE') {
    throw Exception('ElevenLabs API anahtarı yapılandırılmamış!');
  }
  // OpenAI API anahtarı kontrolü kaldırıldı - devre dışı
  // if (openAIKey.isEmpty || openAIKey == 'YOUR_OPENAI_API_KEY_HERE') {
  //   throw Exception('OpenAI API anahtarı yapılandırılmamış!');
  // }
  // Gemini API anahtarı kontrolü kaldırıldı - devre dışı
  // if (geminiKey.isEmpty || geminiKey == 'YOUR_GEMINI_API_KEY_HERE') {
  //   throw Exception('Gemini API anahtarı yapılandırılmamış!');
  // }
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
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
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
