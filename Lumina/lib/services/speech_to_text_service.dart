import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

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
      print("Mikrofon izni kontrolü hatası: $e");
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
        print("Mikrofon izni verilmedi");
        throw Exception('Mikrofon izni gerekli');
      }

      bool available = await _speechToText.initialize(
        onError: (error) {
          print("Speech to Text Error: ${error.errorMsg}");
        },
        onStatus: (status) {
          print("Speech to Text Status: $status");
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (available) {
        _isInitialized = true;
        print("Speech to Text başarıyla başlatıldı");

        // Desteklenen dilleri kontrol et
        await _checkAvailableLocales();
      } else {
        print("Speech to Text kullanılamıyor");
      }
    } catch (e) {
      print("Speech to Text initialization error: $e");
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
        print("Türkçe dil desteği bulundu: $_currentLocaleId");
      } else {
        // Türkçe yoksa varsayılan dili kullan
        if (locales.isNotEmpty) {
          _currentLocaleId = locales.first.localeId;
          print("Varsayılan dil kullanılıyor: $_currentLocaleId");
        }
      }
    } catch (e) {
      print("Dil kontrolü hatası: $e");
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
        listenMode: ListenMode.confirmation,
        partialResults: true,
        onDevice: false,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );

      print("Dinleme başladı");
    } catch (e) {
      print("Dinleme başlatma hatası: $e");
      _isListening = false;
      throw Exception('Dinleme başlatılamadı: $e');
    }
  }

  // Dinlemeyi durdurma
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      _isListening = false;
      print("Dinleme durduruldu");
    } catch (e) {
      print("Dinleme durdurma hatası: $e");
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
      print("Desteklenen diller alma hatası: $e");
      return [];
    }
  }

  // Dil değiştirme
  Future<void> setLocale(String localeId) async {
    try {
      _currentLocaleId = localeId;
      print("Dil değiştirildi: $localeId");
    } catch (e) {
      print("Dil değiştirme hatası: $e");
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

      print("Tanınan metin kaydedildi: $filePath");
      return filePath;
    } catch (e) {
      print("Metin kaydetme hatası: $e");
      throw Exception('Metin kaydedilemedi: $e');
    }
  }

  // Debug fonksiyonu
  Future<void> debugSTT() async {
    print("=== Speech to Text Debug Bilgileri ===");
    print("Başlatıldı: $_isInitialized");
    print("Dinleniyor: $_isListening");
    print("Son kelimeler: $_lastWords");
    print("Mevcut dil: $_currentLocaleId");

    try {
      final locales = await _speechToText.locales();
      print("Desteklenen diller: ${locales.length}");

      for (var locale in locales.take(5)) {
        print("  - ${locale.localeId}: ${locale.name}");
      }
    } catch (e) {
      print("Debug hatası: $e");
    }
  }

  // Servisi temizleme
  void dispose() {
    _speechToText.stop();
  }
}
