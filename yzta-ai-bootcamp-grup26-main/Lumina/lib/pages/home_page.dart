import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'file_explorer_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import '../services/feature_service.dart';
import '../services/language_service.dart';
import '../widgets/feature_card_widget.dart';

class HomePage extends StatefulWidget {
  final String userName;
  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StudentType selectedType = StudentType.none;
  List<String> uploadedFiles = [];
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2563EB);
    final Color softBlue = const Color(0xFF60A5FA);
    final Color cardBG = Colors.white;
    final languageService = Provider.of<LanguageService>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue, softBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Hoş geldiniz kutusu ve navigasyon butonları
              Container(
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: cardBG,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "${languageService.getText('welcome')}, ${widget.userName}!",
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfilePage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person, size: 20),
                            label: Text(languageService.getText('profile')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: primaryBlue,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.settings, size: 20),
                            label: Text(languageService.getText('settings')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: primaryBlue,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Nasıl yardımcı olabilirim?
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBG,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      languageService.currentLocale.languageCode == 'tr' 
                        ? "Nasıl yardımcı olabilirim?"
                        : languageService.currentLocale.languageCode == 'en'
                          ? "How can I help you?"
                          : "Wie kann ich Ihnen helfen?",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        // Görme engelli butonu
                        Expanded(
                          child: SelectButton(
                            selected: selectedType == StudentType.blind,
                            icon: "👁️",
                            text: languageService.currentLocale.languageCode == 'tr' 
                              ? "Ben görme engelli bir öğrenciyim"
                              : languageService.currentLocale.languageCode == 'en'
                                ? "I am a visually impaired student"
                                : "Ich bin ein sehbehinderter Student",
                            onTap: () {
                              setState(() {
                                selectedType = StudentType.blind;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // İşitme engelli butonu
                        Expanded(
                          child: SelectButton(
                            selected: selectedType == StudentType.deaf,
                            icon: "🦻",
                            text: languageService.currentLocale.languageCode == 'tr' 
                              ? "Ben işitme engelli bir öğrenciyim"
                              : languageService.currentLocale.languageCode == 'en'
                                ? "I am a hearing impaired student"
                                : "Ich bin ein hörgeschädigter Student",
                            onTap: () {
                              setState(() {
                                selectedType = StudentType.deaf;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Özellik Kartları Bölümü
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageService.currentLocale.languageCode == 'tr' 
                        ? "🚀 Özellikler"
                        : languageService.currentLocale.languageCode == 'en'
                          ? "🚀 Features"
                          : "🚀 Funktionen",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Builder(
                      builder: (context) {
                        final features =
                            FeatureService.getFeaturesByStudentType(
                              context,
                              selectedType,
                            );

                        if (selectedType == StudentType.none) {
                          // Grid layout for all features
                          final crossAxisCount = 2;
                          final rowCount = (features.length / crossAxisCount)
                              .ceil();
                          return SizedBox(
                            height:
                                rowCount * 180 +
                                (rowCount - 1) *
                                    8, // 180: kart yüksekliği, 8: spacing
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 0.75, // 0.85 -> 0.75
                                  ),
                              itemCount: features.length,
                              itemBuilder: (context, index) {
                                return FeatureCardWidget(
                                  feature: features[index],
                                );
                              },
                            ),
                          );
                        } else {
                          // List layout for specific student types
                          return Column(
                            children: features
                                .map(
                                  (feature) =>
                                      FeatureCardWidget(feature: feature),
                                )
                                .toList(),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Hızlı Erişim Menüsü
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageService.currentLocale.languageCode == 'tr' 
                        ? "⚡ Hızlı Erişim"
                        : languageService.currentLocale.languageCode == 'en'
                          ? "⚡ Quick Access"
                          : "⚡ Schnellzugriff",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FileExplorerPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.folder_open, size: 20),
                            label: Text(languageService.currentLocale.languageCode == 'tr' 
                              ? 'Dosyalar'
                              : languageService.currentLocale.languageCode == 'en'
                                ? 'Files'
                                : 'Dateien'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: primaryBlue,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfilePage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person, size: 20),
                            label: Text(languageService.currentLocale.languageCode == 'tr' 
                              ? 'Profil'
                              : languageService.currentLocale.languageCode == 'en'
                                ? 'Profile'
                                : 'Profil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: primaryBlue,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.settings, size: 20),
                            label: Text(languageService.currentLocale.languageCode == 'tr' 
                              ? 'Ayarlar'
                              : languageService.currentLocale.languageCode == 'en'
                                ? 'Settings'
                                : 'Einstellungen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: primaryBlue,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Son Yüklenenler
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE0E7FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageService.currentLocale.languageCode == 'tr' 
                        ? "📂 Son Yüklenen Dosyalarım"
                        : languageService.currentLocale.languageCode == 'en'
                          ? "📂 My Recently Uploaded Files"
                          : "📂 Meine kürzlich hochgeladenen Dateien",
                      style: TextStyle(
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...uploadedFiles.map(
                      (fileName) => ListTile(
                        leading: Icon(
                          fileName.toLowerCase().contains('.pdf')
                              ? Icons.picture_as_pdf
                              : Icons.audiotrack,
                          color: const Color(0xFF2563EB),
                        ),
                        title: Text(fileName),
                        subtitle: Text(languageService.currentLocale.languageCode == 'tr' 
                          ? 'Dosya yüklendi'
                          : languageService.currentLocale.languageCode == 'en'
                            ? 'File uploaded'
                            : 'Datei hochgeladen'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Seçim butonu widget'ı
class SelectButton extends StatelessWidget {
  final bool selected;
  final String icon;
  final String text;
  final VoidCallback onTap;

  const SelectButton({
    required this.selected,
    required this.icon,
    required this.text,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color active = const Color(0xFF2563EB);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? active : const Color(0xFFF1F5FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? active : const Color(0xFFDBEAFE),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 23)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.blueGrey[800],
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
