import 'dart:io';
import 'text_to_speech_service.dart';
import 'firebase_tts_service.dart';
import 'dart:developer' as developer;

enum TTSMode {
  device, // Cihaz üzerinde (hızlı, düşük kalite)
  cloud, // Bulut (yavaş, yüksek kalite)
}

enum TTSQuality {
  fast, // Hızlı işlem
  quality, // Yüksek kalite
}

class HybridTTSService {
  final TextToSpeechService _deviceTTS = TextToSpeechService();
  final FirebaseTTSService _cloudTTS = FirebaseTTSService();

  TTSMode _currentMode = TTSMode.device;
  TTSQuality _currentQuality = TTSQuality.fast;
  bool _isInitialized = false;

  // Durum değişkenleri
  bool _isPlaying = false;
  bool _isProcessing = false;
  String? _currentTaskId;
  double _uploadProgress = 0.0;

  // Stream'ler
  Stream<bool> get isPlayingStream => Stream.value(_isPlaying);
  Stream<bool> get isProcessingStream => Stream.value(_isProcessing);
  Stream<double> get uploadProgressStream => Stream.value(_uploadProgress);

  // Getter'lar
  TTSMode get currentMode => _currentMode;
  TTSQuality get currentQuality => _currentQuality;
  bool get isPlaying => _isPlaying;
  bool get isProcessing => _isProcessing;
  String? get currentTaskId => _currentTaskId;

  // TTS modunu değiştir
  void setMode(TTSMode mode) {
    _currentMode = mode;
    developer.log('TTS modu değiştirildi: $mode', name: 'HybridTTSService');
  }

  // TTS kalitesini değiştir
  void setQuality(TTSQuality quality) {
    _currentQuality = quality;
    developer.log(
      'TTS kalitesi değiştirildi: $quality',
      name: 'HybridTTSService',
    );
  }

  // Servisi başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _deviceTTS.initialize();
      _isInitialized = true;
      developer.log('Hibrit TTS servisi başlatıldı', name: 'HybridTTSService');
    } catch (e) {
      developer.log(
        'TTS servisi başlatma hatası: $e',
        name: 'HybridTTSService',
      );
      throw Exception('TTS servisi başlatılamadı: $e');
    }
  }

  // Metni sese dönüştür ve oynat
  Future<void> speakText(String text, {String? userId}) async {
    if (!_isInitialized) await initialize();

    try {
      // Mevcut oynatmayı durdur
      await stopSpeaking();

      switch (_currentMode) {
        case TTSMode.device:
          await _speakWithDevice(text);
          break;
        case TTSMode.cloud:
          if (userId != null) {
            await _speakWithCloud(text, userId);
          } else {
            throw Exception('Cloud TTS için kullanıcı ID gerekli');
          }
          break;
      }
    } catch (e) {
      developer.log('Metin okuma hatası: $e', name: 'HybridTTSService');
      throw Exception('Metin okunamadı: $e');
    }
  }

  // Cihaz üzerinde TTS
  Future<void> _speakWithDevice(String text) async {
    try {
      _isPlaying = true;
      await _deviceTTS.speakText(text);
    } catch (e) {
      _isPlaying = false;
      rethrow;
    }
  }

  // Bulut TTS
  Future<void> _speakWithCloud(String text, String userId) async {
    try {
      _isProcessing = true;
      _uploadProgress = 0.0;

      // Metni geçici dosya olarak kaydet
      final tempFile = await _createTempTextFile(text);

      // Cloud TTS ile işle
      final taskId = await _cloudTTS.uploadFileAndCreateTask(
        file: tempFile,
        userId: userId,
      );

      if (taskId != null) {
        _currentTaskId = taskId;
        _uploadProgress = 1.0;

        // Task durumunu dinle
        _cloudTTS.getTaskStream(taskId).listen((task) {
          if (task.status == 'completed' && task.audioUrl != null) {
            _playCloudAudio(task.audioUrl!);
          } else if (task.status == 'failed') {
            _isProcessing = false;
            throw Exception(task.errorMessage ?? 'Bilinmeyen hata');
          }
        });
      }
    } catch (e) {
      _isProcessing = false;
      rethrow;
    }
  }

  // Bulut ses dosyasını oynat
  Future<void> _playCloudAudio(String audioUrl) async {
    try {
      _isProcessing = false;
      _isPlaying = true;
      await _cloudTTS.playAudio(audioUrl);
    } catch (e) {
      _isPlaying = false;
      rethrow;
    }
  }

  // Ses dosyasını oynat (public method)
  Future<void> playAudio(String audioUrl) async {
    try {
      if (_isPlaying) {
        await stopSpeaking();
      }
      _isPlaying = true;
      await _cloudTTS.playAudio(audioUrl);
    } catch (e) {
      _isPlaying = false;
      rethrow;
    }
  }

  // Geçici metin dosyası oluştur
  Future<File> _createTempTextFile(String text) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File(
      '${tempDir.path}/temp_text_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    await tempFile.writeAsString(text);
    return tempFile;
  }

  // Dosyayı sese dönüştür
  Future<void> processFile(File file, {String? userId}) async {
    if (!_isInitialized) await initialize();

    try {
      switch (_currentMode) {
        case TTSMode.device:
          await _processFileWithDevice(file);
          break;
        case TTSMode.cloud:
          if (userId != null) {
            await _processFileWithCloud(file, userId);
          } else {
            throw Exception('Cloud TTS için kullanıcı ID gerekli');
          }
          break;
      }
    } catch (e) {
      developer.log('Dosya işleme hatası: $e', name: 'HybridTTSService');
      throw Exception('Dosya işlenemedi: $e');
    }
  }

  // Cihaz üzerinde dosya işleme
  Future<void> _processFileWithDevice(File file) async {
    try {
      final text = await _deviceTTS.extractTextFromFile(file.path);
      if (text.isNotEmpty) {
        await _speakWithDevice(text);
      } else {
        throw Exception('Dosyadan metin çıkarılamadı');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Bulut dosya işleme
  Future<void> _processFileWithCloud(File file, String userId) async {
    try {
      _isProcessing = true;
      _uploadProgress = 0.0;

      final taskId = await _cloudTTS.uploadFileAndCreateTask(
        file: file,
        userId: userId,
      );

      if (taskId != null) {
        _currentTaskId = taskId;
        _uploadProgress = 1.0;

        // Task durumunu dinle
        _cloudTTS.getTaskStream(taskId).listen((task) {
          if (task.status == 'completed' && task.audioUrl != null) {
            _playCloudAudio(task.audioUrl!);
          } else if (task.status == 'failed') {
            _isProcessing = false;
            throw Exception(task.errorMessage ?? 'Bilinmeyen hata');
          }
        });
      }
    } catch (e) {
      _isProcessing = false;
      rethrow;
    }
  }

  // Oynatmayı durdur
  Future<void> stopSpeaking() async {
    try {
      _isPlaying = false;
      _isProcessing = false;

      await _deviceTTS.stopSpeaking();
      await _cloudTTS.stopAudio();
    } catch (e) {
      developer.log('Durdurma hatası: $e', name: 'HybridTTSService');
    }
  }

  // Oynatmayı duraklat
  Future<void> pauseSpeaking() async {
    try {
      if (_currentMode == TTSMode.cloud) {
        await _cloudTTS.pauseAudio();
      }
      _isPlaying = false;
    } catch (e) {
      developer.log('Duraklatma hatası: $e', name: 'HybridTTSService');
    }
  }

  // Oynatmayı devam ettir
  Future<void> resumeSpeaking() async {
    try {
      if (_currentMode == TTSMode.cloud) {
        await _cloudTTS.resumeAudio();
        _isPlaying = true;
      }
    } catch (e) {
      developer.log('Devam ettirme hatası: $e', name: 'HybridTTSService');
    }
  }

  // Ses pozisyonunu ayarla
  Future<void> seekTo(Duration position) async {
    try {
      if (_currentMode == TTSMode.cloud) {
        await _cloudTTS.seekAudio(position);
      }
    } catch (e) {
      developer.log('Pozisyon ayarlama hatası: $e', name: 'HybridTTSService');
    }
  }

  // Kullanıcı task'larını getir
  Stream<List<Task>> getUserTasks(String userId) {
    return _cloudTTS.getUserTasks(userId);
  }

  // Task'ı sil
  Future<void> deleteTask(String taskId) async {
    try {
      await _cloudTTS.deleteTask(taskId);
      if (_currentTaskId == taskId) {
        _currentTaskId = null;
      }
    } catch (e) {
      developer.log('Task silme hatası: $e', name: 'HybridTTSService');
      throw Exception('Task silinemedi: $e');
    }
  }

  // Ses ayarlarını güncelle
  Future<void> updateAudioSettings({
    double? speechRate,
    double? volume,
    double? pitch,
  }) async {
    try {
      if (speechRate != null) {
        await _deviceTTS.setSpeechRate(speechRate);
      }
      if (volume != null) {
        await _deviceTTS.setVolume(volume);
      }
      if (pitch != null) {
        // Device TTS'de pitch ayarı yok, sadece log
        developer.log('Pitch ayarı: $pitch', name: 'HybridTTSService');
      }
    } catch (e) {
      developer.log(
        'Ses ayarları güncelleme hatası: $e',
        name: 'HybridTTSService',
      );
    }
  }

  // Debug bilgileri
  Future<void> debugInfo() async {
    developer.log(
      '=== Hibrit TTS Debug Bilgileri ===',
      name: 'HybridTTSService',
    );
    developer.log('Mevcut mod: $_currentMode', name: 'HybridTTSService');
    developer.log('Mevcut kalite: $_currentQuality', name: 'HybridTTSService');
    developer.log('Oynatılıyor: $_isPlaying', name: 'HybridTTSService');
    developer.log('İşleniyor: $_isProcessing', name: 'HybridTTSService');
    developer.log('Mevcut task ID: $_currentTaskId', name: 'HybridTTSService');
    developer.log(
      'Upload progress: $_uploadProgress',
      name: 'HybridTTSService',
    );

    await _deviceTTS.debugTTS();
  }

  // Servisi temizle
  void dispose() {
    _deviceTTS.dispose();
    _cloudTTS.dispose();
  }
}
