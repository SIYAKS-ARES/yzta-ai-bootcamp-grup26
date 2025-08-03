import 'text_to_speech_service.dart';
import 'firebase_tts_service.dart';
import 'elevenlabs_tts_service.dart';
import 'openai_tts_service.dart';
import 'gemini_tts_service.dart';
import 'dart:developer' as developer;

enum TTSProvider {
  device, // Cihaz üzerinde (mevcut)
  cloud, // Firebase Cloud (mevcut)
  elevenlabs, // ElevenLabs API (deneysel)
  openai, // OpenAI TTS API (deneysel)
  gemini, // Gemini TTS API (deneysel)
}

class AdvancedTTSService {
  final TextToSpeechService _deviceTTS = TextToSpeechService();
  final FirebaseTTSService _cloudTTS = FirebaseTTSService();
  final ElevenLabsTTSService _elevenLabsTTS = ElevenLabsTTSService();
  final OpenAITTSService _openAITTS = OpenAITTSService();
  final GeminiTTSService _geminiTTS = GeminiTTSService();

  TTSProvider _currentProvider = TTSProvider.device;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isProcessing = false;

  // Getter'lar
  TTSProvider get currentProvider => _currentProvider;
  bool get isPlaying => _isPlaying;
  bool get isProcessing => _isProcessing;

  // TTS sağlayıcısını değiştir
  void setProvider(TTSProvider provider) {
    _currentProvider = provider;
    developer.log(
      'TTS sağlayıcısı değiştirildi: $provider',
      name: 'AdvancedTTSService',
    );
  }

  // Servisi başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _deviceTTS.initialize();
      _isInitialized = true;
      developer.log(
        'Gelişmiş TTS servisi başlatıldı',
        name: 'AdvancedTTSService',
      );
    } catch (e) {
      developer.log(
        'TTS servisi başlatma hatası: $e',
        name: 'AdvancedTTSService',
      );
      throw Exception('TTS servisi başlatılamadı: $e');
    }
  }

  // Metni sese dönüştür ve oynat
  Future<void> speakText(String text, {String? userId}) async {
    if (!_isInitialized) await initialize();

    try {
      await stopSpeaking();

      switch (_currentProvider) {
        case TTSProvider.device:
          await _speakWithDevice(text);
          break;
        case TTSProvider.cloud:
          throw Exception('Firebase Cloud TTS devre dışı - simüle edilmiş');
        case TTSProvider.elevenlabs:
          await _speakWithElevenLabs(text);
        case TTSProvider.openai:
          throw Exception(
            'OpenAI TTS devre dışı - API anahtarı yapılandırılmamış',
          );
        case TTSProvider.gemini:
          throw Exception(
            'Gemini TTS devre dışı - Google Cloud TTS API aktif değil',
          );
      }
    } catch (e) {
      developer.log('Metin okuma hatası: $e', name: 'AdvancedTTSService');
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

  // ElevenLabs TTS
  Future<void> _speakWithElevenLabs(String text) async {
    try {
      _isProcessing = true;
      final audioPath = await _elevenLabsTTS.synthesizeSpeech(
        text: text,
        voiceId: ElevenLabsTTSService.turkishVoices['female_1']!,
      );

      _isProcessing = false;
      _isPlaying = true;
      await _elevenLabsTTS.playAudio(audioPath);
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
      await _elevenLabsTTS.stopAudio();
      await _openAITTS.stopAudio();
      await _geminiTTS.stopAudio();
    } catch (e) {
      developer.log('Durdurma hatası: $e', name: 'AdvancedTTSService');
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
    } catch (e) {
      developer.log(
        'Ses ayarları güncelleme hatası: $e',
        name: 'AdvancedTTSService',
      );
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
    } catch (e) {
      developer.log('Task silme hatası: $e', name: 'AdvancedTTSService');
      throw Exception('Task silinemedi: $e');
    }
  }

  // Debug bilgileri
  Future<void> debugInfo() async {
    developer.log(
      '=== Gelişmiş TTS Debug Bilgileri ===',
      name: 'AdvancedTTSService',
    );
    developer.log(
      'Mevcut sağlayıcı: $_currentProvider',
      name: 'AdvancedTTSService',
    );
    developer.log('Oynatılıyor: $_isPlaying', name: 'AdvancedTTSService');
    developer.log('İşleniyor: $_isProcessing', name: 'AdvancedTTSService');

    await _deviceTTS.debugTTS();
  }

  // Servisi temizle
  void dispose() {
    _deviceTTS.dispose();
    _cloudTTS.dispose();
    _elevenLabsTTS.dispose();
    _openAITTS.dispose();
    _geminiTTS.dispose();
  }
}
