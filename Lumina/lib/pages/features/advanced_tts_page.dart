import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../services/hybrid_tts_service.dart';
import '../../services/firebase_tts_service.dart';
import '../../services/web_file_service.dart';

class AdvancedTTSPage extends StatefulWidget {
  const AdvancedTTSPage({super.key});

  @override
  State<AdvancedTTSPage> createState() => _AdvancedTTSPageState();
}

class _AdvancedTTSPageState extends State<AdvancedTTSPage> {
  final TextEditingController _textController = TextEditingController();
  final HybridTTSService _ttsService = HybridTTSService();
  final WebFileService _webFileService = WebFileService();

  bool isPlaying = false;
  bool isProcessing = false;
  bool isLoading = false;
  String? selectedFileName;
  String extractedText = '';
  String? currentTaskId;
  double uploadProgress = 0.0;
  Task? currentTask;

  // TTS ayarları
  TTSMode selectedMode = TTSMode.device;
  TTSQuality selectedQuality = TTSQuality.fast;
  double speechRate = 0.42; // İyileştirilmiş varsayılan
  double volume = 1.0;
  double pitch = 0.88; // İyileştirilmiş varsayılan

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _setupStreamListeners();
  }

  void _setupStreamListeners() {
    // TTS durumunu dinle
    _ttsService.isPlayingStream.listen((playing) {
      if (mounted) {
        setState(() {
          isPlaying = playing;
        });
      }
    });

    // İşlem durumunu dinle
    _ttsService.isProcessingStream.listen((processing) {
      if (mounted) {
        setState(() {
          isProcessing = processing;
        });
      }
    });

    // Upload progress'i dinle
    _ttsService.uploadProgressStream.listen((progress) {
      if (mounted) {
        setState(() {
          uploadProgress = progress;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _initializeTTS() async {
    try {
      await _ttsService.initialize();
      await _ttsService.updateAudioSettings(
        speechRate: speechRate,
        volume: volume,
        pitch: pitch,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS başlatma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2563EB);
    final Color softBlue = const Color(0xFF60A5FA);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelişmiş Metinden Sese'),
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
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TTS Mod Seçimi
                  _buildModeSelectionCard(),
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

                  // İşlem durumu
                  if (isProcessing || currentTask != null) ...[
                    _buildProcessingStatusCard(),
                    const SizedBox(height: 20),
                  ],

                  // Ses ayarları
                  _buildAudioSettingsCard(),
                  const SizedBox(height: 20),

                  // Hızlı örnekler
                  _buildQuickExamplesCard(),
                  const SizedBox(height: 20),

                  // Geçmiş işlemler
                  _buildHistoryCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔧 TTS Modu',
            style: TextStyle(
              color: const Color(0xFF2563EB),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModeOption(
                  TTSMode.device,
                  'Cihaz',
                  'Hızlı, düşük kalite',
                  Icons.phone_android,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeOption(
                  TTSMode.cloud,
                  'Bulut',
                  'Yavaş, yüksek kalite',
                  Icons.cloud,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    TTSMode mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMode = mode;
          _ttsService.setMode(mode);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📁 Dosya Seç',
            style: TextStyle(
              color: const Color(0xFF2563EB),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _pickFile,
                  icon: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF2563EB),
                            ),
                          ),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(
                    isLoading ? 'İşleniyor...' : 'PDF/DOCX/TXT Dosyası Seç',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (selectedFileName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seçilen dosya: $selectedFileName',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
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

  Widget _buildTextInputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔊 Metin',
            style: TextStyle(
              color: const Color(0xFF2563EB),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText:
                  'Sese dönüştürmek istediğiniz metni buraya yazın veya dosya seçin...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _textController.text.trim().isEmpty || isLoading
                ? null
                : _togglePlayback,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(isPlaying ? Icons.stop : Icons.play_arrow),
            label: Text(
              isLoading ? 'İşleniyor...' : (isPlaying ? 'Durdur' : 'Oynat'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _textController.text.trim().isEmpty || isLoading
                ? null
                : _pauseResume,
            icon: const Icon(Icons.pause),
            label: const Text('Duraklat/Devam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚙️ İşlem Durumu',
            style: TextStyle(
              color: const Color(0xFF2563EB),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (isProcessing) ...[
            Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dosya işleniyor...'),
                      if (uploadProgress > 0) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: uploadProgress),
                        Text('${(uploadProgress * 100).toStringAsFixed(0)}%'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ] else if (currentTask != null) ...[
            _buildTaskStatusWidget(currentTask!),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskStatusWidget(Task task) {
    switch (task.status) {
      case 'pending':
        return Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dosya: ${task.fileName}'),
                  const Text('İşlem sırasında bekliyor...'),
                ],
              ),
            ),
          ],
        );

      case 'processing':
        return Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dosya: ${task.fileName}'),
                  const Text('Sese dönüştürülüyor...'),
                ],
              ),
            ),
          ],
        );

      case 'completed':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tamamlandı: ${task.fileName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (task.processedTextLength != null) ...[
              const SizedBox(height: 8),
              Text('İşlenen metin: ${task.processedTextLength} karakter'),
            ],
            if (task.audioUrl != null) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _playTaskAudio(task.audioUrl!),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Sesi Oynat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        );

      case 'failed':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hata: ${task.fileName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.errorMessage ?? 'Bilinmeyen bir hata oluştu.',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        );

      default:
        return Text('Bilinmeyen durum: ${task.status}');
    }
  }

  Widget _buildAudioSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎵 Ses Ayarları',
            style: TextStyle(
              color: const Color(0xFF2563EB),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Konuşma hızı
          Text('Konuşma Hızı: ${speechRate.toStringAsFixed(1)}'),
          Slider(
            value: speechRate,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            onChanged: (value) {
              setState(() {
                speechRate = value;
              });
              _ttsService.updateAudioSettings(speechRate: value);
            },
          ),

          const SizedBox(height: 16),

          // Ses seviyesi
          Text('Ses Seviyesi: ${(volume * 100).toStringAsFixed(0)}%'),
          Slider(
            value: volume,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (value) {
              setState(() {
                volume = value;
              });
              _ttsService.updateAudioSettings(volume: value);
            },
          ),

          const SizedBox(height: 16),

          // Ses testi butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _testAudioSettings,
              icon: const Icon(Icons.volume_up),
              label: const Text('Ses Testi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Türkçe optimizasyon butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _optimizeTurkishVoice,
              icon: const Icon(Icons.language),
              label: const Text('Türkçe Ses Optimizasyonu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
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
    );
  }

  Widget _buildQuickExamplesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📝 Hızlı Örnekler',
            style: TextStyle(
              color: const Color(0xFF2563EB),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
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
      label: Text(text),
      onPressed: () {
        _textController.text = text;
        Future.delayed(const Duration(milliseconds: 100), () {
          _togglePlayback();
        });
      },
      backgroundColor: const Color(0xFFE0E7FF),
      labelStyle: const TextStyle(color: Color(0xFF2563EB)),
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
        allowedExtensions: ['pdf', 'docx', 'txt'],
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
          // Mobil platform
          final fileObj = File(file.path!);
          await _ttsService.processFile(fileObj, userId: _getCurrentUserId());
        } else if (file.bytes != null) {
          // Web platformu
          text = await _webFileService.processFile(file.bytes!, fileName);
          if (text.isNotEmpty) {
            setState(() {
              extractedText = text;
              _textController.text = text;
            });
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$fileName dosyası yüklendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
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
          const SnackBar(
            content: Text('Lütfen okunacak metin girin'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      if (isPlaying) {
        await _ttsService.stopSpeaking();
        setState(() {
          isPlaying = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ses durduruldu'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        setState(() {
          isPlaying = true;
        });

        final userId = _getCurrentUserId();
        await _ttsService.speakText(text, userId: userId);

        // Kısa bir süre sonra durumu kontrol et
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              isPlaying = _ttsService.isPlaying;
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
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Duraklat/Devam fonksiyonu
  Future<void> _pauseResume() async {
    try {
      if (isPlaying) {
        await _ttsService.pauseSpeaking();
        setState(() {
          isPlaying = false;
        });
      } else {
        await _ttsService.resumeSpeaking();
        setState(() {
          isPlaying = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Task ses dosyasını oynat
  Future<void> _playTaskAudio(String audioUrl) async {
    try {
      await _ttsService.playAudio(audioUrl);
      setState(() {
        isPlaying = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ses oynatma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Ses testi
  Future<void> _testAudioSettings() async {
    try {
      await _ttsService.speakText(
        'Bu bir ses testidir. Ayarlarınızı kontrol edin.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ses testi hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Türkçe ses optimizasyonu
  Future<void> _optimizeTurkishVoice() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Device TTS servisini al ve optimize et
      await _ttsService.initialize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Türkçe ses optimizasyonu tamamlandı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Optimizasyon hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Geçmiş işlemler kartı
  Widget _buildHistoryCard() {
    final userId = _getCurrentUserId();
    if (userId == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 Geçmiş İşlemler',
            style: TextStyle(
              color: const Color(0xFF2563EB),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Task>>(
            stream: _ttsService.getUserTasks(userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Hata: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final tasks = snapshot.data!;
              if (tasks.isEmpty) {
                return const Text(
                  'Henüz işlem yapılmamış',
                  style: TextStyle(color: Colors.grey),
                );
              }

              return Column(
                children: tasks
                    .take(5)
                    .map((task) => _buildTaskItem(task))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getTaskIcon(task.status),
          color: _getTaskColor(task.status),
        ),
        title: Text(
          task.fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('${task.status} • ${_formatDate(task.createdAt)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.status == 'completed' && task.audioUrl != null)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => _playTaskAudio(task.audioUrl!),
                tooltip: 'Oynat',
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteTask(task.id),
              tooltip: 'Sil',
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTaskIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.sync;
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _getTaskColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _ttsService.deleteTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşlem silindi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Mevcut kullanıcı ID'sini al
  String? _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }
}
