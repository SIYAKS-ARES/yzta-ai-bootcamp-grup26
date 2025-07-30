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

class _VideoToTranscriptPageState extends State<VideoToTranscriptPage> {
  String? selectedVideoPath;
  bool isProcessing = false;
  String transcriptText = '';
  double progress = 0.0;

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2563EB);
    final Color softBlue = const Color(0xFF60A5FA);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Transkript'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue, softBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Video seçimi
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎬 Video Seçin',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            selectedVideoPath != null
                                ? Icons.video_file
                                : Icons.video_library,
                            size: 48,
                            color: selectedVideoPath != null
                                ? Colors.green
                                : Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            selectedVideoPath != null
                                ? 'Video seçildi'
                                : 'Video dosyası seçmek için tıklayın',
                            style: TextStyle(
                              color: selectedVideoPath != null
                                  ? Colors.green
                                  : Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (selectedVideoPath != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              selectedVideoPath!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _selectVideo(),
                            icon: Icon(
                              selectedVideoPath != null
                                  ? Icons.change_circle
                                  : Icons.add,
                            ),
                            label: Text(
                              selectedVideoPath != null
                                  ? 'Değiştir'
                                  : 'Video Seç',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // İşlem durumu
              if (isProcessing) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      Text(
                        '🔄 İşleniyor...',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(progress * 100).toInt()}% tamamlandı',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Transkript sonucu
              if (transcriptText.isNotEmpty) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '📝 Transkript',
                              style: TextStyle(
                                color: primaryBlue,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _copyTranscript(),
                                  icon: Icon(Icons.copy, color: primaryBlue),
                                ),
                                IconButton(
                                  onPressed: () => _saveTranscript(),
                                  icon: Icon(Icons.save, color: primaryBlue),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                transcriptText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (!isProcessing) ...[
                // Boş durum
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.subtitles,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz transkript yok',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Video seçip işleme başladığınızda\nsonuç burada görünecek',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // İşlem butonu
              if (selectedVideoPath != null &&
                  !isProcessing &&
                  transcriptText.isEmpty) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _processVideo(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Transkript Oluştur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kaydetme hatası: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
