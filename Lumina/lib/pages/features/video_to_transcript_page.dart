import 'package:flutter/material.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../services/whisper_service.dart';
import '../../api.dart';

class VideoToTranscriptPage extends StatefulWidget {
  const VideoToTranscriptPage({super.key});

  @override
  State<VideoToTranscriptPage> createState() => _VideoToTranscriptPageState();
}

class _VideoToTranscriptPageState extends State<VideoToTranscriptPage>
    with SingleTickerProviderStateMixin {
  String? selectedVideoPath;
  bool isProcessing = false;
  String transcriptText = '';
  double progress = 0.0;

  // Transkript sonucu
  TranscriptResult? _transcriptResult;
  List<TranscriptSegment> _segments = [];

  // Debug bilgileri
  String _debugInfo = '';
  bool _showDebugInfo = false;

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
    _animationController.forward();

    // Whisper servisini başlat
    _initializeWhisper();
  }

  @override
  void dispose() {
    _animationController.dispose();
    // _whisperService.dispose(); // Removed as WhisperService is now provided by Provider
    super.dispose();
  }

  // Whisper servisini başlat
  Future<void> _initializeWhisper() async {
    try {
      setState(() {
        isProcessing = true;
      });

      // Lazy loading - Whisper servisi otomatik başlatılacak
      final initialized = await Provider.of<WhisperService>(
        context,
        listen: false,
      ).initialize();

      if (mounted) {
        setState(() {
          // _isWhisperInitialized = initialized; // Removed as WhisperService is now provided by Provider
          isProcessing = false;
        });

        if (initialized) {
          _showSuccessSnackBar('Whisper servisi başarıyla başlatıldı');
        } else {
          _showErrorSnackBar(
            Provider.of<WhisperService>(context, listen: false).lastError ??
                'Whisper servisi başlatılamadı',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProcessing = false;
          // _isWhisperInitialized = false; // Removed as WhisperService is now provided by Provider
        });
        _showErrorSnackBar('Whisper başlatma hatası: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2563EB);
    final Color softBlue = const Color(0xFF60A5FA);
    final Color accentPurple = const Color(0xFF8B5CF6);

    return Consumer<WhisperService>(
      builder: (context, whisperService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video Transkript',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'AI ile video transkript oluştur',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              // Whisper durumu göstergesi
              Container(
                margin: EdgeInsets.only(right: 16),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: whisperService.isInitialized
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: whisperService.isInitialized
                        ? Colors.green.withValues(alpha: 0.5)
                        : Colors.orange.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: whisperService.isInitialized
                            ? Colors.green
                            : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      whisperService.isInitialized ? 'Hazır' : 'Başlatılıyor',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: whisperService.isInitialized
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, accentPurple, softBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
          ),
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentPurple.withValues(alpha: 0.1),
                  softBlue.withValues(alpha: 0.05),
                  Color(0xFFf8fafc),
                  Color(0xFFffffff),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SafeArea(
                child: CustomScrollView(
                  physics: BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Hoş geldiniz kartı
                            _buildWelcomeCard(),
                            const SizedBox(height: 24),

                            // Video seçimi
                            _buildVideoSelectionCard(),
                            const SizedBox(height: 24),

                            // İşlem durumu
                            if (isProcessing) ...[
                              _buildProcessingCard(),
                              const SizedBox(height: 24),
                            ],

                            // Transkript sonucu
                            if (transcriptText.isNotEmpty) ...[
                              _buildTranscriptCard(),
                            ] else if (!isProcessing) ...[
                              // Boş durum
                              _buildEmptyStateCard(),
                            ],

                            // İşlem butonu
                            if (selectedVideoPath != null && !isProcessing) ...[
                              const SizedBox(height: 24),
                              _buildProcessButton(),
                            ],

                            // Bottom padding
                            const SizedBox(height: 40),

                            // Debug toggle butonu
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showDebugInfo = !_showDebugInfo;
                                  if (_showDebugInfo) {
                                    _updateDebugInfo();
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  _showDebugInfo ? 'Debug Kapat' : 'Debug Aç',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),

                            // Debug butonu
                            if (_showDebugInfo)
                              Container(
                                margin: EdgeInsets.only(top: 16),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Debug Bilgileri',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      _debugInfo,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 12,
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
            ),
          ),
        );
      },
    );
  }

  // Hoş geldiniz kartı
  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8B5CF6).withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0xFF2563EB).withValues(alpha: 0.08),
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
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Video Transkript',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: Color(0xFF1f2937),
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Whisper AI ile video içeriğinizi metne dönüştürün',
                      style: TextStyle(
                        color: Color(0xFF6b7280),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFfaf5ff), Color(0xFFf3e8ff)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Color(0xFFe9d5ff), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Destekli Transkript',
                        style: TextStyle(
                          color: Color(0xFF581c87),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Offline çalışan Whisper AI ile yüksek doğrulukta transkript. Zaman damgaları ile birlikte.',
                        style: TextStyle(
                          color: Color(0xFF7c3aed),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Video seçimi kartı
  Widget _buildVideoSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8B5CF6).withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0xFF2563EB).withValues(alpha: 0.08),
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
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.video_file_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Video Dosyası Seçin',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Color(0xFF1f2937),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: selectedVideoPath != null
                    ? [Color(0xFFf0fdf4), Color(0xFFecfdf5)]
                    : [Color(0xFFfaf5ff), Color(0xFFf3e8ff)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selectedVideoPath != null
                    ? Color(0xFFbbf7d0)
                    : Color(0xFFe9d5ff),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (selectedVideoPath != null
                              ? Color(0xFF16a34a)
                              : Color(0xFF8B5CF6))
                          .withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: selectedVideoPath != null
                        ? Color(0xFFdcfce7)
                        : Color(0xFFf3e8ff),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selectedVideoPath != null
                          ? Color(0xFFbbf7d0)
                          : Color(0xFFe9d5ff),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (selectedVideoPath != null
                                    ? Color(0xFF16a34a)
                                    : Color(0xFF8B5CF6))
                                .withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    selectedVideoPath != null
                        ? Icons.check_circle_rounded
                        : Icons.video_library_rounded,
                    size: 56,
                    color: selectedVideoPath != null
                        ? Color(0xFF16a34a)
                        : Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  selectedVideoPath != null
                      ? 'Video Başarıyla Seçildi!'
                      : 'Video dosyası seçmek için tıklayın',
                  style: TextStyle(
                    color: selectedVideoPath != null
                        ? Color(0xFF16a34a)
                        : Color(0xFF581c87),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (selectedVideoPath != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF16a34a).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF16a34a).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      selectedVideoPath!.split('/').last,
                      style: TextStyle(
                        color: Color(0xFF16a34a),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: selectedVideoPath != null
                          ? [Color(0xFF16a34a), Color(0xFF15803d)]
                          : [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (selectedVideoPath != null
                                    ? Color(0xFF16a34a)
                                    : Color(0xFF8B5CF6))
                                .withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _selectVideo(),
                    icon: Icon(
                      selectedVideoPath != null
                          ? Icons.change_circle_rounded
                          : Icons.add_rounded,
                      size: 22,
                    ),
                    label: Text(
                      selectedVideoPath != null
                          ? 'Farklı Video Seç'
                          : 'Video Seç',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
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

  // İşlem durumu kartı
  Widget _buildProcessingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8B5CF6).withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0xFF2563EB).withValues(alpha: 0.08),
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
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.psychology_rounded,
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
                      'AI Transkript Oluşturuluyor',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Color(0xFF1f2937),
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Whisper AI video içeriğinizi analiz ediyor',
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
          const SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFfaf5ff), Color(0xFFf3e8ff)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Color(0xFFe9d5ff), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'AI Analiz Ediyor...',
                  style: TextStyle(
                    color: Color(0xFF581c87),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(0xFFe9d5ff),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF8B5CF6),
                      ),
                      minHeight: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${(progress * 100).toInt()}% tamamlandı',
                  style: TextStyle(
                    color: Color(0xFF7c3aed),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu işlem video uzunluğuna göre değişebilir',
                  style: TextStyle(
                    color: Color(0xFFa855f7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Transkript sonucu kartı
  Widget _buildTranscriptCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8B5CF6).withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Transkript',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: Color(0xFF1f2937),
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Whisper AI ile oluşturuldu',
                        style: TextStyle(
                          color: Color(0xFF6b7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => _copyTranscript(),
                      icon: Icon(
                        Icons.copy_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Color(0xFF16a34a), Color(0xFF15803d)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF16a34a).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => _saveTranscript(),
                      icon: Icon(
                        Icons.save_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFfaf5ff), Color(0xFFf3e8ff)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Color(0xFFe9d5ff), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_transcriptResult != null) ...[
                    // İstatistikler
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFFe9d5ff)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF8B5CF6).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.analytics_rounded,
                              color: Color(0xFF8B5CF6),
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Transkript İstatistikleri',
                                  style: TextStyle(
                                    color: Color(0xFF581c87),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Süre: ${_formatTime(_transcriptResult!.duration)} | Dil: ${_transcriptResult!.language} | Segment: ${_segments.length}',
                                  style: TextStyle(
                                    color: Color(0xFF7c3aed),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                  // Transkript metni
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFFe9d5ff).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      transcriptText,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: Color(0xFF1f2937),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Boş durum kartı
  Widget _buildEmptyStateCard() {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFf1f5f9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFFe2e8f0), width: 1.5),
            ),
            child: Icon(
              Icons.subtitles_rounded,
              size: 64,
              color: Color(0xFF94a3b8),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Henüz transkript yok',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Video seçip işleme başladığınızda\nsonuç burada görünecek',
            style: TextStyle(color: Color(0xFF64748b), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // İşlem butonu
  Widget _buildProcessButton() {
    final bool canProcess = Provider.of<WhisperService>(
      context,
      listen: false,
    ).isInitialized;
    final String buttonText = transcriptText.isEmpty
        ? 'AI Transkript Oluştur'
        : 'Yeniden Oluştur';

    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: canProcess
              ? [Color(0xFF8B5CF6), Color(0xFF7C3AED)]
              : [Color(0xFF94a3b8), Color(0xFF64748b)],
        ),
        boxShadow: [
          BoxShadow(
            color: (canProcess ? Color(0xFF8B5CF6) : Color(0xFF94a3b8))
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: (canProcess ? Color(0xFF7C3AED) : Color(0xFF64748b))
                .withValues(alpha: 0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: canProcess ? () => _processVideo() : null,
        icon: Icon(
          canProcess ? Icons.auto_awesome_rounded : Icons.warning_rounded,
          size: 26,
        ),
        label: Text(
          canProcess ? buttonText : 'Whisper AI Başlatılıyor...',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  void _selectVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedVideoPath = result.files.single.path;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video seçildi: $selectedVideoPath'),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _processVideo() async {
    if (selectedVideoPath == null) return;
    if (!Provider.of<WhisperService>(context, listen: false).isInitialized) {
      _showErrorSnackBar('Whisper servisi henüz başlatılmadı');
      return;
    }

    setState(() {
      isProcessing = true;
      progress = 0.0;
      transcriptText = '';
      _transcriptResult = null;
      _segments = [];
    });

    try {
      // Progress güncelleme timer'ı - daha gerçekçi progress
      Timer.periodic(const Duration(milliseconds: 200), (timer) {
        if (progress < 0.8) {
          setState(() {
            progress += 0.005; // Daha yavaş artış
          });
        }
      });

      // Video dosya boyutunu kontrol et
      final videoFile = File(selectedVideoPath!);
      final fileSize = await videoFile.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Video işleniyor... (${fileSizeMB.toStringAsFixed(1)}MB)',
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Whisper ile transkript oluştur
      final result = await Provider.of<WhisperService>(
        context,
        listen: false,
      ).transcribeVideo(selectedVideoPath!);

      if (result != null) {
        setState(() {
          _transcriptResult = result;
          _segments = result.segments;
          transcriptText = _formatTranscriptWithTimestamps(result);
          progress = 1.0;
          isProcessing = false;
        });

        _showSuccessSnackBar(
          'Transkript başarıyla oluşturuldu! (${result.language.toUpperCase()})',
        );
      } else {
        setState(() {
          isProcessing = false;
        });
        _showErrorSnackBar(
          Provider.of<WhisperService>(context, listen: false).lastError ??
              'Transkript oluşturulamadı',
        );
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
      _showErrorSnackBar('İşlem hatası: $e');
    }
  }

  String _formatTranscriptWithTimestamps(TranscriptResult result) {
    final buffer = StringBuffer();

    for (final segment in result.segments) {
      final startTime = _formatTime(segment.start);
      final endTime = _formatTime(segment.end);

      buffer.writeln('[$startTime - $endTime] ${segment.text}');
    }

    return buffer.toString();
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
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
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _copyTranscript() async {
    if (transcriptText.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: transcriptText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transkript panoya kopyalandı'),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _saveTranscript() async {
    if (transcriptText.isNotEmpty) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/transkript.txt');
        await file.writeAsString(transcriptText);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transkript dosyası kaydedildi: ${file.path}'),
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
              content: Text('Kaydetme hatası: $e'),
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  void _updateDebugInfo() {
    setState(() {
      _debugInfo =
          '''
Whisper Durumu: ${Provider.of<WhisperService>(context, listen: false).isInitialized ? 'Başlatıldı' : 'Başlatılmadı'}
Video Seçili: ${selectedVideoPath != null ? 'Evet' : 'Hayır'}
İşlem Durumu: ${isProcessing ? 'İşleniyor' : 'Bekliyor'}
Progress: ${(progress * 100).toStringAsFixed(1)}%
FFmpeg: Yüklü
Model: Tiny (39MB)
Son Hata: ${Provider.of<WhisperService>(context, listen: false).lastError ?? 'Yok'}
      '''
              .trim();
    });
  }
}
