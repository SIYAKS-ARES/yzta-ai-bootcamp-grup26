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
    final Color primaryBlue = const Color(0xFF1e40af);
    final Color softBlue = const Color(0xFF3b82f6);
    final Color lightBlue = const Color(0xFF60a5fa);
    final Color cardBG = Colors.white;
    final languageService = Provider.of<LanguageService>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryBlue,
              softBlue,
              lightBlue,
              Color(0xFF93c5fd),
              Color(0xFFdbeafe),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Hoş geldiniz kutusu ve navigasyon butonları
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cardBG.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: softBlue.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryBlue, softBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${languageService.getText('welcome')},",
                                  style: TextStyle(
                                    color: Color(0xFF64748b),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getDisplayName(widget.userName),
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNavigationButton(
                              icon: Icons.person_rounded,
                              label: languageService.getText('profile'),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildNavigationButton(
                              icon: Icons.settings_rounded,
                              label: languageService.getText('settings'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SettingsPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Nasıl yardımcı olabilirim?
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cardBG.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFdbeafe), Color(0xFFbfdbfe)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.help_outline_rounded,
                              color: Color(0xFF1e40af),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              languageService.currentLocale.languageCode == 'tr'
                                  ? "Nasıl yardımcı olabilirim?"
                                  : languageService
                                            .currentLocale
                                            .languageCode ==
                                        'en'
                                  ? "How can I help you?"
                                  : "Wie kann ich Ihnen helfen?",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xFF1f2937),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStudentTypeButton(
                              selected: selectedType == StudentType.blind,
                              icon: Icons.visibility_off_rounded,
                              text:
                                  languageService.currentLocale.languageCode ==
                                      'tr'
                                  ? "Görme Engelli"
                                  : languageService
                                            .currentLocale
                                            .languageCode ==
                                        'en'
                                  ? "Visually Impaired"
                                  : "Sehbehindert",
                              onTap: () {
                                setState(() {
                                  selectedType = StudentType.blind;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStudentTypeButton(
                              selected: selectedType == StudentType.deaf,
                              icon: Icons.hearing_disabled_rounded,
                              text:
                                  languageService.currentLocale.languageCode ==
                                      'tr'
                                  ? "İşitme Engelli"
                                  : languageService
                                            .currentLocale
                                            .languageCode ==
                                        'en'
                                  ? "Hearing Impaired"
                                  : "Hörgeschädigt",
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

                // Özellik Kartları Bölümü
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cardBG.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFdbeafe), Color(0xFFbfdbfe)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.rocket_launch_rounded,
                              color: Color(0xFF1e40af),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            languageService.currentLocale.languageCode == 'tr'
                                ? "Özellikler"
                                : languageService.currentLocale.languageCode ==
                                      'en'
                                ? "Features"
                                : "Funktionen",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xFF1f2937),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Builder(
                        builder: (context) {
                          final features =
                              FeatureService.getFeaturesByStudentType(
                                context,
                                selectedType,
                              );

                          if (selectedType == StudentType.none) {
                            // Grid layout for all features
                            return SizedBox(
                              height: 400, // Sabit yükseklik
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.9,
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
                                    (feature) => Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: FeatureCardWidget(
                                        feature: feature,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Hızlı Erişim Menüsü
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cardBG.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFdbeafe), Color(0xFFbfdbfe)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.flash_on_rounded,
                              color: primaryBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            languageService.currentLocale.languageCode == 'tr'
                                ? "Hızlı Erişim"
                                : languageService.currentLocale.languageCode ==
                                      'en'
                                ? "Quick Access"
                                : "Schnellzugriff",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xFF1f2937),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickAccessButton(
                              icon: Icons.folder_open_rounded,
                              label:
                                  languageService.currentLocale.languageCode ==
                                      'tr'
                                  ? 'Dosyalar'
                                  : languageService
                                            .currentLocale
                                            .languageCode ==
                                        'en'
                                  ? 'Files'
                                  : 'Dateien',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FileExplorerPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickAccessButton(
                              icon: Icons.person_rounded,
                              label:
                                  languageService.currentLocale.languageCode ==
                                      'tr'
                                  ? 'Profil'
                                  : languageService
                                            .currentLocale
                                            .languageCode ==
                                        'en'
                                  ? 'Profile'
                                  : 'Profil',
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickAccessButton(
                              icon: Icons.settings_rounded,
                              label:
                                  languageService.currentLocale.languageCode ==
                                      'tr'
                                  ? 'Ayarlar'
                                  : languageService
                                            .currentLocale
                                            .languageCode ==
                                        'en'
                                  ? 'Settings'
                                  : 'Einstellungen',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SettingsPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Son Yüklenenler
                if (uploadedFiles.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBG.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFf0fdf4),
                                    Color(0xFFdcfce7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.folder_rounded,
                                color: Color(0xFF16a34a),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              languageService.currentLocale.languageCode == 'tr'
                                  ? "Son Yüklenen Dosyalarım"
                                  : languageService
                                            .currentLocale
                                            .languageCode ==
                                        'en'
                                  ? "My Recently Uploaded Files"
                                  : "Meine kürzlich hochgeladenen Dateien",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xFF1f2937),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...uploadedFiles.map(
                          (fileName) => Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFFf8fafc),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(0xFFe2e8f0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        fileName.toLowerCase().contains('.pdf')
                                        ? Color(0xFFfef2f2)
                                        : Color(0xFFf0f9ff),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    fileName.toLowerCase().contains('.pdf')
                                        ? Icons.picture_as_pdf_rounded
                                        : Icons.audiotrack_rounded,
                                    color:
                                        fileName.toLowerCase().contains('.pdf')
                                        ? Color(0xFFdc2626)
                                        : Color(0xFF2563eb),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fileName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Color(0xFF1f2937),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        languageService
                                                    .currentLocale
                                                    .languageCode ==
                                                'tr'
                                            ? 'Dosya yüklendi'
                                            : languageService
                                                      .currentLocale
                                                      .languageCode ==
                                                  'en'
                                            ? 'File uploaded'
                                            : 'Datei hochgeladen',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6b7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDisplayName(String userName) {
    // Email adresinden kullanıcı adını çıkar
    if (userName.contains('@')) {
      return userName.split('@')[0];
    }
    return userName;
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFe2e8f0), width: 1.5),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: Color(0xFF3b82f6)),
        label: Text(
          label,
          style: TextStyle(
            color: Color(0xFF3b82f6),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentTypeButton({
    required bool selected,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Color(0xFF3b82f6) : Color(0xFFe2e8f0),
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Color(0xFF3b82f6).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Color(0xFF6b7280),
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: selected ? Colors.white : Color(0xFF374151),
                  fontSize: 14,
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

  Widget _buildQuickAccessButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFe2e8f0), width: 1.5),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: Color(0xFF3b82f6)),
        label: Text(
          label,
          style: TextStyle(
            color: Color(0xFF3b82f6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
