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
  String recognizedText = '';
  String partialText = '';
  List<FileSystemEntity> savedTextFiles = [];

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

    _sttService.initialize();
    _loadSavedTextFiles();
    _animationController.forward();
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
                    // Hoş geldiniz kartı
                    _buildWelcomeCard(),
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

  // Hoş geldiniz kartı
  Widget _buildWelcomeCard() {
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
                      color: Color(0xFF2563EB).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mic_rounded,
                  color: Color(0xFF2563EB),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sesten Metne Dönüştürücü',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Color(0xFF1f2937),
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sesinizi metne dönüştürün',
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
                    'Net ve yavaş konuşun. Gürültülü ortamlardan kaçının.',
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

  // Mikrofon kontrolü kartı
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
              onPressed: isLoading ? null : _toggleListening,
              icon: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 24,
                    ),
              label: Text(
                isLoading
                    ? 'İşleniyor...'
                    : (isListening ? 'Dinlemeyi Durdur' : 'Dinlemeye Başla'),
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
                          'Konuşmaya başlayın',
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
        ],
      ),
    );
  }

  // Tanınan metin alanı kartı
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
            ],
          ),
        ],
      ),
    );
  }

  // Dinleme başlatma/durdurma fonksiyonu
  Future<void> _toggleListening() async {
    try {
      if (isListening) {
        await _sttService.stopListening();
        setState(() {
          isListening = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dinleme durduruldu'),
              backgroundColor: Color(0xFF6366f1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        setState(() {
          isListening = true;
          partialText = '';
        });

        await _sttService.startListening(
          onResult: (text) {
            setState(() {
              recognizedText = text;
              _textController.text = text;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Metin tanındı: ${text.length} karakter'),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          onListeningComplete: () {
            setState(() {
              isListening = false;
            });
          },
        );
      }
    } catch (e) {
      setState(() {
        isListening = false;
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

  // Metni temizleme fonksiyonu
  void _clearText() {
    setState(() {
      _textController.clear();
      recognizedText = '';
      partialText = '';
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

  // Metni kaydetme fonksiyonu
  Future<void> _saveText() async {
    if (_textController.text.isEmpty) return;

    try {
      setState(() {
        isLoading = true;
      });

      final String fileName =
          'taninan_metin_${DateTime.now().millisecondsSinceEpoch}';
      final String filePath = await _sttService.saveRecognizedTextToFile(
        _textController.text,
        fileName,
      );

      await _loadSavedTextFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Metin kaydedildi: ${path.basename(filePath)}'),
            backgroundColor: Colors.green,
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
      setState(() {
        isLoading = true;
      });

      final File file = File(filePath);
      final String content = await file.readAsString();

      setState(() {
        _textController.text = content;
        recognizedText = content;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${path.basename(filePath)} yüklendi'),
            backgroundColor: Colors.green,
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

  // Metin dosyasını sil
  Future<void> _deleteTextFile(String filePath) async {
    try {
      final File file = File(filePath);
      await file.delete();
      await _loadSavedTextFiles();

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

  Widget _buildTipChip(String tip) {
    return Chip(
      label: Text(tip),
      backgroundColor: const Color(0xFFE0E7FF),
      labelStyle: const TextStyle(color: Color(0xFF2563EB)),
    );
  }
}
