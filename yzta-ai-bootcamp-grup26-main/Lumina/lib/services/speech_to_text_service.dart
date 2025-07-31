import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

class SpeechToTextService {
  final SpeechToText _speechToText = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  String _currentLocaleId = 'tr_TR';

  // Mikrofon izni kontrolü
  Future<bool> _checkMicrophonePermission() async {
    try {
      PermissionStatus status = await Permission.microphone.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        status = await Permission.microphone.request();
        return status.isGranted;
      }

      return false;
    } catch (e) {
      developer.log(
        "Mikrofon izni kontrolü hatası: $e",
        name: 'SpeechToTextService',
      );
      return false;
    }
  }

  // Servisi başlatma
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Mikrofon iznini kontrol et
      bool hasPermission = await _checkMicrophonePermission();
      if (!hasPermission) {
        developer.log("Mikrofon izni verilmedi", name: 'SpeechToTextService');
        throw Exception('Mikrofon izni gerekli');
      }

      bool available = await _speechToText.initialize(
        onError: (error) {
          developer.log(
            "Speech to Text Error: [${error.errorMsg}",
            name: 'SpeechToTextService',
          );
        },
        onStatus: (status) {
          developer.log(
            "Speech to Text Status: $status",
            name: 'SpeechToTextService',
          );
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (available) {
        _isInitialized = true;
        developer.log(
          "Speech to Text başarıyla başlatıldı",
          name: 'SpeechToTextService',
        );

        // Desteklenen dilleri kontrol et
        await _checkAvailableLocales();
      } else {
        developer.log(
          "Speech to Text kullanılamıyor",
          name: 'SpeechToTextService',
        );
      }
    } catch (e) {
      developer.log(
        "Speech to Text initialization error: $e",
        name: 'SpeechToTextService',
      );
    }
  }

  // Desteklenen dilleri kontrol etme
  Future<void> _checkAvailableLocales() async {
    try {
      final locales = await _speechToText.locales();

      // Türkçe dil desteğini kontrol et
      final turkishLocale = locales
          .where(
            (locale) =>
                locale.localeId.startsWith('tr_') ||
                locale.localeId == 'tr_TR' ||
                locale.localeId == 'tr',
          )
          .firstOrNull;

      if (turkishLocale != null) {
        _currentLocaleId = turkishLocale.localeId;
        developer.log(
          "Türkçe dil desteği bulundu: $_currentLocaleId",
          name: 'SpeechToTextService',
        );
      } else {
        // Türkçe yoksa varsayılan dili kullan
        if (locales.isNotEmpty) {
          _currentLocaleId = locales.first.localeId;
          developer.log(
            "Varsayılan dil kullanılıyor: $_currentLocaleId",
            name: 'SpeechToTextService',
          );
        }
      }
    } catch (e) {
      developer.log("Dil kontrolü hatası: $e", name: 'SpeechToTextService');
    }
  }

  // Dinlemeye başlama
  Future<void> startListening({
    Function(String text)? onResult,
    Function()? onListeningComplete,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      if (_isListening) {
        await stopListening();
      }

      _lastWords = '';
      _isListening = true;

      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            _lastWords = result.recognizedWords;
            onResult?.call(_lastWords);
            _isListening = false;
            onListeningComplete?.call();
          }
        },
        localeId: _currentLocaleId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );

      developer.log("Dinleme başladı", name: 'SpeechToTextService');
    } catch (e) {
      developer.log("Dinleme başlatma hatası: $e", name: 'SpeechToTextService');
      _isListening = false;
      throw Exception('Dinleme başlatılamadı: $e');
    }
  }

  // Dinlemeyi durdurma
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      _isListening = false;
      developer.log("Dinleme durduruldu", name: 'SpeechToTextService');
    } catch (e) {
      developer.log("Dinleme durdurma hatası: $e", name: 'SpeechToTextService');
    }
  }

  // Dinleme durumunu kontrol etme
  bool get isListening => _isListening;

  // Son tanınan kelimeleri alma
  String get lastWords => _lastWords;

  // Mevcut dil ID'sini alma
  String get currentLocaleId => _currentLocaleId;

  // Desteklenen dilleri alma
  Future<List<LocaleName>> getSupportedLocales() async {
    try {
      return await _speechToText.locales();
    } catch (e) {
      developer.log(
        "Desteklenen diller alma hatası: $e",
        name: 'SpeechToTextService',
      );
      return [];
    }
  }

  // Dil değiştirme
  Future<void> setLocale(String localeId) async {
    try {
      _currentLocaleId = localeId;
      developer.log("Dil değiştirildi: $localeId", name: 'SpeechToTextService');
    } catch (e) {
      developer.log("Dil değiştirme hatası: $e", name: 'SpeechToTextService');
    }
  }

  // Tanınan metni dosyaya kaydetme
  Future<String> saveRecognizedTextToFile(String text, String fileName) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String textDir = path.join(appDir.path, 'recognized_text');

      // Text klasörünü oluştur
      await Directory(textDir).create(recursive: true);

      final String filePath = path.join(textDir, '$fileName.txt');
      final File file = File(filePath);

      await file.writeAsString(text);

      developer.log(
        "Tanınan metin kaydedildi: $filePath",
        name: 'SpeechToTextService',
      );
      return filePath;
    } catch (e) {
      developer.log("Metin kaydetme hatası: $e", name: 'SpeechToTextService');
      throw Exception('Metin kaydedilemedi: $e');
    }
  }

  // Debug fonksiyonu
  Future<void> debugSTT() async {
    developer.log(
      "=== Speech to Text Debug Bilgileri ===",
      name: 'SpeechToTextService',
    );
    developer.log("Başlatıldı: $_isInitialized", name: 'SpeechToTextService');
    developer.log("Dinleniyor: $_isListening", name: 'SpeechToTextService');
    developer.log("Son kelimeler: $_lastWords", name: 'SpeechToTextService');
    developer.log("Mevcut dil: $_currentLocaleId", name: 'SpeechToTextService');

    try {
      final locales = await _speechToText.locales();
      developer.log(
        "Desteklenen diller: ${locales.length}",
        name: 'SpeechToTextService',
      );

      for (var locale in locales.take(5)) {
        developer.log(
          "  - ${locale.localeId}: ${locale.name}",
          name: 'SpeechToTextService',
        );
      }
    } catch (e) {
      developer.log("Debug hatası: $e", name: 'SpeechToTextService');
    }
  }

  // Servisi temizleme
  void dispose() {
    _speechToText.stop();
  }
}
