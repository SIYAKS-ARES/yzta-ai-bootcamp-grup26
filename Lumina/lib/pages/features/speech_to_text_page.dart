import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../../services/speech_to_text_service.dart';

class SpeechToTextPage extends StatefulWidget {
  const SpeechToTextPage({super.key});

  @override
  State<SpeechToTextPage> createState() => _SpeechToTextPageState();
}

class _SpeechToTextPageState extends State<SpeechToTextPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final SpeechToTextService _sttService = SpeechToTextService();

  bool isListening = false;
  bool isLoading = false;
  bool isInitialized = false;
  String recognizedText = '';
  String partialText = '';
  String? lastError;
  List<FileSystemEntity> savedTextFiles = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

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
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeSTT();
    _loadSavedTextFiles();
    _animationController.forward();
  }

  // STT servisini başlatma
  Future<void> _initializeSTT() async {
    try {
      setState(() {
        isLoading = true;
      });

      bool initialized = await _sttService.initialize();

      if (mounted) {
        setState(() {
          isInitialized = initialized;
          isLoading = false;
        });

        if (!initialized) {
          _showErrorSnackBar(_sttService.lastError ?? 'Servis başlatılamadı');
        } else {
          // Dil bilgisini göster
          String languageInfo = _sttService.currentLocaleId;
          if (languageInfo.startsWith('tr')) {
            languageInfo = 'Türkçe (${_sttService.currentLocaleId})';
          }

          // Android emülatör uyarısı
          if (Platform.isAndroid) {
            _showSuccessSnackBar(
              'Ses tanıma servisi hazır - $languageInfo\nNot: Emülatörde sorun yaşayabilirsiniz',
            );
          } else {
            _showSuccessSnackBar('Ses tanıma servisi hazır - $languageInfo');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isInitialized = false;
        });
        _showErrorSnackBar('Başlatma hatası: $e');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _sttService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2563EB);
    final Color softBlue = const Color(0xFF60A5FA);

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
              child: Icon(Icons.mic_rounded, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesten Metne',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'AI Destekli Ses Tanıma',
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
        actions: [
          // Debug butonu
          IconButton(
            icon: Icon(Icons.bug_report_rounded),
            onPressed: _debugSTT,
            tooltip: 'Debug Bilgileri',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              softBlue,
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
                    // Durum kartı
                    _buildStatusCard(),
                    const SizedBox(height: 20),

                    // Mikrofon kontrolü
                    _buildMicrophoneCard(),
                    const SizedBox(height: 20),

                    // Tanınan metin alanı
                    _buildTextAreaCard(),
                    const SizedBox(height: 20),

                    // Kontrol butonları
                    _buildControlButtons(),
                    const SizedBox(height: 20),

                    // Kaydedilen Metin Dosyaları
                    if (savedTextFiles.isNotEmpty) ...[
                      _buildSavedFilesCard(),
                      const SizedBox(height: 20),
                    ],

                    // Kullanım İpuçları
                    _buildTipsCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Durum kartı - yeni
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isInitialized ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isInitialized ? Icons.check_circle : Icons.error,
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
                  isInitialized ? 'Servis Hazır' : 'Servis Başlatılıyor...',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1f2937),
                  ),
                ),
                Text(
                  isInitialized
                      ? 'Ses tanıma servisi aktif'
                      : 'Lütfen bekleyin...',
                  style: TextStyle(color: Color(0xFF6b7280), fontSize: 14),
                ),
              ],
            ),
          ),
          if (isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ),
        ],
      ),
    );
  }

  // Mikrofon kontrolü kartı - geliştirilmiş
  Widget _buildMicrophoneCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0xFF60A5FA).withValues(alpha: 0.05),
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
                  Icons.mic_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Ses Tanıma',
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
                colors: isListening
                    ? [Color(0xFFdc2626), Color(0xFFb91c1c)]
                    : [Color(0xFF2563EB), Color(0xFF1d4ed8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isListening ? Color(0xFFdc2626) : Color(0xFF2563EB))
                      .withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: (isListening ? Color(0xFFb91c1c) : Color(0xFF1d4ed8))
                      .withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: (!isInitialized || isLoading)
                  ? null
                  : _toggleListening,
              icon: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: isListening ? _pulseAnimation.value : 1.0,
                          child: Icon(
                            isListening
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            size: 24,
                          ),
                        );
                      },
                    ),
              label: Text(
                isLoading
                    ? 'İşleniyor...'
                    : (!isInitialized
                          ? 'Servis Başlatılıyor...'
                          : (isListening
                                ? 'Dinlemeyi Durdur'
                                : 'Dinlemeye Başla')),
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          if (isListening) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFfef2f2), Color(0xFFfee2e2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFfecaca), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFdc2626).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFFdc2626),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dinleniyor...',
                          style: TextStyle(
                            color: Color(0xFF991b1b),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Konuşmaya başlayın (${_sttService.currentLocaleId})',
                          style: TextStyle(
                            color: Color(0xFF7f1d1d),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (lastError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFfef2f2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFfecaca), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFdc2626),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lastError!,
                      style: TextStyle(color: Color(0xFF991b1b), fontSize: 14),
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

  // Tanınan metin alanı kartı - geliştirilmiş
  Widget _buildTextAreaCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0xFF60A5FA).withValues(alpha: 0.05),
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
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tanınan Metin',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF1f2937),
                  letterSpacing: 0.3,
                ),
              ),
              Spacer(),
              if (_textController.text.isNotEmpty)
                Text(
                  '${_textController.text.length} karakter',
                  style: TextStyle(
                    color: Color(0xFF6b7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
                  color: Color(0xFF2563EB).withValues(alpha: 0.08),
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
                hintText: 'Tanınan metin burada görünecek...',
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
                  borderSide: BorderSide(color: Color(0xFF2563EB), width: 2.5),
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

  // Kontrol butonları - geliştirilmiş
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
                  onPressed: _textController.text.isEmpty || isLoading
                      ? null
                      : _clearText,
                  icon: Icon(Icons.clear_rounded, size: 20),
                  label: Text(
                    'Temizle',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
                  onPressed: _textController.text.isEmpty || isLoading
                      ? null
                      : _saveText,
                  icon: Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    'Metni Kaydet',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Kaydedilen dosyalar kartı
  Widget _buildSavedFilesCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0xFF60A5FA).withValues(alpha: 0.05),
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
                  Icons.folder_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Kaydedilen Metin Dosyaları',
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
          ...savedTextFiles.map((file) => _buildTextFileItem(file)),
        ],
      ),
    );
  }

  // Kullanım ipuçları kartı
  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0xFF60A5FA).withValues(alpha: 0.05),
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
                  Icons.lightbulb_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Kullanım İpuçları',
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
              _buildTipChip('Net ve yavaş konuşun'),
              _buildTipChip('Gürültülü ortamlardan kaçının'),
              _buildTipChip('Mikrofonu ağzınıza yakın tutun'),
              _buildTipChip('Cümle sonlarında duraklayın'),
              _buildTipChip('Türkçe karakterleri vurgulayın'),
              _buildTipChip('Kısa cümleler kullanın'),
              if (Platform.isAndroid)
                _buildTipChip('Emülatörde fiziksel cihazdan daha az doğru'),
            ],
          ),
        ],
      ),
    );
  }

  // Dinleme başlatma/durdurma fonksiyonu - geliştirilmiş
  Future<void> _toggleListening() async {
    try {
      if (isListening) {
        await _sttService.stopListening();
        if (mounted) {
          setState(() {
            isListening = false;
          });
          _showSuccessSnackBar('Dinleme durduruldu');
        }
      } else {
        // Android emülatör uyarısı
        if (Platform.isAndroid) {
          _showInfoSnackBar(
            'Android emülatörde ses tanıma sınırlı olabilir. Fiziksel cihazda daha iyi sonuç alırsınız.',
          );
        }

        if (mounted) {
          setState(() {
            isListening = true;
            partialText = '';
            lastError = null;
          });
        }

        bool success = await _sttService.startListening(
          onResult: (text) {
            if (mounted) {
              setState(() {
                recognizedText = text;
                _textController.text = text;
              });

              // Türkçe karakter kontrolü ve düzeltme
              String correctedText = _correctTurkishText(text);
              if (correctedText != text) {
                setState(() {
                  _textController.text = correctedText;
                  recognizedText = correctedText;
                });
                _showSuccessSnackBar(
                  'Metin düzeltildi: ${correctedText.length} karakter',
                );
              } else {
                _showSuccessSnackBar('Metin tanındı: ${text.length} karakter');
              }
            }
          },
          onListeningComplete: () {
            if (mounted) {
              setState(() {
                isListening = false;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                lastError = error;
                isListening = false;
              });

              // Android emülatör için özel mesaj
              if (Platform.isAndroid && error.contains('emülatör')) {
                _showErrorSnackBar(
                  '$error\nFiziksel cihazda test etmeyi deneyin.',
                );
              } else {
                _showErrorSnackBar(error);
              }
            }
          },
        );

        if (!success && mounted) {
          setState(() {
            isListening = false;
            lastError = _sttService.lastError;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isListening = false;
          lastError = e.toString();
        });
        _showErrorSnackBar('Hata: $e');
      }
    }
  }

  // Debug fonksiyonu - geliştirilmiş
  Future<void> _debugSTT() async {
    try {
      final debugInfo = await _sttService.debugSTT();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.bug_report_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text('Debug Bilgileri'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Platform bilgisi
                  _buildDebugSection('Platform Bilgisi', {
                    'İşletim Sistemi': Platform.operatingSystem,
                    'Platform': Platform.isAndroid ? 'Android' : 'iOS',
                    'Emülatör': Platform.isAndroid
                        ? 'Muhtemelen Evet'
                        : 'Hayır',
                  }),

                  // Servis durumu
                  _buildDebugSection('Servis Durumu', {
                    'Başlatıldı': debugInfo['initialized']
                        ? '✅ Evet'
                        : '❌ Hayır',
                    'Dinleniyor': debugInfo['isListening']
                        ? '🔴 Evet'
                        : '⚪ Hayır',
                    'Son Hata': debugInfo['lastError'] ?? 'Yok',
                  }),

                  // Dil bilgisi
                  _buildDebugSection('Dil Bilgisi', {
                    'Mevcut Dil': debugInfo['currentLocaleId'] ?? 'Bilinmiyor',
                    'Desteklenen Dil Sayısı':
                        debugInfo['supportedLocalesCount'] ?? 'Bilinmiyor',
                  }),

                  // Son tanınan metin
                  if (debugInfo['lastWords'] != null &&
                      debugInfo['lastWords'].isNotEmpty)
                    _buildDebugSection('Son Tanınan Metin', {
                      'Metin': debugInfo['lastWords'],
                      'Karakter Sayısı': debugInfo['lastWords'].length
                          .toString(),
                    }),

                  // Desteklenen diller
                  if (debugInfo['supportedLocales'] != null)
                    _buildDebugSection(
                      'Desteklenen Diller',
                      Map.fromEntries(
                        (debugInfo['supportedLocales'] as List).map(
                          (locale) => MapEntry(locale['id'], locale['name']),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Kapat'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSuccessSnackBar('Debug bilgileri kopyalandı');
                },
                child: Text('Kopyala'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Debug hatası: $e');
      }
    }
  }

  Widget _buildDebugSection(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        ...data.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${entry.value}',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 16),
      ],
    );
  }

  // Metni temizleme fonksiyonu
  void _clearText() {
    setState(() {
      _textController.clear();
      recognizedText = '';
      partialText = '';
      lastError = null;
    });

    _showSuccessSnackBar('Metin temizlendi');
  }

  // Metni kaydetme fonksiyonu - geliştirilmiş
  Future<void> _saveText() async {
    if (_textController.text.isEmpty) return;

    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final String fileName =
          'taninan_metin_${DateTime.now().millisecondsSinceEpoch}';
      final String filePath = await _sttService.saveRecognizedTextToFile(
        _textController.text,
        fileName,
      );

      await _loadSavedTextFiles();

      if (mounted) {
        _showSuccessSnackBar('Metin kaydedildi: ${path.basename(filePath)}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Kaydetme hatası: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Kaydedilen metin dosyalarını yükle
  Future<void> _loadSavedTextFiles() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String textDir = path.join(appDir.path, 'recognized_text');

      final Directory dir = Directory(textDir);
      if (await dir.exists()) {
        final List<FileSystemEntity> files = await dir.list().toList();
        setState(() {
          savedTextFiles = files
              .where(
                (file) => file is File && path.extension(file.path) == '.txt',
              )
              .toList();
        });
      }
    } catch (e) {
      developer.log(
        "Metin dosyaları yükleme hatası: $e",
        name: 'SpeechToTextPage',
      );
    }
  }

  Widget _buildTextFileItem(FileSystemEntity file) {
    final String fileName = path.basename(file.path);
    final String fileSize =
        '${(file.statSync().size / 1024).toStringAsFixed(1)} KB';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.text_snippet, color: Colors.blue),
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(fileSize),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _loadTextFileContent(file.path),
              tooltip: 'Görüntüle',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteTextFile(file.path),
              tooltip: 'Sil',
            ),
          ],
        ),
      ),
    );
  }

  // Metin dosyası içeriğini yükle
  Future<void> _loadTextFileContent(String filePath) async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final File file = File(filePath);
      final String content = await file.readAsString();

      if (mounted) {
        setState(() {
          _textController.text = content;
          recognizedText = content;
        });
        _showSuccessSnackBar('${path.basename(filePath)} yüklendi');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Yükleme hatası: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Metin dosyasını sil
  Future<void> _deleteTextFile(String filePath) async {
    try {
      final File file = File(filePath);
      await file.delete();
      await _loadSavedTextFiles();

      if (mounted) {
        _showSuccessSnackBar('${path.basename(filePath)} silindi');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Silme hatası: $e');
      }
    }
  }

  Widget _buildTipChip(String tip) {
    return Chip(
      label: Text(tip),
      backgroundColor: const Color(0xFFE0E7FF),
      labelStyle: const TextStyle(color: Color(0xFF2563EB)),
    );
  }

  // SnackBar yardımcı fonksiyonları
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Color(0xFF16a34a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Color(0xFFdc2626),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // Bilgi SnackBar'ı - yeni
  void _showInfoSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Color(0xFF0ea5e9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // Türkçe metin düzeltme fonksiyonu
  String _correctTurkishText(String text) {
    if (text.isEmpty) return text;

    // Yaygın Türkçe karakter hatalarını düzelt
    String corrected = text;

    // Büyük harf düzeltmeleri
    corrected = corrected.replaceAll('i̇', 'İ'); // i + nokta = İ
    corrected = corrected.replaceAll('İ', 'İ'); // I + nokta = İ

    // Küçük harf düzeltmeleri
    corrected = corrected.replaceAll('İ', 'i'); // İ -> i (başta değilse)
    if (corrected.isNotEmpty && corrected[0] == 'i') {
      corrected = 'İ${corrected.substring(1)}';
    }

    // Yaygın kelime düzeltmeleri
    Map<String, String> corrections = {
      'evet': 'evet',
      'hayır': 'hayır',
      'tamam': 'tamam',
      'merhaba': 'merhaba',
      'güle güle': 'güle güle',
      'teşekkürler': 'teşekkürler',
      'rica ederim': 'rica ederim',
      'lütfen': 'lütfen',
      'affedersiniz': 'affedersiniz',
      'özür dilerim': 'özür dilerim',
    };

    // Kelime düzeltmelerini uygula
    corrections.forEach((wrong, correct) {
      corrected = corrected.replaceAll(wrong, correct);
    });

    // Cümle başı büyük harf yapma
    if (corrected.isNotEmpty) {
      corrected = '${corrected[0].toUpperCase()}${corrected.substring(1)}';
    }

    return corrected;
  }
}
