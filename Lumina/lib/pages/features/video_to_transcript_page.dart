import 'package:flutter/material.dart';
import 'dart:async'; // Added for Timer
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
  }

  @override
  void dispose() {
    _animationController.dispose();
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
              child: Icon(
                Icons.video_library_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Video Transkript',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Video İçeriğini Metne Dönüştür',
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Hoş geldiniz kartı
                    _buildWelcomeCard(),
                    const SizedBox(height: 20),

                    // Video seçimi
                    _buildVideoSelectionCard(),
                    const SizedBox(height: 20),

                    // İşlem durumu
                    if (isProcessing) ...[
                      _buildProcessingCard(),
                      const SizedBox(height: 20),
                    ],

                    // Transkript sonucu
                    if (transcriptText.isNotEmpty) ...[
                      _buildTranscriptCard(),
                    ] else if (!isProcessing) ...[
                      // Boş durum
                      _buildEmptyStateCard(),
                    ],

                    // İşlem butonu
                    if (selectedVideoPath != null &&
                        !isProcessing &&
                        transcriptText.isEmpty) ...[
                      const SizedBox(height: 20),
                      _buildProcessButton(),
                    ],
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
                  Icons.video_library_rounded,
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
                      'Video Transkript Dönüştürücü',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Color(0xFF1f2937),
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Video içeriğinizi metne dönüştürün',
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
                    'Video dosyanızı seçin ve otomatik transkript oluşturun. İşitme engelli kullanıcılar için idealdir.',
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

  // Video seçimi kartı
  Widget _buildVideoSelectionCard() {
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
                  Icons.video_library_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Video Seçin',
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFf8fafc), Color(0xFFf1f5f9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFFe2e8f0), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF64748b).withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: Color(0xFF94a3b8).withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selectedVideoPath != null
                        ? Color(0xFFdcfce7)
                        : Color(0xFFf1f5f9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selectedVideoPath != null
                          ? Color(0xFFbbf7d0)
                          : Color(0xFFe2e8f0),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    selectedVideoPath != null
                        ? Icons.video_file_rounded
                        : Icons.video_library_rounded,
                    size: 48,
                    color: selectedVideoPath != null
                        ? Color(0xFF16a34a)
                        : Color(0xFF64748b),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  selectedVideoPath != null
                      ? 'Video seçildi'
                      : 'Video dosyası seçmek için tıklayın',
                  style: TextStyle(
                    color: selectedVideoPath != null
                        ? Color(0xFF16a34a)
                        : Color(0xFF475569),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (selectedVideoPath != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    selectedVideoPath!,
                    style: TextStyle(color: Color(0xFF64748b), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: selectedVideoPath != null
                          ? [Color(0xFF16a34a), Color(0xFF15803d)]
                          : [Color(0xFF2563EB), Color(0xFF1d4ed8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (selectedVideoPath != null
                                    ? Color(0xFF16a34a)
                                    : Color(0xFF2563EB))
                                .withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                      BoxShadow(
                        color:
                            (selectedVideoPath != null
                                    ? Color(0xFF15803d)
                                    : Color(0xFF1d4ed8))
                                .withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _selectVideo(),
                    icon: Icon(
                      selectedVideoPath != null
                          ? Icons.change_circle_rounded
                          : Icons.add_rounded,
                      size: 20,
                    ),
                    label: Text(
                      selectedVideoPath != null ? 'Değiştir' : 'Video Seç',
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
                        borderRadius: BorderRadius.circular(16),
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
                  Icons.sync_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'İşleniyor...',
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
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFf0f9ff), Color(0xFFe0f2fe)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFbfdbfe), width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.sync_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Color(0xFFe2e8f0),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  minHeight: 8,
                ),
                const SizedBox(height: 12),
                Text(
                  '${(progress * 100).toInt()}% tamamlandı',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    'Transkript',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF1f2937),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366f1), Color(0xFF4f46e5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6366f1).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => _copyTranscript(),
                      icon: Icon(
                        Icons.copy_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Color(0xFF16a34a), Color(0xFF15803d)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF16a34a).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => _saveTranscript(),
                      icon: Icon(
                        Icons.save_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
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
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFf8fafc), Color(0xFFf1f5f9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFe2e8f0), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF64748b).withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: Color(0xFF94a3b8).withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Text(
                transcriptText,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF1f2937),
                  fontWeight: FontWeight.w500,
                ),
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
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF1d4ed8)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withValues(alpha: 0.25),
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
        onPressed: () => _processVideo(),
        icon: Icon(Icons.play_arrow_rounded, size: 24),
        label: Text(
          'Transkript Oluştur',
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

  void _processVideo() {
    if (selectedVideoPath == null) return;

    setState(() {
      isProcessing = true;
      progress = 0.0;
    });

    // Simüle edilmiş işlem
    _simulateProcessing();
  }

  void _simulateProcessing() {
    const totalSteps = 100;
    int currentStep = 0;

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      currentStep++;
      setState(() {
        progress = currentStep / totalSteps;
      });

      if (currentStep >= totalSteps) {
        timer.cancel();
        setState(() {
          isProcessing = false;
          transcriptText = '''
Merhaba, bu bir örnek video transkriptidir. Video to transcript özelliği çalışıyor!

Bu özellik sayesinde video dosyalarınızı metne çevirebilirsiniz. Bu özellikle işitme engelli kullanıcılar için çok faydalıdır.

Video içeriğindeki konuşmalar otomatik olarak metne dönüştürülür ve altyazı olarak kullanılabilir.

Lumina uygulaması ile erişilebilirlik artık daha kolay!
          ''';
        });
      }
    });
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
}
