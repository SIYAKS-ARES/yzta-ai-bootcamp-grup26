import 'package:flutter/material.dart';
import 'profile_page.dart';
import '../services/text_to_speech_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextToSpeechService _ttsService = TextToSpeechService();

  bool notificationsEnabled = true;
  bool darkTheme = false;
  String selectedLanguage = "Türkçe";
  final List<String> languages = ["Türkçe", "English", "Deutsch"];

  // TTS ayarları
  double speechRate = 0.5;
  double volume = 1.0;
  String ttsLanguage = "tr-TR";

  // Gemini API Key ile ilgili tüm kodları kaldır

  @override
  void initState() {
    super.initState();
    // _loadGeminiApiKey(); // Removed as per edit hint
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
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
              title: const Text(
                "Ahmet Yılmaz",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              subtitle: const Text("ahmet@mail.com"),
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
            title: const Text("Uygulama Dili"),
            trailing: DropdownButton<String>(
              value: selectedLanguage,
              items: languages.map((lang) {
                return DropdownMenuItem<String>(value: lang, child: Text(lang));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  if (val != null) selectedLanguage = val;
                });
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
            title: const Text("Bildirimleri Aç"),
          ),
          const Divider(),

          // Parola Değiştir
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text("Parola Değiştir"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Parola Değiştir"),
                  content: const Text("Bu özellik yakında aktif olacak."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tamam"),
                    ),
                  ],
                ),
              );
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
                        "Ses Ayarları",
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
                        "Konuşma Hızı: ${(speechRate * 100).round()}%",
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
                        "Ses Seviyesi: ${(volume * 100).round()}%",
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
                        await _ttsService.speakText(
                          "Bu bir test sesidir. Ayarlarınız çalışıyor.",
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Ses Testi"),
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
            value: darkTheme,
            onChanged: (val) {
              setState(() {
                darkTheme = val;
              });
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Tema"),
                  content: Text(
                    val ? "Koyu tema seçildi." : "Açık tema seçildi.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tamam"),
                    ),
                  ],
                ),
              );
            },
            secondary: const Icon(Icons.brightness_6),
            title: const Text("Koyu Tema"),
          ),
          const Divider(),

          // Yardım ve Destek
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Yardım ve Destek"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Yardım & Destek"),
                  content: const Text("Her türlü soru için: destek@lumina.com"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tamam"),
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
            title: const Text("Gizlilik Politikası"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Gizlilik Politikası"),
                  content: const Text(
                    "Gizlilik politikamız yakında yayınlanacaktır.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tamam"),
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
            title: const Text("Güncellemeleri Kontrol Et"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Güncellemeler"),
                  content: const Text("Uygulamanız güncel!"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tamam"),
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
            title: const Text(
              "Çıkış Yap",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
