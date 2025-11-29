import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:developer' as developer;

class OpenAITTSService {
  static const String _baseUrl = 'https://api.openai.com/v1/audio/speech';

  //   GÜVENLİ: API anahtarını doğrudan .env dosyasından al
  static String get _apiKey {
    final key = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (key.isEmpty || key == 'YOUR_OPENAI_API_KEY_HERE') {
      throw Exception(
        'OpenAI API anahtarı yapılandırılmamış! .env dosyasını kontrol edin.',
      );
    }
    return key;
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  // OpenAI TTS ses seçenekleri
  static const List<String> availableVoices = [
    'alloy', // Çok amaçlı, dengeli
    'echo', // Derin, güçlü
    'fable', // Hikaye anlatımı için
    'onyx', // Ciddi, profesyonel
    'nova', // Genç, enerjik
    'shimmer', // Yumuşak, nazik
  ];

  // Metni sese dönüştür
  Future<String> synthesizeSpeech({
    required String text,
    String voice = 'alloy', // Varsayılan ses
    String model = 'tts-1', // Model seçimi
    double speed = 1.0, // Hız (0.25 - 4.0)
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'input': text,
          'voice': voice,
          'speed': speed,
        }),
      );

      if (response.statusCode == 200) {
        // Ses dosyasını geçici olarak kaydet
        final tempDir = Directory.systemTemp;
        final tempFile = File(
          '${tempDir.path}/openai_audio_${DateTime.now().millisecondsSinceEpoch}.mp3',
        );
        await tempFile.writeAsBytes(response.bodyBytes);

        return tempFile.path;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'OpenAI TTS API hatası: ${response.statusCode} - ${errorBody['error']['message']}',
        );
      }
    } catch (e) {
      developer.log('OpenAI TTS hatası: $e', name: 'OpenAITTSService');
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

      developer.log('OpenAI ses dosyası oynatılıyor', name: 'OpenAITTSService');
    } catch (e) {
      developer.log('OpenAI ses oynatma hatası: $e', name: 'OpenAITTSService');
      throw Exception('Ses oynatılamadı: $e');
    }
  }

  // Oynatmayı durdur
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      developer.log('OpenAI durdurma hatası: $e', name: 'OpenAITTSService');
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
