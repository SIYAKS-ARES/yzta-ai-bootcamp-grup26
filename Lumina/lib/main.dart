import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lumina/pages/auth_page.dart';
import 'package:lumina/pages/home_page.dart';
import 'package:lumina/pages/profile_page.dart';
import 'package:lumina/pages/settings_page.dart';
import 'package:lumina/pages/debug_page.dart';
import 'package:lumina/pages/file_explorer_page.dart';

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

  runApp(LuminaApp());
}

class LuminaApp extends StatelessWidget {
  const LuminaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumina',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo, // veya Colors.blue, sana kalmış
        fontFamily: 'Inter', // veya 'Roboto', yine sen seç
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/', // ilk açılan sayfa AuthPage
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
  }
}
