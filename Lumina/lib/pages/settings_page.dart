import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import '../services/text_to_speech_service.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../services/whisper_service.dart';
import '../api.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  final TextToSpeechService _ttsService = TextToSpeechService();

  bool notificationsEnabled = true;
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';

  // TTS ayarları
  double speechRate = 0.5;
  double volume = 1.0;
  String ttsLanguage = "tr-TR";

  // Whisper ayarları
  WhisperMode _selectedWhisperMode = WhisperMode.auto;
  bool _isWhisperInitialized = false;

  // Parola değiştirme controllers
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _ttsService.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

      // Whisper ayarlarını yükle
      await _loadWhisperSettings();

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWhisperSettings() async {
    try {
      final whisperService = Provider.of<WhisperService>(
        context,
        listen: false,
      );
      setState(() {
        _selectedWhisperMode = whisperService.currentMode;
        _isWhisperInitialized = whisperService.isInitialized;
      });
    } catch (e) {
      // Hata durumunda varsayılan değerler kullan
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF1e40af);
    final Color softBlue = const Color(0xFF3b82f6);
    final Color lightBlue = const Color(0xFF60a5fa);
    final languageService = Provider.of<LanguageService>(context);
    final themeService = Provider.of<ThemeService>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(languageService.getText('settings')),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  languageService.getText('loading'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(languageService.getText('settings')),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Kullanıcı info header
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
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
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryBlue, softBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xFF1f2937),
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _userEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6b7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.edit_rounded,
                          color: primaryBlue,
                          size: 24,
                        ),
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
                  ],
                ),
              ),

              // Dil seçimi
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        languageService.getText('language'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFf8fafc),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFFe2e8f0),
                          width: 1.5,
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: languageService.supportedLocales.entries
                            .firstWhere(
                              (entry) =>
                                  entry.value == languageService.currentLocale,
                            )
                            .key,
                        items: languageService.supportedLocales.keys.map((
                          lang,
                        ) {
                          return DropdownMenuItem<String>(
                            value: lang,
                            child: Text(
                              lang,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1f2937),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          if (val != null) {
                            await languageService.changeLanguage(val);
                            _updateTTSLanguage();
                          }
                        },
                        underline: SizedBox(),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: primaryBlue,
                          size: 20,
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),

              // Bildirimler
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
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
                        Icons.notifications_rounded,
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        languageService.getText('notifications'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                    ),
                    Switch(
                      value: notificationsEnabled,
                      onChanged: (val) {
                        setState(() {
                          notificationsEnabled = val;
                        });
                      },
                      activeThumbColor: primaryBlue,
                      activeTrackColor: primaryBlue.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),

              // Parola Değiştir
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showChangePasswordDialog();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFdcfce7), Color(0xFFbbf7d0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lock_reset_rounded,
                            color: Color(0xFF16a34a),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            languageService.currentLocale.languageCode == 'tr'
                                ? "Parola Değiştir"
                                : languageService.currentLocale.languageCode ==
                                      'en'
                                ? "Change Password"
                                : "Passwort ändern",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF9ca3af),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // TTS Ayarları Bölümü
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
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
                            Icons.volume_up_rounded,
                            color: primaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          languageService.currentLocale.languageCode == 'tr'
                              ? "Ses Ayarları"
                              : languageService.currentLocale.languageCode ==
                                    'en'
                              ? "Audio Settings"
                              : "Audioeinstellungen",
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

                    // Konuşma hızı
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              languageService.currentLocale.languageCode == 'tr'
                                  ? "Konuşma Hızı"
                                  : languageService
                                            .currentLocale
                                            .languageCode ==
                                        'en'
                                  ? "Speech Rate"
                                  : "Sprechgeschwindigkeit",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF374151),
                              ),
                            ),
                            Text(
                              "${(speechRate * 100).round()}%",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: primaryBlue,
                            inactiveTrackColor: Color(0xFFe5e7eb),
                            thumbColor: primaryBlue,
                            overlayColor: primaryBlue.withValues(alpha: 0.1),
                            trackHeight: 4,
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                          ),
                          child: Slider(
                            value: speechRate,
                            min: 0.1,
                            max: 1.0,
                            divisions: 9,
                            onChanged: (value) {
                              setState(() {
                                speechRate = value;
                              });
                              _ttsService.setSpeechRate(value);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Ses seviyesi
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              languageService.currentLocale.languageCode == 'tr'
                                  ? "Ses Seviyesi"
                                  : languageService
                                            .currentLocale
                                            .languageCode ==
                                        'en'
                                  ? "Volume Level"
                                  : "Lautstärke",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF374151),
                              ),
                            ),
                            Text(
                              "${(volume * 100).round()}%",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: primaryBlue,
                            inactiveTrackColor: Color(0xFFe5e7eb),
                            thumbColor: primaryBlue,
                            overlayColor: primaryBlue.withValues(alpha: 0.1),
                            trackHeight: 4,
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                          ),
                          child: Slider(
                            value: volume,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            onChanged: (value) {
                              setState(() {
                                volume = value;
                              });
                              _ttsService.setVolume(value);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Test butonu
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF3b82f6).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final testText =
                              languageService.currentLocale.languageCode == 'tr'
                              ? "Bu bir test sesidir. Ayarlarınız çalışıyor."
                              : languageService.currentLocale.languageCode ==
                                    'en'
                              ? "This is a test sound. Your settings are working."
                              : "Dies ist ein Testton. Ihre Einstellungen funktionieren.";
                          await _ttsService.speakText(testText);
                        },
                        icon: Icon(Icons.play_arrow_rounded, size: 20),
                        label: Text(
                          languageService.currentLocale.languageCode == 'tr'
                              ? "Ses Testi"
                              : languageService.currentLocale.languageCode ==
                                    'en'
                              ? "Audio Test"
                              : "Audiotest",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tema Değiştir
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
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
                        Icons.brightness_6_rounded,
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        languageService.getText('dark_theme'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                    ),
                    Switch(
                      value: themeService.isDarkMode,
                      onChanged: (val) async {
                        final currentContext = context;
                        await themeService.setTheme(val);
                        if (currentContext.mounted) {
                          final currentLanguageService =
                              Provider.of<LanguageService>(
                                currentContext,
                                listen: false,
                              );
                          showDialog(
                            context: currentContext,
                            builder: (BuildContext dialogContext) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text(
                                currentLanguageService.getText('dark_theme'),
                              ),
                              content: Text(
                                val
                                    ? "${currentLanguageService.getText('dark_theme')} seçildi."
                                    : "Açık tema seçildi.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: Text(
                                    currentLanguageService.getText('ok'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      activeThumbColor: primaryBlue,
                      activeTrackColor: primaryBlue.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),

              // Whisper Ayarları Bölümü
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
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
                              colors: [Color(0xFFfef3c7), Color(0xFFfde68a)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.mic_rounded,
                            color: Color(0xFFd97706),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Whisper Transkript Ayarları",
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

                    // Sağlayıcı Seçimi
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Transkript Sağlayıcısı",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFf8fafc),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFFe2e8f0),
                              width: 1.5,
                            ),
                          ),
                          child: DropdownButton<WhisperMode>(
                            value: _selectedWhisperMode,
                            items: [
                              DropdownMenuItem(
                                value: WhisperMode.auto,
                                child: Text(
                                  "Otomatik Seçim",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: WhisperMode.local,
                                child: Text(
                                  "Yerel Whisper (Offline)",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: WhisperMode.api,
                                child: Text(
                                  "OpenAI API",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (WhisperMode? newValue) async {
                              if (newValue != null) {
                                // setMode kaldırıldı - artık sadece API kullanılıyor
                                setState(() {
                                  _selectedWhisperMode = newValue;
                                });
                              }
                            },
                            underline: SizedBox(),
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: primaryBlue,
                              size: 20,
                            ),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // API Anahtarı (sadece API modunda göster)
                    if (_selectedWhisperMode == WhisperMode.api) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "OpenAI API Anahtarı",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: "sk-...",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFFe2e8f0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: primaryBlue,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              final whisperService =
                                  Provider.of<WhisperService>(
                                    context,
                                    listen: false,
                                  );
                              whisperService.setApiKey(value);
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "API anahtarınızı güvenli şekilde saklayın",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6b7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Durum Bilgisi
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _isWhisperInitialized
                                ? Color(0xFFdcfce7)
                                : Color(0xFFfef2f2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isWhisperInitialized
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: _isWhisperInitialized
                                    ? Color(0xFF16a34a)
                                    : Color(0xFFdc2626),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isWhisperInitialized
                                    ? "Hazır"
                                    : "Başlatılamadı",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isWhisperInitialized
                                      ? Color(0xFF16a34a)
                                      : Color(0xFFdc2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Mevcut: ${Provider.of<WhisperService>(context, listen: false).getModeInfo()}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6b7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Yardım ve Destek
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(languageService.getText('help_support')),
                          content: Text(
                            languageService.currentLocale.languageCode == 'tr'
                                ? "Her türlü soru için: destek@lumina.com"
                                : languageService.currentLocale.languageCode ==
                                      'en'
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
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
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
                            color: primaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            languageService.getText('help_support'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF9ca3af),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Gizlilik Politikası
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            languageService.getText('privacy_policy'),
                          ),
                          content: Text(
                            languageService.currentLocale.languageCode == 'tr'
                                ? "Bu gizlilik politikası, Lumina uygulamasının kullanıcı verilerini nasıl topladığını, kullandığını ve koruduğunu açıklar. Kişisel bilgileriniz güvenli bir şekilde saklanır ve üçüncü taraflarla paylaşılmaz. Uygulama kullanımı sırasında toplanan veriler sadece hizmet kalitesini artırmak için kullanılır."
                                : languageService.currentLocale.languageCode ==
                                      'en'
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
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFdcfce7), Color(0xFFbbf7d0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.privacy_tip_outlined,
                            color: Color(0xFF16a34a),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            languageService.getText('privacy_policy'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF9ca3af),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Güncellemeleri kontrol et
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            languageService.currentLocale.languageCode == 'tr'
                                ? "Güncellemeler"
                                : languageService.currentLocale.languageCode ==
                                      'en'
                                ? "Updates"
                                : "Updates",
                          ),
                          content: Text(
                            languageService.currentLocale.languageCode == 'tr'
                                ? "Uygulamanız güncel!"
                                : languageService.currentLocale.languageCode ==
                                      'en'
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
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
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
                            Icons.update_rounded,
                            color: primaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            languageService.currentLocale.languageCode == 'tr'
                                ? "Güncellemeleri Kontrol Et"
                                : languageService.currentLocale.languageCode ==
                                      'en'
                                ? "Check for Updates"
                                : "Nach Updates suchen",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF9ca3af),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Çıkış yap
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showLogoutDialog();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFfef2f2), Color(0xFFfecaca)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFdc2626),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            languageService.getText('logout'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFFdc2626),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF9ca3af),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageService.getText('cancel')),
          ),
          ElevatedButton(
            onPressed: () => _changePassword(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3b82f6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
              backgroundColor: Color(0xFF16a34a),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFdc2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
