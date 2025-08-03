import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../api.dart';
// import '../frb_generated.dart';

class WhisperService extends ChangeNotifier {
  static final WhisperService _instance = WhisperService._internal();
  factory WhisperService() => _instance;
  WhisperService._internal();

  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _lastError;

  String? get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;

  // API kullanarak başlatma
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
      // Model dosyasının yolunu belirle
      final modelPath = await _getModelPath();

      // API ile Whisper'ı başlat
      final initialized = await initializeWhisper(modelPath: modelPath);

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

  Future<bool> initialize() async {
    return await _ensureInitialized();
  }

  Future<String> _getModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDir.path}/whisper_models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return '${modelDir.path}/ggml-tiny.bin';
  }

  Future<TranscriptResult?> transcribeVideo(String videoPath) async {
    // API kullanarak transkript
    final initialized = await _ensureInitialized();
    if (!initialized) {
      _lastError = 'Whisper servisi başlatılamadı';
      return null;
    }

    try {
      final modelPath = await _getModelPath();

      // Video dosyasının varlığını kontrol et
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        _lastError = 'Video dosyası bulunamadı: $videoPath';
        return null;
      }

      // Video dosya boyutunu kontrol et
      final fileSize = await videoFile.length();
      if (fileSize > 100 * 1024 * 1024) {
        // 100MB limit
        _lastError = 'Video dosyası çok büyük (max 100MB)';
        return null;
      }

      final result = await transcribeVideoWithWhisper(
        modelPath: modelPath,
        videoPath: videoPath,
      );

      _lastError = null;
      return result;
    } catch (e) {
      _lastError = e.toString();
      print('Whisper transkript hatası: $e');
      return null;
    }
  }

  Future<TranscriptResult?> transcribeAudio(String audioPath) async {
    // API kullanarak transkript
    final initialized = await _ensureInitialized();
    if (!initialized) {
      _lastError = 'Whisper servisi başlatılamadı';
      return null;
    }

    try {
      final modelPath = await _getModelPath();
      final result = await transcribeAudioWithWhisper(
        modelPath: modelPath,
        audioPath: audioPath,
      );

      _lastError = null;
      return result;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  @override
  void dispose() {
    // Cleanup
    super.dispose();
  }
}
