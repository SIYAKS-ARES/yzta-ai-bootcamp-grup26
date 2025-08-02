import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../../services/text_to_speech_service.dart';
import '../../services/file_manager_service.dart';
import '../../services/web_file_service.dart';

class TextToSpeechPage extends StatefulWidget {
  const TextToSpeechPage({super.key});

  @override
  State<TextToSpeechPage> createState() => _TextToSpeechPageState();
}

class _TextToSpeechPageState extends State<TextToSpeechPage> {
  final TextEditingController _textController = TextEditingController();
  final TextToSpeechService _ttsService = TextToSpeechService();
  final FileManagerService _fileManager = FileManagerService();
  final WebFileService _webFileService = WebFileService();

  bool isPlaying = false;
  bool isLoading = false;
  String? selectedFileName;
  String extractedText = '';
  List<FileSystemEntity> uploadedFiles = [];

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    _loadUploadedFiles();
  }

  @override
  void dispose() {
    _textController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2563EB);
    final Color softBlue = const Color(0xFF60A5FA);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metinden Sese'),
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
                  // Dosya seçme butonu
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
                          '📁 Dosya Seç',
                          style: TextStyle(
                            color: primaryBlue,
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                primaryBlue,
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.upload_file),
                                label: Text(
                                  isLoading
                                      ? 'İşleniyor...'
                                      : 'PDF/TXT Dosyası Seç',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
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
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green[600],
                                  size: 20,
                                ),
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
                  ),
                  const SizedBox(height: 20),

                  // Metin girişi alanı
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
                          '🔊 Metin',
                          style: TextStyle(
                            color: primaryBlue,
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
                              borderSide: BorderSide(
                                color: primaryBlue,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Kontrol butonları
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _textController.text.trim().isEmpty || isLoading
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
                              : Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                          label: Text(
                            isLoading
                                ? 'İşleniyor...'
                                : (isPlaying ? 'Durdur' : 'Oynat'),
                          ),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _textController.text.trim().isEmpty || isLoading
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
                              : const Icon(Icons.save),
                          label: Text(
                            isLoading ? 'Kaydediliyor...' : 'Ses Olarak Kaydet',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
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
                  const SizedBox(height: 12),

                  // Debug butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _debugTTS,
                      icon: const Icon(Icons.bug_report),
                      label: const Text('TTS Debug'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Yüklenen Dosyalar
                  if (uploadedFiles.isNotEmpty) ...[
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
                            '📁 Yüklenen Dosyalar',
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...uploadedFiles.map((file) => _buildFileItem(file)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Hızlı örnekler
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
                          '📝 Hızlı Örnekler',
                          style: TextStyle(
                            color: primaryBlue,
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
                            _buildExampleChip(
                              'Yapay zeka geleceğimizi şekillendiriyor.',
                            ),
                            _buildExampleChip(
                              'Erişilebilirlik herkes için önemli.',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
        withData: true, // Web için dosya verilerini al
      );

      if (result != null) {
        final file = result.files.single;
        String fileName = file.name;

        // Seçilen dosya bilgileri

        setState(() {
          selectedFileName = fileName;
        });

        String text = '';

        // Web platformu için farklı işleme
        if (file.path != null) {
          // Mobil platform
          text = await _ttsService.processUploadedFile(file.path!, fileName);
        } else if (file.bytes != null) {
          // Web platformu - dosya verilerini doğrudan işle
          // Web platformu tespit edildi, dosya verilerini işleme
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
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dosyadan metin çıkarılamadı'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      // Dosya seçme hatası
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
        await _ttsService.speakText(text);

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
            backgroundColor: Colors.green,
          ),
        );
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

  // Yüklenen dosyaları yükle
  Future<void> _loadUploadedFiles() async {
    try {
      final files = await _fileManager.getUploadedFiles();
      setState(() {
        uploadedFiles = files;
      });
      // Yüklenen dosyalar
    } catch (e) {
      // Dosya listesi yükleme hatası
    }
  }

  // Debug fonksiyonu
  Future<void> _debugTTS() async {
    try {
      await _ttsService.debugTTS();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debug bilgileri konsola yazdırıldı'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFileItem(FileSystemEntity file) {
    final String fileName = path.basename(file.path);
    final String extension = path.extension(fileName).toLowerCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          extension == '.pdf' ? Icons.picture_as_pdf : Icons.text_snippet,
          color: extension == '.pdf' ? Colors.red : Colors.blue,
        ),
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${(file.statSync().size / 1024).toStringAsFixed(1)} KB',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _loadFileContent(file.path),
              tooltip: 'Yükle ve Oynat',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteFile(file.path),
              tooltip: 'Sil',
            ),
          ],
        ),
      ),
    );
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

  // Dosyayı sil
  Future<void> _deleteFile(String filePath) async {
    try {
      await _fileManager.deleteFile(filePath);
      await _loadUploadedFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${path.basename(filePath)} silindi'),
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

  Widget _buildExampleChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _textController.text = text;
        // Otomatik olarak oynat
        Future.delayed(const Duration(milliseconds: 100), () {
          _togglePlayback();
        });
      },
      backgroundColor: const Color(0xFFE0E7FF),
      labelStyle: const TextStyle(color: Color(0xFF2563EB)),
    );
  }
}
