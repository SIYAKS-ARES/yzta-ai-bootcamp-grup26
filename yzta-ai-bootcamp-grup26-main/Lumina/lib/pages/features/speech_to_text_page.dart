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

class _SpeechToTextPageState extends State<SpeechToTextPage> {
  final TextEditingController _textController = TextEditingController();
  final SpeechToTextService _sttService = SpeechToTextService();

  bool isListening = false;
  bool isLoading = false;
  String recognizedText = '';
  String partialText = '';
  List<FileSystemEntity> savedTextFiles = [];

  @override
  void initState() {
    super.initState();
    _sttService.initialize();
    _loadSavedTextFiles();
  }

  @override
  void dispose() {
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
        title: const Text('Sesten Metne'),
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
                  // Mikrofon kontrolü
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
                          '🎤 Ses Tanıma',
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
                                onPressed: isLoading ? null : _toggleListening,
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
                                    : Icon(
                                        isListening ? Icons.stop : Icons.mic,
                                        size: 24,
                                      ),
                                label: Text(
                                  isLoading
                                      ? 'İşleniyor...'
                                      : (isListening
                                            ? 'Dinlemeyi Durdur'
                                            : 'Dinlemeye Başla'),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isListening
                                      ? Colors.red
                                      : primaryBlue,
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
                        if (isListening) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.record_voice_over,
                                  color: Colors.red[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dinleniyor... Konuşmaya başlayın',
                                    style: TextStyle(
                                      color: Colors.red[700],
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

                  // Tanınan metin alanı
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
                          '📝 Tanınan Metin',
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
                            hintText: 'Tanınan metin burada görünecek...',
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
                        if (partialText.isNotEmpty && !isListening) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Text(
                              'Kısmi sonuç: $partialText',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Kontrol butonları
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _textController.text.isEmpty || isLoading
                              ? null
                              : _clearText,
                          icon: const Icon(Icons.clear),
                          label: const Text('Temizle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
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
                          onPressed: _textController.text.isEmpty || isLoading
                              ? null
                              : _saveText,
                          icon: const Icon(Icons.save),
                          label: const Text('Metni Kaydet'),
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
                      onPressed: _debugSTT,
                      icon: const Icon(Icons.bug_report),
                      label: const Text('STT Debug'),
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

                  // Kaydedilen Metin Dosyaları
                  if (savedTextFiles.isNotEmpty) ...[
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
                            '📁 Kaydedilen Metin Dosyaları',
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...savedTextFiles.map(
                            (file) => _buildTextFileItem(file),
                          ),
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
                          '💡 Kullanım İpuçları',
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
                            _buildTipChip('Net ve yavaş konuşun'),
                            _buildTipChip('Gürültülü ortamlardan kaçının'),
                            _buildTipChip('Mikrofonu ağzınıza yakın tutun'),
                            _buildTipChip('Cümle sonlarında duraklayın'),
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
            const SnackBar(
              content: Text('Dinleme durduruldu'),
              backgroundColor: Colors.orange,
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
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
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
      developer.log("Metin dosyaları yükleme hatası: $e", name: 'SpeechToTextPage');
    }
  }

  // Debug fonksiyonu
  Future<void> _debugSTT() async {
    try {
      await _sttService.debugSTT();
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

  Widget _buildTipChip(String tip) {
    return Chip(
      label: Text(tip),
      backgroundColor: const Color(0xFFE0E7FF),
      labelStyle: const TextStyle(color: Color(0xFF2563EB)),
    );
  }
}
