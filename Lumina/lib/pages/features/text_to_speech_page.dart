import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../../services/text_to_speech_service.dart';
import '../../services/file_manager_service.dart';
import '../../services/web_file_service.dart';
import '../../services/elevenlabs_tts_service.dart';
import '../../services/gemini_tts_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum TTSProvider { device, elevenlabs, cloud, openai, gemini }

class TextToSpeechPage extends StatefulWidget {
  const TextToSpeechPage({super.key});

  @override
  State<TextToSpeechPage> createState() => _TextToSpeechPageState();
}

class _TextToSpeechPageState extends State<TextToSpeechPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final TextToSpeechService _ttsService = TextToSpeechService();
  final ElevenLabsTTSService _elevenLabsTTS = ElevenLabsTTSService();
  final GeminiTTSService _geminiTTS = GeminiTTSService();
  final FileManagerService _fileManager = FileManagerService();
  final WebFileService _webFileService = WebFileService();

  bool isPlaying = false;
  bool isLoading = false;
  String? selectedFileName;
  String extractedText = '';
  List<FileSystemEntity> uploadedFiles = [];
  TTSProvider selectedProvider = TTSProvider.device;

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

    _initializeServices();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _ttsService.dispose();
    _elevenLabsTTS.dispose();
    _geminiTTS.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      await _ttsService.initialize();
      await _loadUploadedFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Servis başlatma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF1e40af);
    final Color softBlue = const Color(0xFF3b82f6);
    final Color lightBlue = const Color(0xFF60a5fa);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.volume_up_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metinden Sese',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'AI Destekli Ses Dönüştürücü',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, softBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              softBlue,
              lightBlue,
              Color(0xFF93c5fd),
              Color(0xFFdbeafe),
              Color(0xFFf1f5f9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hoş geldiniz kartı
                    _buildWelcomeCard(),
                    const SizedBox(height: 20),

                    // TTS Sağlayıcı Seçimi
                    _buildProviderSelectionCard(),
                    const SizedBox(height: 20),

                    // Dosya seçme butonu
                    _buildFileSelectionCard(),
                    const SizedBox(height: 20),

                    // Metin girişi alanı
                    _buildTextInputCard(),
                    const SizedBox(height: 20),

                    // Kontrol butonları
                    _buildControlButtons(),
                    const SizedBox(height: 20),

                    // Durum kartı
                    _buildStatusCard(),
                    const SizedBox(height: 20),

                    // Yüklenen Dosyalar
                    if (uploadedFiles.isNotEmpty) ...[
                      _buildUploadedFilesCard(),
                      const SizedBox(height: 20),
                    ],

                    // Hızlı örnekler
                    _buildQuickExamplesCard(),
                    const SizedBox(height: 20),

                    // Ses ayarları kartı
                    _buildAudioSettingsCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Hoş geldiniz kartı
  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1e40af).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0xFF3b82f6).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFdbeafe), Color(0xFFbfdbfe)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF1e40af).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF1e40af),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Metinden Sese Dönüştürücü',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Color(0xFF1f2937),
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Metinlerinizi doğal sese dönüştürün',
                      style: TextStyle(
                        color: Color(0xFF6b7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFf0f9ff), Color(0xFFe0f2fe)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFbfdbfe), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF0ea5e9).withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF0ea5e9),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cihaz TTS ücretsizdir. ElevenLabs için API anahtarı gerekir.',
                    style: TextStyle(
                      color: Color(0xFF0c4a6e),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TTS Sağlayıcı Seçim Kartı
  Widget _buildProviderSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1e40af).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0xFF3b82f6).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  Icons.settings_rounded,
                  color: Color(0xFF1e40af),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'TTS Sağlayıcısı',
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
          Row(
            children: [
              Expanded(
                child: _buildProviderChip(
                  TTSProvider.device,
                  'Cihaz TTS',
                  'Ücretsiz, hızlı',
                  Icons.phone_android_rounded,
                  Color(0xFF16a34a),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProviderChip(
                  TTSProvider.elevenlabs,
                  'ElevenLabs',
                  'Ücretli, doğal',
                  Icons.psychology_rounded,
                  Color(0xFF7c3aed),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProviderChip(
                  TTSProvider.gemini,
                  'Gemini',
                  'Google AI, ücretsiz',
                  Icons.auto_awesome_rounded,
                  Color(0xFF0ea5e9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderChip(
    TTSProvider provider,
    String title,
    String subtitle,
    IconData icon,
    Color accentColor,
  ) {
    final isSelected = selectedProvider == provider;
    final isDisabled =
        provider == TTSProvider.elevenlabs && !_isProviderConfigured(provider);

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                selectedProvider = provider;
              });
            },
      child: Container(
        width: double.infinity,
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isDisabled ? Color(0xFFf3f4f6) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDisabled ? Color(0xFFd1d5db) : Color(0xFFe5e7eb)),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDisabled ? Color(0xFF9ca3af) : Color(0xFF6b7280)),
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDisabled ? Color(0xFF9ca3af) : Color(0xFF374151)),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : (isDisabled ? Color(0xFF9ca3af) : Color(0xFF6b7280)),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Dosya seçme kartı
  Widget _buildFileSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1e40af).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0xFF3b82f6).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    colors: [Color(0xFFdcfce7), Color(0xFFbbf7d0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  color: Color(0xFF16a34a),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Dosya Seç',
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
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF3b82f6).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color(0xFF1d4ed8).withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _pickFile,
              icon: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.upload_file_rounded, size: 20),
              label: Text(
                isLoading ? 'İşleniyor...' : 'PDF/TXT Dosyası Seç',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (selectedFileName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFf0fdf4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFbbf7d0), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16a34a),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seçilen dosya: $selectedFileName',
                      style: TextStyle(
                        color: Color(0xFF166534),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Metin girişi kartı
  Widget _buildTextInputCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1e40af).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0xFF3b82f6).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  Icons.text_fields_rounded,
                  color: Color(0xFF1e40af),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Metin',
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
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF3b82f6).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Color(0xFF1e40af).withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _textController,
              maxLines: 10,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF1f2937),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText:
                    'Sese dönüştürmek istediğiniz metni buraya yazın veya dosya seçin...',
                hintStyle: TextStyle(color: Color(0xFF9ca3af), fontSize: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Color(0xFFe5e7eb), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Color(0xFF3b82f6), width: 2.5),
                ),
                filled: true,
                fillColor: Color(0xFFf9fafb),
                contentPadding: EdgeInsets.all(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Kontrol butonları
  Widget _buildControlButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF3b82f6).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Color(0xFF1d4ed8).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _textController.text.trim().isEmpty || isLoading
                      ? null
                      : _togglePlayback,
                  icon: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          size: 20,
                        ),
                  label: Text(
                    isLoading
                        ? 'İşleniyor...'
                        : (isPlaying ? 'Durdur' : 'Oynat'),
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF16a34a), Color(0xFF15803d)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF16a34a).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Color(0xFF15803d).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _textController.text.trim().isEmpty || isLoading
                      ? null
                      : _saveAsAudio,
                  icon: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    isLoading ? 'Kaydediliyor...' : 'Ses Olarak Kaydet',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366f1), Color(0xFF4f46e5)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF6366f1).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0xFF4f46e5).withValues(alpha: 0.15),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _textController.text.trim().isEmpty || isLoading
                ? null
                : _clearText,
            icon: Icon(Icons.clear_rounded, size: 20),
            label: Text(
              'Metni Temizle',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Durum kartı
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1e40af).withValues(alpha: 0.1),
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
                  Icons.info_outline_rounded,
                  color: Color(0xFF1e40af),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Durum',
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPlaying ? Color(0xFFdcfce7) : Color(0xFFf3f4f6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPlaying
                      ? Icons.play_circle_rounded
                      : Icons.stop_circle_rounded,
                  color: isPlaying ? Color(0xFF16a34a) : Color(0xFF6b7280),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Durum: ${isPlaying ? "Oynatılıyor" : "Hazır"}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sağlayıcı: ${_getProviderName(selectedProvider)}',
                      style: TextStyle(
                        color: Color(0xFF6b7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Yüklenen dosyalar kartı
  Widget _buildUploadedFilesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1e40af).withValues(alpha: 0.1),
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
                    colors: [Color(0xFFdcfce7), Color(0xFFbbf7d0)],
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
                'Yüklenen Dosyalar',
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
          ...uploadedFiles.map((file) => _buildFileItem(file)),
        ],
      ),
    );
  }

  // Hızlı örnekler kartı
  Widget _buildQuickExamplesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1e40af).withValues(alpha: 0.1),
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
                  Icons.lightbulb_rounded,
                  color: Color(0xFF1e40af),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Hızlı Örnekler',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildExampleChip('Merhaba, nasılsınız?'),
              _buildExampleChip('Bugün hava çok güzel.'),
              _buildExampleChip('Yapay zeka geleceğimizi şekillendiriyor.'),
              _buildExampleChip('Erişilebilirlik herkes için önemli.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExampleChip(String text) {
    return ActionChip(
      label: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF3b82f6),
        ),
      ),
      onPressed: () {
        _textController.text = text;
        Future.delayed(const Duration(milliseconds: 100), () {
          _togglePlayback();
        });
      },
      backgroundColor: Color(0xFFdbeafe),
      side: BorderSide(color: Color(0xFFbfdbfe), width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildFileItem(FileSystemEntity file) {
    final String fileName = path.basename(file.path);
    final String extension = path.extension(fileName).toLowerCase();

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFe2e8f0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: extension == '.pdf'
                  ? Color(0xFFfef2f2)
                  : Color(0xFFf0f9ff),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              extension == '.pdf'
                  ? Icons.picture_as_pdf_rounded
                  : Icons.text_snippet_rounded,
              color: extension == '.pdf'
                  ? Color(0xFFdc2626)
                  : Color(0xFF2563eb),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1f2937),
                  ),
                ),
                Text(
                  '${(file.statSync().size / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFdbeafe),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF3b82f6),
                  ),
                  onPressed: () => _loadFileContent(file.path),
                  tooltip: 'Yükle ve Oynat',
                  style: IconButton.styleFrom(padding: EdgeInsets.all(8)),
                ),
              ),
              SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFfef2f2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.delete_rounded, color: Color(0xFFdc2626)),
                  onPressed: () => _deleteFile(file.path),
                  tooltip: 'Sil',
                  style: IconButton.styleFrom(padding: EdgeInsets.all(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Dosya seçme fonksiyonu
  Future<void> _pickFile() async {
    try {
      setState(() {
        isLoading = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        final file = result.files.single;
        String fileName = file.name;

        setState(() {
          selectedFileName = fileName;
        });

        String text = '';

        if (file.path != null) {
          text = await _ttsService.processUploadedFile(file.path!, fileName);
        } else if (file.bytes != null) {
          text = await _webFileService.processFile(file.bytes!, fileName);
        }

        if (text.isNotEmpty) {
          setState(() {
            extractedText = text;
            _textController.text = text;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$fileName dosyası yüklendi ve metin çıkarıldı (${text.length} karakter)',
                ),
                backgroundColor: Color(0xFF16a34a),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Dosyadan metin çıkarılamadı'),
                backgroundColor: Color(0xFFd97706),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Metni oynatma/durdurma fonksiyonu
  Future<void> _togglePlayback() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lütfen okunacak metin girin'),
            backgroundColor: Color(0xFF6366f1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    try {
      if (isPlaying) {
        if (selectedProvider == TTSProvider.elevenlabs) {
          await _elevenLabsTTS.stopAudio();
        } else if (selectedProvider == TTSProvider.gemini) {
          await _geminiTTS.stopAudio();
        } else {
          await _ttsService.stopSpeaking();
        }
        setState(() {
          isPlaying = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ses durduruldu'),
              backgroundColor: Color(0xFF6366f1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        setState(() {
          isPlaying = true;
        });

        if (selectedProvider == TTSProvider.elevenlabs) {
          final audioPath = await _elevenLabsTTS.synthesizeSpeech(text: text);
          await _elevenLabsTTS.playAudio(audioPath);
        } else if (selectedProvider == TTSProvider.gemini) {
          final audioPath = await _geminiTTS.synthesizeSpeech(text: text);
          await _geminiTTS.playAudio(audioPath);
        } else {
          await _ttsService.speakText(text);
        }

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              isPlaying = selectedProvider == TTSProvider.elevenlabs
                  ? _elevenLabsTTS.isPlaying
                  : selectedProvider == TTSProvider.gemini
                  ? _geminiTTS.isPlaying
                  : _ttsService.isPlaying;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        isPlaying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // Ses dosyası olarak kaydetme fonksiyonu
  Future<void> _saveAsAudio() async {
    if (_textController.text.isEmpty) return;

    try {
      setState(() {
        isLoading = true;
      });

      String fileName = selectedFileName ?? 'ses_dosyasi';
      fileName = path.basenameWithoutExtension(fileName);

      String audioPath = await _ttsService.saveTextAsAudio(
        _textController.text,
        fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ses dosyası kaydedildi: $audioPath'),
            backgroundColor: Color(0xFF16a34a),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Yüklenen dosyaları yükle
  Future<void> _loadUploadedFiles() async {
    try {
      final files = await _fileManager.getUploadedFiles();
      setState(() {
        uploadedFiles = files;
      });
    } catch (e) {
      // Dosya listesi yükleme hatası
    }
  }

  // Dosya içeriğini yükle
  Future<void> _loadFileContent(String filePath) async {
    try {
      setState(() {
        isLoading = true;
      });

      final String text = await _ttsService.extractTextFromFile(filePath);

      if (text.isNotEmpty) {
        setState(() {
          _textController.text = text;
          selectedFileName = path.basename(filePath);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${path.basename(filePath)} yüklendi'),
              backgroundColor: Color(0xFF16a34a),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Dosyayı sil
  Future<void> _deleteFile(String filePath) async {
    try {
      await _fileManager.deleteFile(filePath);
      await _loadUploadedFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${path.basename(filePath)} silindi'),
            backgroundColor: Color(0xFF6366f1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  String _getProviderName(TTSProvider provider) {
    switch (provider) {
      case TTSProvider.device:
        return 'Cihaz TTS (Ücretsiz)';
      case TTSProvider.elevenlabs:
        return 'ElevenLabs TTS (Ücretli)';
      case TTSProvider.cloud:
        return 'Firebase Cloud';
      case TTSProvider.openai:
        return 'OpenAI TTS';
      case TTSProvider.gemini:
        return 'Gemini TTS (Ücretsiz)';
    }
  }

  // Metni temizle
  void _clearText() {
    setState(() {
      _textController.clear();
      selectedFileName = null;
      extractedText = '';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Metin temizlendi'),
          backgroundColor: Color(0xFF6366f1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // API anahtarı kontrolü
  bool _isProviderConfigured(TTSProvider provider) {
    switch (provider) {
      case TTSProvider.elevenlabs:
        final key = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
        return key.isNotEmpty && key != 'YOUR_ELEVENLABS_API_KEY_HERE';
      case TTSProvider.device:
        return true;
      case TTSProvider.cloud:
        return true;
      case TTSProvider.openai:
        return false;
      case TTSProvider.gemini:
        final key = dotenv.env['GEMINI_API_KEY'] ?? '';
        return key.isNotEmpty && key != 'YOUR_GEMINI_API_KEY_HERE';
    }
  }

  // Ses ayarları kartı
  Widget _buildAudioSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1e40af).withValues(alpha: 0.1),
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
                    colors: [Color(0xFFe0e7ff), Color(0xFFc7d2fe)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF4f46e5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Ses Ayarları',
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
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFe0e7ff), Color(0xFFc7d2fe)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF6366f1), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.volume_up_rounded,
                      color: Color(0xFF4f46e5),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cihaz TTS Ayarları',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF3730a3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Cihaz TTS ayarları sistem ayarlarından değiştirilebilir.',
                  style: TextStyle(
                    color: Color(0xFF3730a3),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                if (selectedProvider == TTSProvider.elevenlabs) ...[
                  Divider(color: Color(0xFF6366f1), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        color: Color(0xFF4f46e5),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ElevenLabs Ayarları',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF3730a3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ElevenLabs API anahtarınızı .env dosyasına ekleyin.',
                    style: TextStyle(
                      color: Color(0xFF3730a3),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (selectedProvider == TTSProvider.gemini) ...[
                  Divider(color: Color(0xFF6366f1), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF4f46e5),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Gemini TTS Ayarları',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF3730a3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gemini API anahtarınızı .env dosyasına ekleyin.',
                    style: TextStyle(
                      color: Color(0xFF3730a3),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
