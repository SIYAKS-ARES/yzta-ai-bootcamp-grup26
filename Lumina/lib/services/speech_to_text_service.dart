import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import 'dart:convert'; // Added for Utf8Codec

class SpeechToTextService {
  final SpeechToText _speechToText = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  String _currentLocaleId = 'tr_TR';
  String? _lastError;

  // Mikrofon izni kontrolü - geliştirilmiş
  Future<bool> _checkMicrophonePermission() async {
    try {
      PermissionStatus status = await Permission.microphone.status;

      if (status.isGranted) {
        developer.log(
          "Mikrofon izni zaten verilmiş",
          name: 'SpeechToTextService',
        );
        return true;
      }

      if (status.isDenied) {
        developer.log(
          "Mikrofon izni isteniyor...",
          name: 'SpeechToTextService',
        );
        status = await Permission.microphone.request();

        if (status.isGranted) {
          developer.log("Mikrofon izni verildi", name: 'SpeechToTextService');
          return true;
        } else {
          developer.log(
            "Mikrofon izni reddedildi",
            name: 'SpeechToTextService',
          );
          _lastError =
              'Mikrofon izni reddedildi. Lütfen ayarlardan izin verin.';
          return false;
        }
      }

      if (status.isPermanentlyDenied) {
        developer.log(
          "Mikrofon izni kalıcı olarak reddedildi",
          name: 'SpeechToTextService',
        );
        _lastError =
            'Mikrofon izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.';
        return false;
      }

      return false;
    } catch (e) {
      developer.log(
        "Mikrofon izni kontrolü hatası: $e",
        name: 'SpeechToTextService',
      );
      _lastError = 'Mikrofon izni kontrolünde hata: $e';
      return false;
    }
  }

  // Servisi başlatma - geliştirilmiş
  Future<bool> initialize() async {
    if (_isInitialized) {
      developer.log(
        "Speech to Text zaten başlatılmış",
        name: 'SpeechToTextService',
      );
      return true;
    }

    try {
      developer.log(
        "Speech to Text başlatılıyor... (Platform: ${Platform.operatingSystem})",
        name: 'SpeechToTextService',
      );

      // Mikrofon iznini kontrol et
      bool hasPermission = await _checkMicrophonePermission();
      if (!hasPermission) {
        developer.log("Mikrofon izni verilmedi", name: 'SpeechToTextService');
        return false;
      }

      bool available = await _speechToText.initialize(
        onError: (error) {
          developer.log(
            "Speech to Text Error: ${error.errorMsg} (Code: ${error.errorMsg})",
            name: 'SpeechToTextService',
          );

          // Android emülatör için özel hata yönetimi
          if (Platform.isAndroid) {
            switch (error.errorMsg) {
              case 'Error 7':
                _lastError =
                    'Android emülatörde ses tanıma sorunu. Fiziksel cihazda test edin.';
                break;
              case 'Error 9':
                _lastError =
                    'Ses tanıma servisi mevcut değil. Google uygulamasını güncelleyin.';
                break;
              case 'Error 3':
                _lastError =
                    'Ağ bağlantısı gerekli. İnternet bağlantınızı kontrol edin.';
                break;
              default:
                _lastError = 'Ses tanıma hatası: ${error.errorMsg}';
            }
          } else {
            _lastError = 'Ses tanıma hatası: ${error.errorMsg}';
          }
          _isListening = false;
        },
        onStatus: (status) {
          developer.log(
            "Speech to Text Status: $status",
            name: 'SpeechToTextService',
          );

          // Dinleme durumunu güncelle
          if (status == 'done' ||
              status == 'notListening' ||
              status == 'canceled' ||
              status == 'doneNoResult') {
            _isListening = false;
          } else if (status == 'listening') {
            _isListening = true;
          }
        },
        debugLogging: true, // Debug loglarını etkinleştir
      );

      if (available) {
        _isInitialized = true;
        _lastError = null;
        developer.log(
          "Speech to Text başarıyla başlatıldı",
          name: 'SpeechToTextService',
        );

        // Desteklenen dilleri kontrol et
        await _checkAvailableLocales();
        return true;
      } else {
        _lastError = 'Speech to Text kullanılamıyor';
        developer.log(
          "Speech to Text kullanılamıyor",
          name: 'SpeechToTextService',
        );
        return false;
      }
    } catch (e) {
      _lastError = 'Speech to Text başlatma hatası: $e';
      developer.log(
        "Speech to Text initialization error: $e",
        name: 'SpeechToTextService',
      );
      return false;
    }
  }

  // Desteklenen dilleri kontrol etme - geliştirilmiş
  Future<void> _checkAvailableLocales() async {
    try {
      final locales = await _speechToText.locales();
      developer.log(
        "Toplam ${locales.length} dil desteği bulundu",
        name: 'SpeechToTextService',
      );

      // Türkçe dil desteğini kontrol et - geliştirilmiş
      final turkishLocales = locales
          .where(
            (locale) =>
                locale.localeId.startsWith('tr_') ||
                locale.localeId == 'tr_TR' ||
                locale.localeId == 'tr' ||
                locale.name.toLowerCase().contains('turkish') ||
                locale.name.toLowerCase().contains('türkçe') ||
                locale.name.toLowerCase().contains('turkish') ||
                locale.name.toLowerCase().contains('türk') ||
                locale.name.toLowerCase().contains('turkey'),
          )
          .toList();

      developer.log(
        "Bulunan Türkçe diller: ${turkishLocales.map((l) => '${l.localeId} (${l.name})').join(', ')}",
        name: 'SpeechToTextService',
      );

      if (turkishLocales.isNotEmpty) {
        // En uygun Türkçe dilini seç - öncelik sırası
        LocaleName preferredTurkish;

        // Önce tr_TR'yi ara
        preferredTurkish = turkishLocales.firstWhere(
          (locale) => locale.localeId == 'tr_TR',
          orElse: () => turkishLocales.first,
        );

        // Eğer tr_TR yoksa, tr_ ile başlayan ilkini ara
        if (preferredTurkish.localeId != 'tr_TR') {
          preferredTurkish = turkishLocales.firstWhere(
            (locale) => locale.localeId.startsWith('tr_'),
            orElse: () => turkishLocales.first,
          );
        }

        _currentLocaleId = preferredTurkish.localeId;
        developer.log(
          "Türkçe dil seçildi: $_currentLocaleId (${preferredTurkish.name})",
          name: 'SpeechToTextService',
        );
      } else {
        // Türkçe yoksa varsayılan dili kullan
        if (locales.isNotEmpty) {
          _currentLocaleId = locales.first.localeId;
          developer.log(
            "Varsayılan dil kullanılıyor: $_currentLocaleId (${locales.first.name})",
            name: 'SpeechToTextService',
          );
        }
      }

      // Desteklenen dilleri logla
      developer.log("Desteklenen diller:", name: 'SpeechToTextService');
      for (var locale in locales.take(10)) {
        developer.log(
          "  - ${locale.localeId}: ${locale.name}",
          name: 'SpeechToTextService',
        );
      }
    } catch (e) {
      developer.log("Dil kontrolü hatası: $e", name: 'SpeechToTextService');
    }
  }

  // Dinlemeye başlama - geliştirilmiş
  Future<bool> startListening({
    Function(String text)? onResult,
    Function()? onListeningComplete,
    Function(String error)? onError,
  }) async {
    try {
      // Servisi başlat
      if (!_isInitialized) {
        bool initialized = await initialize();
        if (!initialized) {
          onError?.call(_lastError ?? 'Servis başlatılamadı');
          return false;
        }
      }

      // Zaten dinleniyorsa durdur
      if (_isListening) {
        await stopListening();
      }

      _lastWords = '';
      _lastError = null;
      _isListening = true;

      // Android emülatör için özel ayarlar
      Map<String, dynamic> listenOptions = {
        'cancelOnError': false,
        'listenMode': 'confirmation',
        'partialResults': true,
      };

      // Android emülatör kontrolü
      if (Platform.isAndroid) {
        // Emülatör için daha uzun dinleme süresi
        listenOptions['listenFor'] = const Duration(seconds: 60);
        listenOptions['pauseFor'] = const Duration(seconds: 5);
      } else {
        listenOptions['listenFor'] = const Duration(seconds: 30);
        listenOptions['pauseFor'] = const Duration(seconds: 3);
      }

      await _speechToText.listen(
        onResult: (result) {
          developer.log(
            "Ses tanıma sonucu: ${result.recognizedWords} (final: ${result.finalResult})",
            name: 'SpeechToTextService',
          );

          if (result.finalResult) {
            _lastWords = result.recognizedWords;
            _isListening = false;
            onResult?.call(_lastWords);
            onListeningComplete?.call();
          }
        },
        localeId: _currentLocaleId,
        listenFor: listenOptions['listenFor'],
        pauseFor: listenOptions['pauseFor'],
        listenOptions: SpeechListenOptions(
          cancelOnError: listenOptions['cancelOnError'],
          listenMode: ListenMode.confirmation,
          partialResults: listenOptions['partialResults'],
        ),
      );

      developer.log(
        "Dinleme başladı (Dil: $_currentLocaleId, Platform: ${Platform.operatingSystem})",
        name: 'SpeechToTextService',
      );
      return true;
    } catch (e) {
      _lastError = 'Dinleme başlatılamadı: $e';
      _isListening = false;
      developer.log("Dinleme başlatma hatası: $e", name: 'SpeechToTextService');

      // Android emülatör için özel hata mesajları
      if (Platform.isAndroid && e.toString().contains('Error 7')) {
        onError?.call(
          'Android emülatörde ses tanıma sorunu. Lütfen fiziksel cihazda test edin.',
        );
      } else if (Platform.isAndroid && e.toString().contains('Error 9')) {
        onError?.call(
          'Ses tanıma servisi mevcut değil. Lütfen Google uygulamasını güncelleyin.',
        );
      } else {
        onError?.call(_lastError!);
      }
      return false;
    }
  }

  // Dinlemeyi durdurma - geliştirilmiş
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speechToText.stop();
        _isListening = false;
        developer.log("Dinleme durduruldu", name: 'SpeechToTextService');
      }
    } catch (e) {
      developer.log("Dinleme durdurma hatası: $e", name: 'SpeechToTextService');
      _isListening = false;
    }
  }

  // Dinleme durumunu kontrol etme
  bool get isListening => _isListening;

  // Son tanınan kelimeleri alma
  String get lastWords => _lastWords;

  // Mevcut dil ID'sini alma
  String get currentLocaleId => _currentLocaleId;

  // Son hatayı alma
  String? get lastError => _lastError;

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

  // Dil değiştirme - geliştirilmiş
  Future<bool> setLocale(String localeId) async {
    try {
      final locales = await _speechToText.locales();
      final targetLocale = locales
          .where((locale) => locale.localeId == localeId)
          .firstOrNull;

      if (targetLocale != null) {
        _currentLocaleId = localeId;
        developer.log(
          "Dil değiştirildi: $localeId (${targetLocale.name})",
          name: 'SpeechToTextService',
        );
        return true;
      } else {
        developer.log(
          "Belirtilen dil bulunamadı: $localeId",
          name: 'SpeechToTextService',
        );
        return false;
      }
    } catch (e) {
      developer.log("Dil değiştirme hatası: $e", name: 'SpeechToTextService');
      return false;
    }
  }

  // Tanınan metni dosyaya kaydetme - geliştirilmiş
  Future<String> saveRecognizedTextToFile(String text, String fileName) async {
    try {
      if (text.trim().isEmpty) {
        throw Exception('Kaydedilecek metin boş olamaz');
      }

      // Platform kontrolü
      if (!Platform.isAndroid && !Platform.isIOS) {
        throw Exception('Bu özellik sadece mobil platformlarda desteklenir');
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String textDir = path.join(appDir.path, 'recognized_text');

      // Text klasörünü oluştur
      final Directory dir = Directory(textDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Dosya adını temizle ve tarih ekle
      final String cleanFileName = fileName.replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      );
      final String timestamp = DateTime.now().toIso8601String().replaceAll(
        ':',
        '-',
      );
      final String filePath = path.join(
        textDir,
        '${cleanFileName}_$timestamp.txt',
      );
      final File file = File(filePath);

      // Metni UTF-8 ile kaydet
      await file.writeAsString(text, encoding: const Utf8Codec());

      developer.log(
        "Tanınan metin kaydedildi: $filePath (${text.length} karakter)",
        name: 'SpeechToTextService',
      );
      return filePath;
    } catch (e) {
      developer.log("Metin kaydetme hatası: $e", name: 'SpeechToTextService');

      // Daha detaylı hata mesajları
      if (e.toString().contains('MissingPluginException')) {
        throw Exception(
          'Path provider plugin hatası. Lütfen uygulamayı yeniden başlatın.',
        );
      } else if (e.toString().contains('Permission')) {
        throw Exception(
          'Dosya yazma izni gerekli. Lütfen ayarlardan izin verin.',
        );
      } else {
        throw Exception('Metin kaydedilemedi: $e');
      }
    }
  }

  // Debug fonksiyonu - geliştirilmiş
  Future<Map<String, dynamic>> debugSTT() async {
    final Map<String, dynamic> debugInfo = {
      'initialized': _isInitialized,
      'isListening': _isListening,
      'lastWords': _lastWords,
      'currentLocaleId': _currentLocaleId,
      'lastError': _lastError,
    };

    try {
      final locales = await _speechToText.locales();
      debugInfo['supportedLocalesCount'] = locales.length;
      debugInfo['supportedLocales'] = locales
          .take(5)
          .map((locale) => {'id': locale.localeId, 'name': locale.name})
          .toList();
    } catch (e) {
      debugInfo['localeError'] = e.toString();
    }

    developer.log(
      "=== Speech to Text Debug Bilgileri ===",
      name: 'SpeechToTextService',
    );
    debugInfo.forEach((key, value) {
      developer.log("$key: $value", name: 'SpeechToTextService');
    });

    return debugInfo;
  }

  // Servisi temizleme - geliştirilmiş
  void dispose() {
    try {
      if (_isListening) {
        _speechToText.stop();
      }
      _isListening = false;
      _isInitialized = false;
      developer.log(
        "Speech to Text servisi temizlendi",
        name: 'SpeechToTextService',
      );
    } catch (e) {
      developer.log("Servis temizleme hatası: $e", name: 'SpeechToTextService');
    }
  }
}
