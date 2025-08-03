import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum WhisperMode {
  local, // Yerel Python Whisper
  api, // OpenAI API
  auto, // Otomatik seçim
}

class WhisperHybridService extends ChangeNotifier {
  static final WhisperHybridService _instance =
      WhisperHybridService._internal();
  factory WhisperHybridService() => _instance;
  WhisperHybridService._internal();

  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _lastError;
  WhisperMode _currentMode = WhisperMode.auto;
  String? _pythonScriptPath;
  String? _apiKey;

  // API endpoint
  static const String _apiUrl = 'https://api.elevenlabs.io/v1/speech-to-text';
  static const String _model = 'scribe_v1';

  String? get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  WhisperMode get currentMode => _currentMode;

  // Mod ayarla
  void setMode(WhisperMode mode) {
    _currentMode = mode;
    _isInitialized = false; // Yeniden başlat
    notifyListeners();
  }

  // Whisper'ı başlat
  Future<bool> _ensureInitialized() async {
    if (_isInitialized) return true;
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return _isInitialized;
    }

    _isInitializing = true;
    try {
      bool initialized = false;

      switch (_currentMode) {
        case WhisperMode.local:
          initialized = await _initializeLocal();
          break;
        case WhisperMode.api:
          initialized = await _initializeApi();
          break;
        case WhisperMode.auto:
          initialized = await _initializeAuto();
          break;
      }

      _isInitialized = initialized;
      _lastError = null;
      notifyListeners();

      return initialized;
    } catch (e) {
      _lastError = e.toString();
      _isInitialized = false;
      notifyListeners();
      return false;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Yerel mod başlat
  Future<bool> _initializeLocal() async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Yerel Whisper başlatma başladı...');
      }

      // Android'de Python3 kurulumu kontrol et
      bool pythonAvailable = false;
      String pythonVersion = '';
      String pythonError = '';

      // Önce python3'ü dene
      try {
        if (kDebugMode) {
          debugPrint('🔍 Python3 kontrol ediliyor...');
        }

        final pythonCheck = await Process.run('python3', ['--version']);
        pythonAvailable = pythonCheck.exitCode == 0;
        pythonVersion = pythonCheck.stdout.toString().trim();
        pythonError = pythonCheck.stderr.toString().trim();

        if (kDebugMode) {
          debugPrint('🐍 Python3 kontrol sonucu:');
          debugPrint('   Exit Code: ${pythonCheck.exitCode}');
          debugPrint('   Version: $pythonVersion');
          debugPrint('   Error: $pythonError');
          debugPrint('   Available: $pythonAvailable');
        }
      } catch (e) {
        pythonAvailable = false;
        pythonError = e.toString();
        if (kDebugMode) {
          debugPrint('❌ Python3 kontrol hatası: $e');
        }
      }

      // Python3 yoksa python'u dene
      if (!pythonAvailable) {
        try {
          if (kDebugMode) {
            debugPrint('🔍 Python kontrol ediliyor...');
          }

          final pythonCheck = await Process.run('python', ['--version']);
          pythonAvailable = pythonCheck.exitCode == 0;
          pythonVersion = pythonCheck.stdout.toString().trim();
          pythonError = pythonCheck.stderr.toString().trim();

          if (kDebugMode) {
            debugPrint('🐍 Python kontrol sonucu:');
            debugPrint('   Exit Code: ${pythonCheck.exitCode}');
            debugPrint('   Version: $pythonVersion');
            debugPrint('   Error: $pythonError');
            debugPrint('   Available: $pythonAvailable');
          }
        } catch (e) {
          pythonAvailable = false;
          pythonError = e.toString();
          if (kDebugMode) {
            debugPrint('❌ Python kontrol hatası: $e');
          }
        }
      }

      if (!pythonAvailable) {
        _lastError =
            'Python3/Python bulunamadı - Android\'de yerel Whisper desteklenmiyor';
        if (kDebugMode) {
          debugPrint('❌ Python bulunamadı: $_lastError');
        }
        return false;
      }

      // Python komutunu belirle
      final pythonCommand = await _getPythonCommand();

      if (kDebugMode) {
        debugPrint('✅ Python bulundu: $pythonVersion');
        debugPrint('🔧 Kullanılacak komut: $pythonCommand');
      }

      // Python script'ini oluştur
      if (kDebugMode) {
        debugPrint('📝 Python script oluşturuluyor...');
      }

      _pythonScriptPath = await _createPythonScript();

      if (kDebugMode) {
        debugPrint('📄 Script yolu: $_pythonScriptPath');
      }

      // Whisper kütüphanesini kontrol et
      if (kDebugMode) {
        debugPrint('🔍 Whisper kütüphanesi kontrol ediliyor...');
      }

      final whisperCheck = await Process.run(pythonCommand, [
        '-c',
        'import whisper; print("Whisper available")',
      ]);

      if (kDebugMode) {
        debugPrint('📚 Whisper kontrol sonucu:');
        debugPrint('   Exit Code: ${whisperCheck.exitCode}');
        debugPrint('   Stdout: ${whisperCheck.stdout.toString().trim()}');
        debugPrint('   Stderr: ${whisperCheck.stderr.toString().trim()}');
      }

      if (whisperCheck.exitCode != 0) {
        _lastError =
            'Whisper kütüphanesi yüklü değil - pip3 install openai-whisper';
        if (kDebugMode) {
          debugPrint('❌ Whisper kütüphanesi bulunamadı: $_lastError');
        }
        return false;
      }

      if (kDebugMode) {
        debugPrint('✅ Whisper kütüphanesi bulundu');
      }

      // Whisper modelini kontrol et ve gerekirse kur
      if (kDebugMode) {
        debugPrint('🔍 Whisper modeli kontrol ediliyor...');
      }

      final modelCheck = await Process.run(pythonCommand, [
        '-c',
        '''
import whisper
import os
from pathlib import Path

# Model cache dizinini kontrol et
cache_dir = os.path.expanduser("~/.cache/whisper")
print(f"Cache dir: {cache_dir}")
print(f"Cache exists: {os.path.exists(cache_dir)}")

if os.path.exists(cache_dir):
    models = list(Path(cache_dir).glob("*.pt"))
    print(f"Models found: {len(models)}")
    for model in models:
        print(f"  - {model.name}")
else:
    print("Cache directory not found")

# Tiny modelini yüklemeyi dene
try:
    print("Tiny model yükleniyor...")
    model = whisper.load_model("tiny")
    print("Tiny model loaded successfully")
    print(f"Model size: {model.model_size}")
except Exception as e:
    print(f"Model loading error: {e}")
    print("Model indirme deneniyor...")
    try:
        # Modeli zorla indir
        model = whisper.load_model("tiny", download_root=cache_dir)
        print("Model başarıyla indirildi!")
    except Exception as e2:
        print(f"Model indirme hatası: {e2}")
''',
      ]);

      if (kDebugMode) {
        debugPrint('📦 Model kontrol sonucu:');
        debugPrint('   Exit Code: ${modelCheck.exitCode}');
        debugPrint('   Stdout: ${modelCheck.stdout.toString().trim()}');
        debugPrint('   Stderr: ${modelCheck.stderr.toString().trim()}');
      }

      // Model yükleme başarısızsa, otomatik indirme dene
      if (modelCheck.exitCode != 0 ||
          modelCheck.stderr.toString().contains('Model loading error')) {
        if (kDebugMode) {
          debugPrint('🔄 Model otomatik indirme deneniyor...');
        }

        final autoDownload = await Process.run(pythonCommand, [
          '-c',
          '''
import whisper
import os

try:
    print("Tiny model otomatik indiriliyor...")
    model = whisper.load_model("tiny")
    print("Model başarıyla indirildi ve yüklendi!")
    print("SUCCESS")
except Exception as e:
    print(f"Otomatik indirme hatası: {e}")
    print("FAILED")
''',
        ]);

        if (kDebugMode) {
          debugPrint('📥 Otomatik indirme sonucu:');
          debugPrint('   Exit Code: ${autoDownload.exitCode}');
          debugPrint('   Stdout: ${autoDownload.stdout.toString().trim()}');
          debugPrint('   Stderr: ${autoDownload.stderr.toString().trim()}');
        }

        if (autoDownload.exitCode != 0 ||
            !autoDownload.stdout.toString().contains('SUCCESS')) {
          _lastError =
              'Whisper modeli indirilemedi - İnternet bağlantısını kontrol edin';
          if (kDebugMode) {
            debugPrint('❌ Whisper modeli indirilemedi: $_lastError');
          }
          return false;
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Whisper modeli kontrol edildi');
        debugPrint('🎉 Yerel Whisper başarıyla başlatıldı!');
      }

      return true;
    } catch (e) {
      _lastError = 'Yerel mod başlatma hatası: $e';
      if (kDebugMode) {
        debugPrint('❌ Yerel mod başlatma hatası: $e');
      }
      return false;
    }
  }

  // API mod başlat
  Future<bool> _initializeApi() async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 API mod başlatma başladı...');
      }

      final apiKey = _getApiKey();

      if (kDebugMode) {
        debugPrint('🔑 API anahtarı kontrol ediliyor...');
        debugPrint('   API Key uzunluğu: ${apiKey.length}');
        debugPrint('   API Key boş mu: ${apiKey.isEmpty}');
        if (apiKey.isNotEmpty) {
          debugPrint('   API Key başlangıcı: ${apiKey.substring(0, 7)}...');
        }
      }

      if (apiKey.isEmpty) {
        _lastError = 'OpenAI API anahtarı gerekli';
        if (kDebugMode) {
          debugPrint('❌ API anahtarı bulunamadı: $_lastError');
        }
        return false;
      }

      if (kDebugMode) {
        debugPrint('✅ API anahtarı bulundu');
        debugPrint('🎉 API mod başarıyla başlatıldı!');
      }

      return true;
    } catch (e) {
      _lastError = 'API mod başlatma hatası: $e';
      if (kDebugMode) {
        debugPrint('❌ API mod başlatma hatası: $e');
      }
      return false;
    }
  }

  // Direkt API modu başlat
  Future<bool> _initializeAuto() async {
    try {
      if (kDebugMode) {
        debugPrint('🤖 OpenAI API modu başlatılıyor...');
      }

      // API anahtarını kontrol et
      final apiKey = _getApiKey();
      if (apiKey.isNotEmpty && apiKey != 'YOUR_OPENAI_API_KEY_HERE') {
        if (kDebugMode) {
          debugPrint('🔑 API anahtarı bulundu, API modu başlatılıyor...');
        }

        if (await _initializeApi()) {
          _currentMode = WhisperMode.api;
          if (kDebugMode) {
            debugPrint('✅ OpenAI API modu başarıyla başlatıldı');
          }
          return true;
        }
      }

      if (kDebugMode) {
        debugPrint('❌ API anahtarı bulunamadı, Mock moda geçiliyor...');
      }

      // API başarısızsa mock mod
      _currentMode = WhisperMode.auto;
      if (kDebugMode) {
        debugPrint('🎭 Mock moda geçildi');
      }
      return true;
    } catch (e) {
      _lastError = 'API modu başlatma hatası: $e';
      if (kDebugMode) {
        debugPrint('❌ API modu başlatma hatası: $e');
      }
      _currentMode = WhisperMode.auto;
      return true; // Mock moda geç
    }
  }

  Future<bool> initialize() async {
    return await _ensureInitialized();
  }

  // API anahtarını al
  String _getApiKey() {
    if (kDebugMode) {
      debugPrint('🔑 API anahtarı aranıyor...');
    }

    // Önce manuel girilen API anahtarını kontrol et
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '✅ Manuel API anahtarı bulundu (${_apiKey!.length} karakter)',
        );
      }
      return _apiKey!;
    }

    if (kDebugMode) {
      debugPrint(
        '🔍 Manuel API anahtarı bulunamadı, .env dosyası kontrol ediliyor...',
      );
    }

    // Sonra .env dosyasından al
    try {
      final envApiKey = dotenv.env['ELEVENLABS_API_KEY'];

      if (kDebugMode) {
        debugPrint('📄 .env dosyasından API anahtarı:');
        debugPrint('   Değer: ${envApiKey ?? 'null'}');
        debugPrint('   Boş mu: ${envApiKey?.isEmpty ?? true}');
        debugPrint(
          '   Varsayılan mu: ${envApiKey == 'YOUR_ELEVENLABS_API_KEY_HERE'}',
        );
      }

      if (envApiKey != null &&
          envApiKey.isNotEmpty &&
          envApiKey != 'YOUR_ELEVENLABS_API_KEY_HERE') {
        if (kDebugMode) {
          debugPrint(
            '✅ .env dosyasından API anahtarı bulundu (${envApiKey.length} karakter)',
          );
        }
        return envApiKey;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ .env dosyasından API anahtarı alınamadı: $e');
      }
    }

    if (kDebugMode) {
      debugPrint('❌ Hiçbir API anahtarı bulunamadı');
    }

    return '';
  }

  // API anahtarını ayarla
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
    if (_currentMode == WhisperMode.api) {
      _isInitialized = false; // Yeniden başlat
      notifyListeners();
    }
  }

  // Python komutunu belirle
  Future<String> _getPythonCommand() async {
    // Android'de sistem Python3 yolunu dene
    final systemPythonPaths = [
      '/system/bin/python3',
      '/usr/bin/python3',
      '/data/data/com.termux/files/usr/bin/python3', // Termux
    ];

    for (final pythonPath in systemPythonPaths) {
      try {
        final check = await Process.run(pythonPath, ['--version']);
        if (check.exitCode == 0) {
          if (kDebugMode) {
            debugPrint(
              '✅ Python3 bulundu: $pythonPath - ${check.stdout.toString().trim()}',
            );
          }
          return pythonPath;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Python3 bulunamadı: $pythonPath - $e');
        }
      }
    }

    // Önce python3'ü dene
    try {
      final python3Check = await Process.run('python3', ['--version']);
      if (python3Check.exitCode == 0) {
        if (kDebugMode) {
          debugPrint(
            '✅ Sistem Python3 bulundu: ${python3Check.stdout.toString().trim()}',
          );
        }
        return 'python3';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sistem Python3 bulunamadı: $e');
      }
    }

    // Sonra python'u dene
    try {
      final pythonCheck = await Process.run('python', ['--version']);
      if (pythonCheck.exitCode == 0) {
        if (kDebugMode) {
          debugPrint(
            '✅ Sistem Python bulundu: ${pythonCheck.stdout.toString().trim()}',
          );
        }
        return 'python';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sistem Python bulunamadı: $e');
      }
    }

    // Varsayılan olarak python3 döndür
    if (kDebugMode) {
      debugPrint(
        '⚠️ Hiçbir Python bulunamadı, varsayılan olarak python3 kullanılacak',
      );
    }
    return 'python3';
  }

  // Python script'ini oluştur
  Future<String> _createPythonScript() async {
    final appDir = await getApplicationDocumentsDirectory();
    final scriptPath = '${appDir.path}/whisper_transcribe.py';
    final scriptFile = File(scriptPath);

    if (await scriptFile.exists()) {
      return scriptPath;
    }

    // Python script içeriği
    const scriptContent = '''
import sys
import json
import whisper
import tempfile
import os
from pathlib import Path

def transcribe_audio(audio_path, output_path):
    try:
        print(f"Audio dosyası: {audio_path}")
        print(f"Çıktı dosyası: {output_path}")
        
        # Audio dosyasının varlığını kontrol et
        if not os.path.exists(audio_path):
            print(f"Audio dosyası bulunamadı: {audio_path}", file=sys.stderr)
            return False
        
        print("Whisper modeli yükleniyor...")
        # Whisper modelini yükle (küçük model)
        model = whisper.load_model("tiny")
        print("Model yüklendi!")
        
        print("Transkript başlıyor...")
        # Audio dosyasını transkript et
        result = model.transcribe(audio_path, language="tr")
        print("Transkript tamamlandı!")
        
        print("Sonuçlar kaydediliyor...")
        # Sonuçları JSON formatında kaydet
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
        
        print("Başarılı!")
        return True
    except Exception as e:
        print(f"Transkript hatası: {str(e)}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <audio_path> <output_path>", file=sys.stderr)
        sys.exit(1)
    
    audio_path = sys.argv[1]
    output_path = sys.argv[2]
    
    print("Whisper transkript script'i başlatıldı...")
    success = transcribe_audio(audio_path, output_path)
    print(f"Script tamamlandı: {'Başarılı' if success else 'Başarısız'}")
    sys.exit(0 if success else 1)
''';

    await scriptFile.writeAsString(scriptContent);
    return scriptPath;
  }

  // Audio dosyasını transkript et
  Future<TranscriptResult?> transcribeAudio(String audioPath) async {
    final initialized = await _ensureInitialized();
    if (!initialized) {
      _lastError = 'Whisper servisi başlatılamadı';
      return null;
    }

    try {
      // Audio dosyasının varlığını kontrol et
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        _lastError = 'Audio dosyası bulunamadı: $audioPath';
        return null;
      }

      switch (_currentMode) {
        case WhisperMode.local:
          return await _transcribeLocal(audioPath);
        case WhisperMode.api:
          return await _transcribeApi(audioPath);
        case WhisperMode.auto:
          return await _transcribeAuto(audioPath);
      }
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) {
        debugPrint('Whisper transkript hatası: $e');
      }
      return null;
    }
  }

  // Yerel transkript
  Future<TranscriptResult?> _transcribeLocal(String audioPath) async {
    try {
      if (kDebugMode) {
        debugPrint('🎯 Yerel transkript başlatılıyor...');
        debugPrint('📁 Audio dosyası: $audioPath');
      }

      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/whisper_output.json';

      if (kDebugMode) {
        debugPrint('📄 Çıktı dosyası: $outputPath');
      }

      // Python komutunu belirle
      final pythonCommand = await _getPythonCommand();

      if (kDebugMode) {
        debugPrint('🐍 Python komutu: $pythonCommand');
        debugPrint('📜 Script yolu: $_pythonScriptPath');
      }

      if (kDebugMode) {
        debugPrint('🚀 Python script çalıştırılıyor...');
      }

      final result = await Process.run(pythonCommand, [
        _pythonScriptPath!,
        audioPath,
        outputPath,
      ]);

      if (kDebugMode) {
        debugPrint('📊 Python script sonucu:');
        debugPrint('   Exit Code: ${result.exitCode}');
        debugPrint('   Stdout: ${result.stdout.toString().trim()}');
        debugPrint('   Stderr: ${result.stderr.toString().trim()}');
      }

      if (result.exitCode == 0) {
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          if (kDebugMode) {
            debugPrint('✅ Çıktı dosyası bulundu, JSON okunuyor...');
          }

          final jsonContent = await outputFile.readAsString();
          final jsonData = json.decode(jsonContent);

          final segments = _parseWhisperJson(jsonData);
          final fullText = jsonData['text'] ?? '';
          final language = jsonData['language'] ?? 'tr';
          final duration = (jsonData['duration'] ?? 0.0).toDouble();

          if (kDebugMode) {
            debugPrint('✅ JSON başarıyla parse edildi');
            debugPrint('📝 Metin uzunluğu: ${fullText.length} karakter');
            debugPrint('🌍 Dil: $language');
            debugPrint('⏱️ Süre: $duration saniye');
          }

          return TranscriptResult(
            segments: segments,
            fullText: fullText,
            language: language,
            duration: duration,
          );
        } else {
          if (kDebugMode) {
            debugPrint('❌ Çıktı dosyası bulunamadı: $outputPath');
          }
          _lastError = 'Çıktı dosyası oluşturulamadı';
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Python script başarısız: Exit Code ${result.exitCode}');
        }
        _lastError = 'Yerel Python script hatası: ${result.stderr}';
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Yerel transkript exception: $e');
      }
      _lastError = 'Yerel transkript hatası: $e';
      return null;
    }
  }

  // API transkript
  Future<TranscriptResult?> _transcribeApi(String audioPath) async {
    try {
      if (kDebugMode) {
        debugPrint('🔑 ElevenLabs API transkript başlatılıyor...');
        debugPrint('📁 Audio dosyası: $audioPath');
      }

      final apiKey = _getApiKey();
      if (apiKey.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ API anahtarı boş, mock kullanılıyor');
        }
        return await _transcribeMock(audioPath);
      }

      if (kDebugMode) {
        debugPrint('✅ API anahtarı bulundu (${apiKey.length} karakter)');
      }

      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        if (kDebugMode) {
          debugPrint('❌ Audio dosyası bulunamadı: $audioPath');
        }
        _lastError = 'Audio dosyası bulunamadı';
        return null;
      }

      final audioBytes = await audioFile.readAsBytes();
      if (kDebugMode) {
        debugPrint('📊 Audio dosyası boyutu: ${audioBytes.length} bytes');
      }

      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.headers['xi-api-key'] = apiKey;
      request.fields['model_id'] = _model;
      request.fields['language_code'] = 'tr';

      request.files.add(
        http.MultipartFile.fromBytes('file', audioBytes, filename: 'audio.wav'),
      );

      if (kDebugMode) {
        debugPrint('🌐 ElevenLabs API isteği gönderiliyor...');
        debugPrint('   URL: $_apiUrl');
        debugPrint('   Model: $_model');
      }

      // Timeout ile API isteği gönder
      final response = await request.send().timeout(
        Duration(seconds: 60), // 60 saniye timeout
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⏰ API isteği timeout oldu (60 saniye)');
          }
          throw TimeoutException(
            'ElevenLabs API isteği timeout oldu',
            Duration(seconds: 60),
          );
        },
      );

      if (kDebugMode) {
        debugPrint('📡 API yanıtı alındı, işleniyor...');
        debugPrint('   Status Code: ${response.statusCode}');
      }

      final responseBody = await response.stream.bytesToString().timeout(
        Duration(seconds: 30), // Response body okuma için 30 saniye timeout
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⏰ Response body okuma timeout oldu');
          }
          throw TimeoutException(
            'Response body okuma timeout oldu',
            Duration(seconds: 30),
          );
        },
      );

      if (kDebugMode) {
        debugPrint(
          '📄 Response body uzunluğu: ${responseBody.length} karakter',
        );
        debugPrint(
          '   Response Body: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}...',
        );
      }

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseBody);
        final result = _parseElevenLabsResponse(jsonData);

        if (kDebugMode) {
          debugPrint('✅ ElevenLabs API transkript başarılı');
        }

        return result;
      } else {
        if (kDebugMode) {
          debugPrint('❌ API hatası: ${response.statusCode}');
          debugPrint('   Hata detayı: $responseBody');
        }
        _lastError =
            'ElevenLabs API hatası: ${response.statusCode} - $responseBody';
        return await _transcribeMock(audioPath);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ElevenLabs API transkript hatası: $e');
      }
      _lastError = 'ElevenLabs API transkript hatası: $e';
      return await _transcribeMock(audioPath);
    }
  }

  // Otomatik transkript
  Future<TranscriptResult?> _transcribeAuto(String audioPath) async {
    // API öncelikli olarak API'yi dene
    if (kDebugMode) {
      debugPrint('🤖 Otomatik transkript: API deneniyor...');
    }

    final apiResult = await _transcribeApi(audioPath);
    if (apiResult != null) {
      if (kDebugMode) {
        debugPrint('✅ Otomatik transkript: API başarılı');
      }
      return apiResult;
    }

    if (kDebugMode) {
      debugPrint('❌ Otomatik transkript: API başarısız, mock kullanılıyor');
    }

    return await _transcribeMock(audioPath);
  }

  // Mock transkript (test için)
  Future<TranscriptResult?> _transcribeMock(String audioPath) async {
    try {
      if (kDebugMode) {
        debugPrint('🎭 Mock transkript başlatılıyor...');
        debugPrint('📁 Audio dosyası: $audioPath');
      }

      await Future.delayed(Duration(seconds: 2)); // Simüle edilmiş işlem süresi

      if (kDebugMode) {
        debugPrint('✅ Mock transkript tamamlandı');
      }

      return TranscriptResult(
        segments: [
          TranscriptSegment(
            start: 0.0,
            end: 10.0,
            text:
                'Merhaba, bu bir demo transkriptidir. OpenAI API kotası dolduğu için gerçek transkript oluşturulamıyor.',
            confidence: 0.95,
          ),
          TranscriptSegment(
            start: 10.0,
            end: 20.0,
            text:
                'Video dosyasından audio başarıyla çıkarıldı ve API\'ye gönderildi, ancak kotanız dolmuş.',
            confidence: 0.92,
          ),
          TranscriptSegment(
            start: 20.0,
            end: 30.0,
            text:
                'Çözüm için: 1) Yeni hesap açın 2) Kredi ekleyin 3) Farklı IP kullanın',
            confidence: 0.88,
          ),
        ],
        fullText:
            'Merhaba, bu bir demo transkriptidir. OpenAI API kotası dolduğu için gerçek transkript oluşturulamıyor. Video dosyasından audio başarıyla çıkarıldı ve API\'ye gönderildi, ancak kotanız dolmuş. Çözüm için: 1) Yeni hesap açın 2) Kredi ekleyin 3) Farklı IP kullanın',
        language: 'tr',
        duration: 30.0,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Mock transkript hatası: $e');
      }
      _lastError = 'Mock transkript hatası: $e';
      return null;
    }
  }

  // Test fonksiyonu - Whisper durumunu kontrol et
  Future<Map<String, dynamic>> testWhisperStatus() async {
    final status = <String, dynamic>{};

    try {
      if (kDebugMode) {
        debugPrint('🧪 Whisper test başlatılıyor...');
      }

      // Python kontrolü
      final pythonCommand = await _getPythonCommand();
      status['python_command'] = pythonCommand;
      status['python_available'] =
          pythonCommand != 'python3' || await _testPythonCommand(pythonCommand);

      // Whisper kütüphanesi kontrolü
      status['whisper_available'] = await _testWhisperLibrary(pythonCommand);

      // Model kontrolü
      status['model_available'] = await _testWhisperModel(pythonCommand);

      // Genel durum
      status['overall_status'] =
          status['python_available'] &&
          status['whisper_available'] &&
          status['model_available'];

      if (kDebugMode) {
        debugPrint('📊 Test sonuçları: $status');
      }

      return status;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Test hatası: $e');
      }
      status['error'] = e.toString();
      return status;
    }
  }

  // Python komutunu test et
  Future<bool> _testPythonCommand(String command) async {
    try {
      final result = await Process.run(command, ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  // Whisper kütüphanesini test et
  Future<bool> _testWhisperLibrary(String pythonCommand) async {
    try {
      final result = await Process.run(pythonCommand, [
        '-c',
        'import whisper; print("OK")',
      ]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  // Whisper modelini test et
  Future<bool> _testWhisperModel(String pythonCommand) async {
    try {
      final result = await Process.run(pythonCommand, [
        '-c',
        '''
import whisper
try:
    model = whisper.load_model("tiny")
    print("OK")
except:
    print("FAIL")
''',
      ]);
      return result.exitCode == 0 && result.stdout.toString().contains('OK');
    } catch (e) {
      return false;
    }
  }

  // Video dosyasını transkript et
  Future<TranscriptResult?> transcribeVideo(String videoPath) async {
    try {
      // Video'dan audio çıkar
      final audioPath = await _extractAudioFromVideo(videoPath);
      if (audioPath == null) {
        _lastError = 'Video\'dan audio çıkarılamadı';
        return null;
      }

      // Audio'yu transkript et
      final result = await transcribeAudio(audioPath);

      // Geçici audio dosyasını sil
      try {
        await File(audioPath).delete();
      } catch (e) {
        // Silme hatası önemli değil
      }

      return result;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  // Video'dan audio çıkar (Android native + FFmpeg hibrit)
  Future<String?> _extractAudioFromVideo(String videoPath) async {
    try {
      if (kDebugMode) {
        debugPrint('🎬 Video işleme başlatılıyor...');
        debugPrint('📁 Video dosyası: $videoPath');
      }

      // Önce dosyanın zaten audio olup olmadığını kontrol et
      if (await _isAudioFile(videoPath)) {
        if (kDebugMode) {
          debugPrint('✅ Dosya zaten audio formatında, direkt kullanılıyor');
        }
        return videoPath;
      }

      if (kDebugMode) {
        debugPrint('🔧 Video dosyası, audio çıkarılıyor...');
      }

      // Android'de önce FFmpeg'i dene
      bool ffmpegAvailable = false;
      try {
        final ffmpegCheck = await Process.run('ffmpeg', ['-version']);
        ffmpegAvailable = ffmpegCheck.exitCode == 0;
        if (kDebugMode) {
          debugPrint(
            '🔍 FFmpeg durumu: ${ffmpegAvailable ? "Mevcut" : "Bulunamadı"}',
          );
        }
      } catch (e) {
        ffmpegAvailable = false;
        if (kDebugMode) {
          debugPrint('❌ FFmpeg kontrol hatası: $e');
        }
      }

      if (ffmpegAvailable) {
        if (kDebugMode) {
          debugPrint('🎯 FFmpeg ile audio çıkarılıyor...');
        }
        return await _extractAudioWithFFmpeg(videoPath);
      } else {
        if (kDebugMode) {
          debugPrint('🎯 Android native video işleme deneniyor...');
        }
        return await _extractAudioWithAndroidNative(videoPath);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Video işleme genel hatası: $e');
      }
      _lastError = 'Audio çıkarma hatası: $e';
      return null;
    }
  }

  // FFmpeg ile audio çıkar
  Future<String?> _extractAudioWithFFmpeg(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final audioPath = '${tempDir.path}/extracted_audio.wav';

      if (kDebugMode) {
        debugPrint('🎯 FFmpeg komutu çalıştırılıyor...');
        debugPrint('📄 Çıktı dosyası: $audioPath');
      }

      final result = await Process.run('ffmpeg', [
        '-i', videoPath,
        '-vn', // Video stream'i kaldır
        '-acodec', 'pcm_s16le', // 16-bit PCM
        '-ar', '16000', // 16kHz sample rate
        '-ac', '1', // Mono
        '-y', // Overwrite
        audioPath,
      ]);

      if (kDebugMode) {
        debugPrint('📊 FFmpeg sonucu:');
        debugPrint('   Exit Code: ${result.exitCode}');
        debugPrint('   Stdout: ${result.stdout.toString().trim()}');
        debugPrint('   Stderr: ${result.stderr.toString().trim()}');
      }

      if (result.exitCode == 0) {
        final audioFile = File(audioPath);
        if (await audioFile.exists()) {
          if (kDebugMode) {
            debugPrint('✅ FFmpeg ile audio başarıyla çıkarıldı');
          }
          return audioPath;
        }
      }

      if (kDebugMode) {
        debugPrint('❌ FFmpeg başarısız: ${result.stderr}');
      }
      _lastError = 'FFmpeg hatası: ${result.stderr}';
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FFmpeg exception: $e');
      }
      _lastError = 'FFmpeg hatası: $e';
      return null;
    }
  }

  // Android native MediaCodec ile audio çıkar
  Future<String?> _extractAudioWithAndroidNative(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final audioPath = '${tempDir.path}/extracted_audio.wav';

      if (kDebugMode) {
        debugPrint('🎯 Android native video işleme deneniyor...');
        debugPrint('📄 Geçici audio dosyası: $audioPath');
      }

      // Platform channel kullanarak native Android kodu çağır
      const platform = MethodChannel('com.example.lumina/video_processor');

      try {
        if (kDebugMode) {
          debugPrint('📱 Platform channel çağrılıyor: extractAudioFromVideo');
        }

        // Önce video'dan audio çıkar
        final extractResult = await platform.invokeMethod(
          'extractAudioFromVideo',
          {'videoPath': videoPath, 'outputPath': audioPath},
        );

        if (kDebugMode) {
          debugPrint('📊 Extract sonucu: $extractResult');
        }

        if (extractResult == true) {
          // Audio başarıyla çıkarıldı, WAV formatına dönüştür
          final wavPath = '${tempDir.path}/extracted_audio_final.wav';

          if (kDebugMode) {
            debugPrint('🔄 WAV dönüşümü yapılıyor...');
            debugPrint('📄 WAV dosyası: $wavPath');
          }

          final convertResult = await platform.invokeMethod('convertToWav', {
            'inputPath': audioPath,
            'outputPath': wavPath,
          });

          if (kDebugMode) {
            debugPrint('📊 Convert sonucu: $convertResult');
          }

          if (convertResult == true) {
            final wavFile = File(wavPath);
            if (await wavFile.exists()) {
              if (kDebugMode) {
                debugPrint('✅ Android native ile audio başarıyla çıkarıldı');
              }
              return wavPath;
            } else {
              if (kDebugMode) {
                debugPrint('❌ WAV dosyası bulunamadı: $wavPath');
              }
            }
          } else {
            if (kDebugMode) {
              debugPrint('❌ WAV dönüşümü başarısız');
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint('❌ Audio çıkarma başarısız');
          }
        }

        _lastError = 'Android native video işleme başarısız';
        return null;
      } on PlatformException catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Platform channel hatası: ${e.message}');
        }
        _lastError = 'Platform channel hatası: ${e.message}';
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Android native video işleme exception: $e');
      }
      _lastError = 'Android native video işleme hatası: $e';
      return null;
    }
  }

  // Dosyanın audio olup olmadığını kontrol et
  Future<bool> _isAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final extension = filePath.split('.').last.toLowerCase();
      final audioExtensions = [
        'mp3',
        'wav',
        'm4a',
        'aac',
        'ogg',
        'flac',
        'wma',
      ];

      return audioExtensions.contains(extension);
    } catch (e) {
      return false;
    }
  }

  // Whisper JSON çıktısını parse et
  List<TranscriptSegment> _parseWhisperJson(Map<String, dynamic> jsonData) {
    final segments = <TranscriptSegment>[];
    final segmentsData = jsonData['segments'] as List<dynamic>? ?? [];

    for (final segmentData in segmentsData) {
      final start = segmentData['start']?.toDouble() ?? 0.0;
      final end = segmentData['end']?.toDouble() ?? 0.0;
      final text = segmentData['text']?.toString() ?? '';

      segments.add(
        TranscriptSegment(
          start: start,
          end: end,
          text: text.trim(),
          confidence: 0.9, // Varsayılan confidence
        ),
      );
    }

    return segments;
  }

  // ElevenLabs API yanıtını parse et
  TranscriptResult _parseElevenLabsResponse(Map<String, dynamic> jsonData) {
    final segments = <TranscriptSegment>[];
    final words = jsonData['words'] as List<dynamic>? ?? [];

    // Words'den segmentler oluştur
    String currentSegmentText = '';
    double currentStart = 0.0;
    double currentEnd = 0.0;

    for (final wordData in words) {
      final word = wordData['text']?.toString() ?? '';
      final start = wordData['start']?.toDouble() ?? 0.0;
      final end = wordData['end']?.toDouble() ?? 0.0;
      final type = wordData['type']?.toString() ?? 'word';

      // Sadece kelimeleri işle, spacing ve audio_event'leri atla
      if (type == 'word') {
        if (currentSegmentText.isEmpty) {
          currentStart = start;
        }
        currentSegmentText += word;
        currentEnd = end;
      } else if (type == 'spacing' && currentSegmentText.isNotEmpty) {
        currentSegmentText += ' ';
      }

      // Segment'i tamamla (5 saniye veya daha uzun)
      if (currentEnd - currentStart >= 5.0 &&
          currentSegmentText.trim().isNotEmpty) {
        segments.add(
          TranscriptSegment(
            start: currentStart,
            end: currentEnd,
            text: currentSegmentText.trim(),
            confidence: 0.9,
          ),
        );
        currentSegmentText = '';
        currentStart = 0.0;
        currentEnd = 0.0;
      }
    }

    // Son segment'i ekle
    if (currentSegmentText.trim().isNotEmpty) {
      segments.add(
        TranscriptSegment(
          start: currentStart,
          end: currentEnd,
          text: currentSegmentText.trim(),
          confidence: 0.9,
        ),
      );
    }

    return TranscriptResult(
      segments: segments,
      fullText: jsonData['text'] ?? '',
      language: jsonData['language_code'] ?? 'tr',
      duration: segments.isNotEmpty ? segments.last.end : 0.0,
    );
  }

  // Mevcut mod bilgisini al
  String getModeInfo() {
    switch (_currentMode) {
      case WhisperMode.local:
        return 'Yerel Whisper (Offline)';
      case WhisperMode.api:
        return _getApiKey().isNotEmpty ? 'ElevenLabs API' : 'Mock Servis';
      case WhisperMode.auto:
        return 'Otomatik Seçim';
    }
  }
}

// TranscriptResult ve TranscriptSegment sınıfları
class TranscriptResult {
  final List<TranscriptSegment> segments;
  final String fullText;
  final String language;
  final double duration;

  const TranscriptResult({
    required this.segments,
    required this.fullText,
    required this.language,
    required this.duration,
  });
}

class TranscriptSegment {
  final double start;
  final double end;
  final String text;
  final double confidence;

  const TranscriptSegment({
    required this.start,
    required this.end,
    required this.text,
    required this.confidence,
  });
}
