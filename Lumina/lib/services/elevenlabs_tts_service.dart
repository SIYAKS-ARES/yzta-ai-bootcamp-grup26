import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ElevenLabsTTSService {
  static const String _baseUrl = 'https://api.elevenlabs.io/v1';

  // 🔒 GÜVENLİ: API anahtarını doğrudan .env dosyasından al
  static String get _apiKey {
    final key = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
    if (key.isEmpty || key == 'YOUR_ELEVENLABS_API_KEY_HERE') {
      throw Exception(
        'ElevenLabs API anahtarı yapılandırılmamış! .env dosyasını kontrol edin.',
      );
    }
    return key;
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  // Türkçe ses ID'leri (ElevenLabs'te mevcut olanlar)
  static const Map<String, String> turkishVoices = {
    'female_1': '21m00Tcm4TlvDq8ikWAM', // Rachel - Türkçe benzeri
    'female_2': 'EXAVITQu4vr4xnSDxMaL', // Bella - Doğal ses
    'male_1': 'VR6AewLTigWG4xSOukaG', // Arnold - Erkek ses
  };

  // Metni sese dönüştür
  Future<String> synthesizeSpeech({
    required String text,
    String voiceId = '21m00Tcm4TlvDq8ikWAM', // Varsayılan Türkçe benzeri ses
    double stability = 0.5,
    double similarityBoost = 0.75,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/text-to-speech/$voiceId');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'audio/mpeg',
          'Content-Type': 'application/json',
          'xi-api-key': _apiKey,
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_multilingual_v2', // Çok dilli model
          'voice_settings': {
            'stability': stability,
            'similarity_boost': similarityBoost,
          },
        }),
      );

      if (response.statusCode == 200) {
        // Ses dosyasını geçici olarak kaydet
        final tempDir = Directory.systemTemp;
        final tempFile = File(
          '${tempDir.path}/elevenlabs_audio_${DateTime.now().millisecondsSinceEpoch}.mp3',
        );
        await tempFile.writeAsBytes(response.bodyBytes);

        return tempFile.path;
      } else {
        throw Exception(
          'ElevenLabs API hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      developer.log('ElevenLabs TTS hatası: $e', name: 'ElevenLabsTTSService');
      throw Exception('Ses sentezi başarısız: $e');
    }
  }

  // Ses dosyasını oynat
  Future<void> playAudio(String audioPath) async {
    try {
      if (_isPlaying) {
        await stopAudio();
      }

      await _audioPlayer.setFilePath(audioPath);
      await _audioPlayer.play();
      _isPlaying = true;

      developer.log(
        'ElevenLabs ses dosyası oynatılıyor',
        name: 'ElevenLabsTTSService',
      );
    } catch (e) {
      developer.log(
        'ElevenLabs ses oynatma hatası: $e',
        name: 'ElevenLabsTTSService',
      );
      throw Exception('Ses oynatılamadı: $e');
    }
  }

  // Oynatmayı durdur
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      developer.log(
        'ElevenLabs durdurma hatası: $e',
        name: 'ElevenLabsTTSService',
      );
    }
  }

  // Durum getter'ları
  bool get isPlaying => _isPlaying;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  // Servisi temizle
  void dispose() {
    _audioPlayer.dispose();
  }
}
