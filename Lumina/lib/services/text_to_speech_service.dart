import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'file_manager_service.dart';

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FileManagerService _fileManager = FileManagerService();

  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _currentAudioPath;

  // TTS ayarları
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Event listener'ları ayarla
      _flutterTts.setStartHandler(() {
        print("TTS başladı");
        _isPlaying = true;
      });

      _flutterTts.setCompletionHandler(() {
        print("TTS tamamlandı");
        _isPlaying = false;
      });

      _flutterTts.setErrorHandler((msg) {
        print("TTS Error: $msg");
        _isPlaying = false;
      });

      // Türkçe dil ayarları
      await _flutterTts.setLanguage("tr-TR");
      await _flutterTts.setSpeechRate(0.5); // Konuşma hızı (0.1 - 1.0)
      await _flutterTts.setVolume(1.0); // Ses seviyesi (0.0 - 1.0)
      await _flutterTts.setPitch(1.0); // Ses tonu (0.5 - 2.0)

      // Platform ayarları - daha güvenli yaklaşım
      try {
        if (Platform.isAndroid) {
          await _flutterTts.setEngine("com.google.android.tts");
        } else if (Platform.isIOS) {
          await _flutterTts.setEngine("com.apple.ttsbundle.siri_female_tr-TR");
        }
      } catch (e) {
        print("Engine ayarlama hatası (göz ardı edildi): $e");
      }

      _isInitialized = true;
      print("TTS başarıyla başlatıldı");
    } catch (e) {
      print("TTS initialization error: $e");
    }
  }

  // PDF dosyasından metin çıkarma
  Future<String> extractTextFromPdf(String filePath) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Dosya bulunamadı: $filePath');
      }

      final Uint8List bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String text = extractor.extractText();
      document.dispose();

      return text.trim();
    } catch (e) {
      print("PDF metin çıkarma hatası: $e");
      throw Exception('PDF dosyasından metin çıkarılamadı: $e');
    }
  }

  // TXT dosyasından metin okuma
  Future<String> readTextFile(String filePath) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Dosya bulunamadı: $filePath');
      }

      final String content = await file.readAsString();
      return content.trim();
    } catch (e) {
      print("TXT dosya okuma hatası: $e");
      throw Exception('TXT dosyası okunamadı: $e');
    }
  }

  // Dosyayı uygulama dizinine kopyala ve metin çıkar
  Future<String> processUploadedFile(String sourcePath, String fileName) async {
    try {
      // Web platformu kontrolü
      if (sourcePath.startsWith('blob:') || sourcePath.contains('_Namespace')) {
        // Web platformunda doğrudan dosyadan metin çıkar
        print("Web platformu tespit edildi, doğrudan dosya işleme");
        final String text = await extractTextFromFile(sourcePath);
        print("Dosya işlendi (web): $fileName, Metin uzunluğu: ${text.length}");
        return text;
      } else {
        // Mobil platformlarda dosyayı kopyala
        final String localPath = await _fileManager.copyFileToAppDirectory(
          sourcePath,
          fileName,
        );
        final String text = await extractTextFromFile(localPath);
        print(
          "Dosya işlendi (mobil): $localPath, Metin uzunluğu: ${text.length}",
        );
        return text;
      }
    } catch (e) {
      print("Dosya işleme hatası: $e");
      throw Exception('Dosya işlenemedi: $e');
    }
  }

  // Dosya türüne göre metin çıkarma
  Future<String> extractTextFromFile(String filePath) async {
    final String extension = path.extension(filePath).toLowerCase();

    switch (extension) {
      case '.pdf':
        return await extractTextFromPdf(filePath);
      case '.txt':
        return await readTextFile(filePath);
      default:
        throw Exception('Desteklenmeyen dosya türü: $extension');
    }
  }

  // Metni sese dönüştürme ve oynatma
  Future<void> speakText(String text) async {
    if (!_isInitialized) await initialize();

    try {
      if (_isPlaying) {
        await stopSpeaking();
      }

      print(
        "Metin okunuyor: ${text.substring(0, text.length > 50 ? 50 : text.length)}...",
      );
      await _flutterTts.speak(text);
    } catch (e) {
      print("Metin okuma hatası: $e");
      throw Exception('Metin okunamadı: $e');
    }
  }

  // Metni ses dosyası olarak kaydetme
  Future<String> saveTextAsAudio(String text, String fileName) async {
    if (!_isInitialized) await initialize();

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String audioDir = path.join(appDir.path, 'audio');

      // Audio klasörünü oluştur
      await Directory(audioDir).create(recursive: true);

      final String audioPath = path.join(audioDir, '$fileName.wav');

      // TTS ile ses dosyası oluştur
      await _flutterTts.synthesizeToFile(text, audioPath);

      return audioPath;
    } catch (e) {
      print("Ses dosyası kaydetme hatası: $e");
      throw Exception('Ses dosyası kaydedilemedi: $e');
    }
  }

  // Ses dosyasını oynatma
  Future<void> playAudioFile(String audioPath) async {
    try {
      if (_isPlaying) {
        await stopSpeaking();
      }

      _currentAudioPath = audioPath;
      await _audioPlayer.play(DeviceFileSource(audioPath));
      _isPlaying = true;
    } catch (e) {
      print("Ses dosyası oynatma hatası: $e");
      throw Exception('Ses dosyası oynatılamadı: $e');
    }
  }

  // Konuşmayı durdurma
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentAudioPath = null;
    } catch (e) {
      print("Durdurma hatası: $e");
    }
  }

  // Konuşma durumunu kontrol etme
  bool get isPlaying => _isPlaying;

  // Mevcut ses dosyası yolunu alma
  String? get currentAudioPath => _currentAudioPath;

  // Desteklenen dilleri alma
  Future<List<Map<String, String>>> getSupportedLanguages() async {
    try {
      final List<dynamic> languages = await _flutterTts.getLanguages;
      return languages
          .map<Map<String, String>>(
            (lang) => {
              'code': (lang['code'] ?? '').toString(),
              'name': (lang['name'] ?? '').toString(),
            },
          )
          .toList();
    } catch (e) {
      print("Dil listesi alma hatası: $e");
      return [];
    }
  }

  // Dil değiştirme
  Future<void> setLanguage(String languageCode) async {
    try {
      await _flutterTts.setLanguage(languageCode);
    } catch (e) {
      print("Dil değiştirme hatası: $e");
    }
  }

  // Konuşma hızını ayarlama
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      print("Konuşma hızı ayarlama hatası: $e");
    }
  }

  // Ses seviyesini ayarlama
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
    } catch (e) {
      print("Ses seviyesi ayarlama hatası: $e");
    }
  }

  // Debug fonksiyonu
  Future<void> debugTTS() async {
    print("=== TTS Debug Bilgileri ===");
    print("Başlatıldı: $_isInitialized");
    print("Oynatılıyor: $_isPlaying");
    print("Mevcut ses dosyası: $_currentAudioPath");

    try {
      final List<dynamic> languages = await _flutterTts.getLanguages;
      print("Desteklenen diller: ${languages.length}");

      final List<dynamic> engines = await _flutterTts.getEngines;
      print("Mevcut engine'ler: ${engines.length}");

      // Test metni oku
      print("Test metni okunuyor...");
      await _flutterTts.speak("Test");
    } catch (e) {
      print("Debug hatası: $e");
    }
  }

  // Servisi temizleme
  void dispose() {
    _flutterTts.stop();
    _audioPlayer.dispose();
  }
}
