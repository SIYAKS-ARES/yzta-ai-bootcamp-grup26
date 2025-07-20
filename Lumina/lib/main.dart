import 'package:flutter/material.dart';
import 'package:lumina/pages/auth_page.dart';
import 'pages/home_page.dart';
import 'package:lumina/pages/profile_page.dart';

void main() {
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
        '/home': (context) =>
            HomePage(userName: 'Ahmet'), // userName parametresiyle örnek
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
