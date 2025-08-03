import 'package:flutter/foundation.dart';
import 'whisper_hybrid_service.dart';

class WhisperService extends ChangeNotifier {
  static final WhisperService _instance = WhisperService._internal();
  factory WhisperService() => _instance;
  WhisperService._internal();

  final WhisperHybridService _hybridService = WhisperHybridService();
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _lastError;

  String? get lastError => _lastError ?? _hybridService.lastError;
  bool get isInitialized => _isInitialized && _hybridService.isInitialized;
  bool get isInitializing => _isInitializing || _hybridService.isInitializing;

  // Whisper modu için getter
  WhisperMode get currentMode => _hybridService.currentMode;

  // API anahtarı için getter ve setter
  void setApiKey(String apiKey) => _hybridService.setApiKey(apiKey);
  String getModeInfo() => _hybridService.getModeInfo();

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
      // Hibrit servisi başlat
      final initialized = await _hybridService.initialize();

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

  Future<TranscriptResult?> transcribeVideo(String videoPath) async {
    final initialized = await _ensureInitialized();
    if (!initialized) {
      _lastError = 'Whisper servisi başlatılamadı';
      return null;
    }

    try {
      final result = await _hybridService.transcribeVideo(videoPath);
      _lastError = null;
      return result;
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) {
        debugPrint('Whisper transkript hatası: $e');
      }
      return null;
    }
  }

  Future<TranscriptResult?> transcribeAudio(String audioPath) async {
    final initialized = await _ensureInitialized();
    if (!initialized) {
      _lastError = 'Whisper servisi başlatılamadı';
      return null;
    }

    try {
      final result = await _hybridService.transcribeAudio(audioPath);
      _lastError = null;
      return result;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  // Test fonksiyonu
  Future<Map<String, dynamic>> testWhisperStatus() async {
    return await _hybridService.testWhisperStatus();
  }

  // dispose metodu gerekli değil - ChangeNotifier'dan geliyor
}
