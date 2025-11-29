import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiTTSService {
  //   GÜVENLİ: API anahtarını doğrudan .env dosyasından al
  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (key.isEmpty || key == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception(
        'Gemini API anahtarı yapılandırılmamış! .env dosyasını kontrol edin.',
      );
    }
    return key;
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  // Gemini TTS ses seçenekleri
  static const List<String> availableVoices = [
    'gemini-1.0-pro', // Ana model
  ];

  // Metni sese dönüştür (Gemini TTS henüz beta, alternatif yöntem)
  Future<String> synthesizeSpeech({
    required String text,
    String voice = 'gemini-1.0-pro',
    double speed = 1.0,
  }) async {
    try {
      // Gemini TTS henüz mevcut değil, Google Cloud TTS kullanıyoruz
      final url = Uri.parse(
        'https://texttospeech.googleapis.com/v1/text:synthesize?key=$_apiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'input': {'text': text},
          'voice': {
            'languageCode': 'tr-TR',
            'name': 'tr-TR-Wavenet-A', // Türkçe ses
            'ssmlGender': 'FEMALE',
          },
          'audioConfig': {
            'audioEncoding': 'MP3',
            'speakingRate': speed,
            'pitch': 0.0,
            'volumeGainDb': 0.0,
          },
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final audioContent = responseData['audioContent'];

        if (audioContent != null) {
          // Base64'ten decode et
          final audioBytes = base64Decode(audioContent);

          // Ses dosyasını geçici olarak kaydet
          final tempDir = Directory.systemTemp;
          final tempFile = File(
            '${tempDir.path}/gemini_audio_${DateTime.now().millisecondsSinceEpoch}.mp3',
          );
          await tempFile.writeAsBytes(audioBytes);

          return tempFile.path;
        } else {
          throw Exception('Ses içeriği alınamadı');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'Gemini TTS API hatası: ${response.statusCode} - ${errorBody['error']['message']}',
        );
      }
    } catch (e) {
      developer.log('Gemini TTS hatası: $e', name: 'GeminiTTSService');
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

      developer.log('Gemini ses dosyası oynatılıyor', name: 'GeminiTTSService');
    } catch (e) {
      developer.log('Gemini ses oynatma hatası: $e', name: 'GeminiTTSService');
      throw Exception('Ses oynatılamadı: $e');
    }
  }

  // Oynatmayı durdur
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      developer.log('Gemini durdurma hatası: $e', name: 'GeminiTTSService');
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
