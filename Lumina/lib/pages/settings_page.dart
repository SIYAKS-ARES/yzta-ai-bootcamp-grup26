import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import '../services/text_to_speech_service.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextToSpeechService _ttsService = TextToSpeechService();

  bool notificationsEnabled = true;
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';

  // TTS ayarları
  double speechRate = 0.5;
  double volume = 1.0;
  String ttsLanguage = "tr-TR";

  // Parola değiştirme controllers
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Gemini API Key ile ilgili tüm kodları kaldır

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // _loadGeminiApiKey(); // Removed as per edit hint
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _userName = '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim();
            _userEmail = user.email ?? '';
            _isLoading = false;
          });
        } else {
          setState(() {
            _userName = user.displayName ?? 'Kullanıcı';
            _userEmail = user.email ?? '';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Future<void> _loadGeminiApiKey() async { // Removed as per edit hint
  //   final key = await GeminiApiService.getApiKey(); // Removed as per edit hint
  //   setState(() { // Removed as per edit hint
  //     _savedGeminiApiKey = key; // Removed as per edit hint
  //   }); // Removed as per edit hint
  // } // Removed as per edit hint

  // Future<void> _saveGeminiApiKey() async { // Removed as per edit hint
  //   if (_geminiApiKey.isEmpty) return; // Removed as per edit hint
  //   await GeminiApiService.saveApiKey(_geminiApiKey); // Removed as per edit hint
  //   setState(() { // Removed as per edit hint
  //     _savedGeminiApiKey = _geminiApiKey; // Removed as per edit hint
  //     _geminiApiKey = ''; // Removed as per edit hint
  //   }); // Removed as per edit hint
  //   if (mounted) { // Removed as per edit hint
  //     ScaffoldMessenger.of(context).showSnackBar( // Removed as per edit hint
  //       const SnackBar(content: Text('Gemini API Key kaydedildi!')), // Removed as per edit hint
  //     ); // Removed as per edit hint
  //   } // Removed as per edit hint
  // } // Removed as per edit hint

  // Future<void> _deleteGeminiApiKey() async { // Removed as per edit hint
  //   await GeminiApiService.deleteApiKey(); // Removed as per edit hint
  //   setState(() { // Removed as per edit hint
  //     _savedGeminiApiKey = null; // Removed as per edit hint
  //   }); // Removed as per edit hint
  //   if (mounted) { // Removed as per edit hint
  //     ScaffoldMessenger.of( // Removed as per edit hint
  //       context, // Removed as per edit hint
  //     ).showSnackBar(const SnackBar(content: Text('Gemini API Key silindi!'))); // Removed as per edit hint
  //   } // Removed as per edit hint
  // } // Removed as per edit hint

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2563EB);
    final languageService = Provider.of<LanguageService>(context);
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageService.getText('settings')),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Kullanıcı info header
          Card(
            elevation: 0,
            color: const Color(0xFFF1F5FB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFF60A5FA),
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              title: Text(
                _isLoading ? languageService.getText('loading') : _userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              subtitle: Text(_isLoading ? '' : _userEmail),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Dil seçimi
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(languageService.getText('language')),
            trailing: DropdownButton<String>(
              value: languageService.supportedLocales.entries
                  .firstWhere(
                    (entry) => entry.value == languageService.currentLocale,
                  )
                  .key,
              items: languageService.supportedLocales.keys.map((lang) {
                return DropdownMenuItem<String>(value: lang, child: Text(lang));
              }).toList(),
              onChanged: (val) async {
                if (val != null) {
                  await languageService.changeLanguage(val);
                  _updateTTSLanguage();
                }
              },
            ),
          ),
          const Divider(),

          // Bildirimler
          SwitchListTile(
            value: notificationsEnabled,
            onChanged: (val) {
              setState(() {
                notificationsEnabled = val;
              });
            },
            secondary: const Icon(Icons.notifications),
            title: Text(languageService.getText('notifications')),
          ),
          const Divider(),

          // Parola Değiştir
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: Text(
              languageService.currentLocale.languageCode == 'tr'
                  ? "Parola Değiştir"
                  : languageService.currentLocale.languageCode == 'en'
                  ? "Change Password"
                  : "Passwort ändern",
            ),
            onTap: () {
              _showChangePasswordDialog();
            },
          ),
          const Divider(),

          // TTS Ayarları Bölümü
          Card(
            elevation: 0,
            color: const Color(0xFFF1F5FB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.volume_up, color: primaryBlue),
                      const SizedBox(width: 12),
                      Text(
                        languageService.currentLocale.languageCode == 'tr'
                            ? "Ses Ayarları"
                            : languageService.currentLocale.languageCode == 'en'
                            ? "Audio Settings"
                            : "Audioeinstellungen",
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Konuşma hızı
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageService.currentLocale.languageCode == 'tr'
                            ? "Konuşma Hızı: ${(speechRate * 100).round()}%"
                            : languageService.currentLocale.languageCode == 'en'
                            ? "Speech Rate: ${(speechRate * 100).round()}%"
                            : "Sprechgeschwindigkeit: ${(speechRate * 100).round()}%",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: speechRate,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        activeColor: primaryBlue,
                        onChanged: (value) {
                          setState(() {
                            speechRate = value;
                          });
                          _ttsService.setSpeechRate(value);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Ses seviyesi
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageService.currentLocale.languageCode == 'tr'
                            ? "Ses Seviyesi: ${(volume * 100).round()}%"
                            : languageService.currentLocale.languageCode == 'en'
                            ? "Volume Level: ${(volume * 100).round()}%"
                            : "Lautstärke: ${(volume * 100).round()}%",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        activeColor: primaryBlue,
                        onChanged: (value) {
                          setState(() {
                            volume = value;
                          });
                          _ttsService.setVolume(value);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Test butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final testText =
                            languageService.currentLocale.languageCode == 'tr'
                            ? "Bu bir test sesidir. Ayarlarınız çalışıyor."
                            : languageService.currentLocale.languageCode == 'en'
                            ? "This is a test sound. Your settings are working."
                            : "Dies ist ein Testton. Ihre Einstellungen funktionieren.";
                        await _ttsService.speakText(testText);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        languageService.currentLocale.languageCode == 'tr'
                            ? "Ses Testi"
                            : languageService.currentLocale.languageCode == 'en'
                            ? "Audio Test"
                            : "Audiotest",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tema Değiştir
          SwitchListTile(
            value: themeService.isDarkMode,
            onChanged: (val) async {
              await themeService.setTheme(val);
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(languageService.getText('dark_theme')),
                    content: Text(
                      val
                          ? "${languageService.getText('dark_theme')} seçildi."
                          : "Açık tema seçildi.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(languageService.getText('ok')),
                      ),
                    ],
                  ),
                );
              }
            },
            secondary: const Icon(Icons.brightness_6),
            title: Text(languageService.getText('dark_theme')),
          ),
          const Divider(),

          // Yardım ve Destek
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(languageService.getText('help_support')),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(languageService.getText('help_support')),
                  content: Text(
                    languageService.currentLocale.languageCode == 'tr'
                        ? "Her türlü soru için: destek@lumina.com"
                        : languageService.currentLocale.languageCode == 'en'
                        ? "For any questions: support@lumina.com"
                        : "Bei Fragen: support@lumina.com",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(languageService.getText('ok')),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),

          // Gizlilik Politikası
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(languageService.getText('privacy_policy')),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(languageService.getText('privacy_policy')),
                  content: Text(
                    languageService.currentLocale.languageCode == 'tr'
                        ? "Bu gizlilik politikası, Lumina uygulamasının kullanıcı verilerini nasıl topladığını, kullandığını ve koruduğunu açıklar. Kişisel bilgileriniz güvenli bir şekilde saklanır ve üçüncü taraflarla paylaşılmaz. Uygulama kullanımı sırasında toplanan veriler sadece hizmet kalitesini artırmak için kullanılır."
                        : languageService.currentLocale.languageCode == 'en'
                        ? "This privacy policy explains how the Lumina app collects, uses, and protects user data. Your personal information is stored securely and is not shared with third parties. Data collected during app usage is only used to improve service quality."
                        : "Diese Datenschutzrichtlinie erklärt, wie die Lumina-App Benutzerdaten sammelt, verwendet und schützt. Ihre persönlichen Informationen werden sicher gespeichert und nicht an Dritte weitergegeben. Während der App-Nutzung gesammelte Daten werden nur zur Verbesserung der Servicequalität verwendet.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(languageService.getText('ok')),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),

          // Güncellemeleri kontrol et
          ListTile(
            leading: const Icon(Icons.update),
            title: Text(
              languageService.currentLocale.languageCode == 'tr'
                  ? "Güncellemeleri Kontrol Et"
                  : languageService.currentLocale.languageCode == 'en'
                  ? "Check for Updates"
                  : "Nach Updates suchen",
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    languageService.currentLocale.languageCode == 'tr'
                        ? "Güncellemeler"
                        : languageService.currentLocale.languageCode == 'en'
                        ? "Updates"
                        : "Updates",
                  ),
                  content: Text(
                    languageService.currentLocale.languageCode == 'tr'
                        ? "Uygulamanız güncel!"
                        : languageService.currentLocale.languageCode == 'en'
                        ? "Your app is up to date!"
                        : "Ihre App ist auf dem neuesten Stand!",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(languageService.getText('ok')),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 22),

          // Çıkış yap
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              languageService.getText('logout'),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ttsService.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          languageService.currentLocale.languageCode == 'tr'
              ? "Parola Değiştir"
              : languageService.currentLocale.languageCode == 'en'
              ? "Change Password"
              : "Passwort ändern",
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: languageService.currentLocale.languageCode == 'tr'
                    ? "Mevcut Parola"
                    : languageService.currentLocale.languageCode == 'en'
                    ? "Current Password"
                    : "Aktuelles Passwort",
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: languageService.currentLocale.languageCode == 'tr'
                    ? "Yeni Parola"
                    : languageService.currentLocale.languageCode == 'en'
                    ? "New Password"
                    : "Neues Passwort",
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: languageService.currentLocale.languageCode == 'tr'
                    ? "Yeni Parolayı Onayla"
                    : languageService.currentLocale.languageCode == 'en'
                    ? "Confirm New Password"
                    : "Neues Passwort bestätigen",
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageService.getText('cancel')),
          ),
          TextButton(
            onPressed: () => _changePassword(),
            child: Text(
              languageService.currentLocale.languageCode == 'tr'
                  ? "Değiştir"
                  : languageService.currentLocale.languageCode == 'en'
                  ? "Change"
                  : "Ändern",
            ),
          ),
        ],
      ),
    );
  }

  // TTS dilini güncelle
  void _updateTTSLanguage() {
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final languageCode = languageService.currentLocale.languageCode;
    switch (languageCode) {
      case 'tr':
        _ttsService.setLanguage("tr-TR");
        break;
      case 'en':
        _ttsService.setLanguage("en-US");
        break;
      case 'de':
        _ttsService.setLanguage("de-DE");
        break;
      default:
        _ttsService.setLanguage("tr-TR");
    }
  }

  Future<void> _changePassword() async {
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageService.currentLocale.languageCode == 'tr'
                ? "Yeni parolalar eşleşmiyor!"
                : languageService.currentLocale.languageCode == 'en'
                ? "New passwords don't match!"
                : "Neue Passwörter stimmen nicht überein!",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(_newPasswordController.text);

        // Firestore'da da güncelle
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'password': _newPasswordController.text});

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                languageService.currentLocale.languageCode == 'tr'
                    ? "Parola başarıyla değiştirildi!"
                    : languageService.currentLocale.languageCode == 'en'
                    ? "Password changed successfully!"
                    : "Passwort erfolgreich geändert!",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageService.currentLocale.languageCode == 'tr'
                  ? "Parola değiştirme hatası: $e"
                  : languageService.currentLocale.languageCode == 'en'
                  ? "Password change error: $e"
                  : "Passwortänderungsfehler: $e",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          languageService.currentLocale.languageCode == 'tr'
              ? "Çıkış Yap"
              : languageService.currentLocale.languageCode == 'en'
              ? "Logout"
              : "Abmelden",
        ),
        content: Text(
          languageService.currentLocale.languageCode == 'tr'
              ? "Çıkış yapmak istediğinizden emin misiniz?"
              : languageService.currentLocale.languageCode == 'en'
              ? "Are you sure you want to logout?"
              : "Sind Sie sicher, dass Sie sich abmelden möchten?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              languageService.currentLocale.languageCode == 'tr'
                  ? "Hayır"
                  : languageService.currentLocale.languageCode == 'en'
                  ? "No"
                  : "Nein",
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: Text(
              languageService.currentLocale.languageCode == 'tr'
                  ? "Evet"
                  : languageService.currentLocale.languageCode == 'en'
                  ? "Yes"
                  : "Ja",
            ),
          ),
        ],
      ),
    );
  }
}
