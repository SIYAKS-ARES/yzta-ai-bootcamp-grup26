import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'file_manager_service.dart';
import 'dart:developer' as developer;

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
        developer.log("TTS başladı", name: 'TextToSpeechService');
        _isPlaying = true;
      });

      _flutterTts.setCompletionHandler(() {
        developer.log("TTS tamamlandı", name: 'TextToSpeechService');
        _isPlaying = false;
      });

      _flutterTts.setErrorHandler((msg) {
        developer.log("TTS Error: $msg", name: 'TextToSpeechService');
        _isPlaying = false;
      });

      // Türkçe dil ayarları - iyileştirilmiş
      await _flutterTts.setLanguage("tr-TR");
      await _flutterTts.setSpeechRate(0.42); // Biraz daha hızlı (optimal)
      await _flutterTts.setVolume(1.0); // Ses seviyesi (0.0 - 1.0)
      await _flutterTts.setPitch(0.88); // Biraz daha yüksek ton (daha doğal)

      // Platform ayarları - iyileştirilmiş
      try {
        if (Platform.isAndroid) {
          // Android için en iyi Türkçe ses motoru
          await _flutterTts.setEngine("com.google.android.tts");
          // Türkçe ses seçimi - daha fazla alternatif
          final List<Map<String, String>> turkishVoices = [
            {"name": "tr-tr-x-ism-local", "locale": "tr-TR"},
            {"name": "tr-TR", "locale": "tr-TR"},
            {"name": "tr-tr-x-ism", "locale": "tr-TR"},
            {"name": "tr-tr-x-ism-local", "locale": "tr-TR"},
          ];

          bool voiceSet = false;
          for (final voice in turkishVoices) {
            try {
              await _flutterTts.setVoice(voice);
              voiceSet = true;
              developer.log(
                "Türkçe ses ayarlandı: ${voice['name']}",
                name: 'TextToSpeechService',
              );
              break;
            } catch (e) {
              continue;
            }
          }

          if (!voiceSet) {
            developer.log(
              "Türkçe ses ayarlanamadı, varsayılan kullanılıyor",
              name: 'TextToSpeechService',
            );
          }
        } else if (Platform.isIOS) {
          // iOS için en iyi Türkçe ses
          await _flutterTts.setEngine("com.apple.ttsbundle.siri_female_tr-TR");
        }
      } catch (e) {
        developer.log(
          "Engine ayarlama hatası (göz ardı edildi): $e",
          name: 'TextToSpeechService',
        );
      }

      // Türkçe ses optimizasyonu
      await optimizeForTurkish();

      _isInitialized = true;
      developer.log("TTS başarıyla başlatıldı", name: 'TextToSpeechService');
    } catch (e) {
      developer.log(
        "TTS initialization error: $e",
        name: 'TextToSpeechService',
      );
    }
  }

  // PDF dosyasından metin çıkarma - geliştirilmiş
  Future<String> extractTextFromPdf(String filePath) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Dosya bulunamadı: $filePath');
      }

      final Uint8List bytes = await file.readAsBytes();

      // PDF boyut kontrolü
      if (bytes.length > 50 * 1024 * 1024) {
        throw Exception('PDF dosyası çok büyük (maksimum 50MB)');
      }

      // PDF başlık kontrolü - daha esnek
      final header = String.fromCharCodes(bytes.take(8));
      if (!header.contains('PDF')) {
        throw Exception('Geçersiz PDF dosyası');
      }

      String text = '';

      // İlk yöntem: Standart çıkarma
      try {
        final PdfDocument document = PdfDocument(inputBytes: bytes);

        if (document.pages.count == 0) {
          document.dispose();
          throw Exception('PDF dosyası boş');
        }

        final PdfTextExtractor extractor = PdfTextExtractor(document);
        text = extractor.extractText();
        document.dispose();

        if (text.trim().isNotEmpty) {
          return text.trim();
        }
      } catch (e) {
        developer.log(
          "Standart PDF çıkarma başarısız: $e",
          name: 'TextToSpeechService',
        );
      }

      // İkinci yöntem: Sayfa sayfa çıkarma
      try {
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        text = '';

        for (int i = 0; i < document.pages.count; i++) {
          try {
            final String pageText = PdfTextExtractor(
              document,
            ).extractText(startPageIndex: i, endPageIndex: i);
            if (pageText.isNotEmpty) {
              text += '$pageText\n';
            }
          } catch (pageError) {
            developer.log(
              "Sayfa $i çıkarılamadı: $pageError",
              name: 'TextToSpeechService',
            );
            continue;
          }
        }

        document.dispose();

        if (text.trim().isNotEmpty) {
          return text.trim();
        }
      } catch (e) {
        developer.log(
          "Sayfa sayfa çıkarma başarısız: $e",
          name: 'TextToSpeechService',
        );
      }

      // Hiçbir yöntem başarılı olmadı
      throw Exception(
        'PDF dosyasından metin çıkarılamadı. Dosya korumalı, bozuk veya görsel PDF olabilir.',
      );
    } catch (e) {
      developer.log(
        "PDF metin çıkarma hatası: $e",
        name: 'TextToSpeechService',
      );

      // Daha kullanıcı dostu hata mesajları
      if (e.toString().contains('Invalid cross reference table') ||
          e.toString().contains('corrupted')) {
        throw Exception(
          'PDF dosyası bozuk. Lütfen farklı bir PDF dosyası deneyin.',
        );
      } else if (e.toString().contains('password') ||
          e.toString().contains('encrypted')) {
        throw Exception('PDF dosyası şifre korumalı. Lütfen şifreyi kaldırın.');
      } else if (e.toString().contains('protected')) {
        throw Exception(
          'PDF dosyası korumalı. Lütfen farklı bir PDF dosyası deneyin.',
        );
      } else {
        throw Exception(
          'PDF dosyası işlenemedi. Lütfen farklı bir dosya deneyin.',
        );
      }
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
      developer.log("TXT dosya okuma hatası: $e", name: 'TextToSpeechService');
      throw Exception('TXT dosyası okunamadı: $e');
    }
  }

  // Dosyayı uygulama dizinine kopyala ve metin çıkar
  Future<String> processUploadedFile(String sourcePath, String fileName) async {
    try {
      // Web platformu kontrolü
      if (sourcePath.startsWith('blob:') || sourcePath.contains('_Namespace')) {
        // Web platformunda doğrudan dosyadan metin çıkar
        developer.log(
          "Web platformu tespit edildi, doğrudan dosya işleme",
          name: 'TextToSpeechService',
        );
        final String text = await extractTextFromFile(sourcePath);
        developer.log(
          "Dosya işlendi (web): $fileName, Metin uzunluğu: [${text.length}",
          name: 'TextToSpeechService',
        );
        return text;
      } else {
        // Mobil platformlarda dosyayı kopyala
        final String localPath = await _fileManager.copyFileToAppDirectory(
          sourcePath,
          fileName,
        );
        final String text = await extractTextFromFile(localPath);
        developer.log(
          "Dosya işlendi (mobil): $localPath, Metin uzunluğu: [${text.length}",
          name: 'TextToSpeechService',
        );
        return text;
      }
    } catch (e) {
      developer.log("Dosya işleme hatası: $e", name: 'TextToSpeechService');
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

      developer.log(
        "Metin okunuyor: [${text.substring(0, text.length > 50 ? 50 : text.length)}...",
        name: 'TextToSpeechService',
      );
      await _flutterTts.speak(text);
    } catch (e) {
      developer.log("Metin okuma hatası: $e", name: 'TextToSpeechService');
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
      developer.log(
        "Ses dosyası kaydetme hatası: $e",
        name: 'TextToSpeechService',
      );
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
      developer.log(
        "Ses dosyası oynatma hatası: $e",
        name: 'TextToSpeechService',
      );
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
      developer.log("Durdurma hatası: $e", name: 'TextToSpeechService');
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
      developer.log("Dil listesi alma hatası: $e", name: 'TextToSpeechService');
      return [];
    }
  }

  // Dil değiştirme
  Future<void> setLanguage(String languageCode) async {
    try {
      await _flutterTts.setLanguage(languageCode);
    } catch (e) {
      developer.log("Dil değiştirme hatası: $e", name: 'TextToSpeechService');
    }
  }

  // Konuşma hızını ayarlama
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      developer.log(
        "Konuşma hızı ayarlama hatası: $e",
        name: 'TextToSpeechService',
      );
    }
  }

  // Türkçe ses kalitesini optimize et
  Future<void> optimizeForTurkish() async {
    try {
      await _flutterTts.setLanguage("tr-TR");
      await _flutterTts.setSpeechRate(0.42); // Türkçe için optimal hız
      await _flutterTts.setPitch(0.88); // Türkçe ses tonu
      await _flutterTts.setVolume(1.0);

      // Türkçe ses seçimi
      if (Platform.isAndroid) {
        try {
          await _flutterTts.setVoice({
            "name": "tr-tr-x-ism-local",
            "locale": "tr-TR",
          });
        } catch (e) {
          try {
            await _flutterTts.setVoice({"name": "tr-TR", "locale": "tr-TR"});
          } catch (e2) {
            developer.log(
              "Türkçe ses ayarlanamadı",
              name: 'TextToSpeechService',
            );
          }
        }
      }

      developer.log(
        "Türkçe ses optimizasyonu tamamlandı",
        name: 'TextToSpeechService',
      );
    } catch (e) {
      developer.log(
        "Türkçe optimizasyon hatası: $e",
        name: 'TextToSpeechService',
      );
    }
  }

  // Ses seviyesini ayarlama
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
    } catch (e) {
      developer.log(
        "Ses seviyesi ayarlama hatası: $e",
        name: 'TextToSpeechService',
      );
    }
  }

  // Debug fonksiyonu
  Future<void> debugTTS() async {
    developer.log("=== TTS Debug Bilgileri ===", name: 'TextToSpeechService');
    developer.log("Başlatıldı: $_isInitialized", name: 'TextToSpeechService');
    developer.log("Oynatılıyor: $_isPlaying", name: 'TextToSpeechService');
    developer.log(
      "Mevcut ses dosyası: $_currentAudioPath",
      name: 'TextToSpeechService',
    );

    try {
      final List<dynamic> languages = await _flutterTts.getLanguages;
      developer.log(
        "Desteklenen diller: ${languages.length}",
        name: 'TextToSpeechService',
      );

      final List<dynamic> engines = await _flutterTts.getEngines;
      developer.log(
        "Mevcut engine'ler: ${engines.length}",
        name: 'TextToSpeechService',
      );

      // Test metni oku
      developer.log("Test metni okunuyor...", name: 'TextToSpeechService');
      await _flutterTts.speak("Test");
    } catch (e) {
      developer.log("Debug hatası: $e", name: 'TextToSpeechService');
    }
  }

  // Servisi temizleme
  void dispose() {
    _flutterTts.stop();
    _audioPlayer.dispose();
  }
}
