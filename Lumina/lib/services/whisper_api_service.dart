import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WhisperApiService extends ChangeNotifier {
  static final WhisperApiService _instance = WhisperApiService._internal();
  factory WhisperApiService() => _instance;
  WhisperApiService._internal();

  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _lastError;

  // Whisper API endpoint (ElevenLabs)
  static const String _apiUrl =
      'https://api.elevenlabs.io/v1/speech-to-text';
  static const String _model = 'scribe_v1';

  String? get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;

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
      // API anahtarını kontrol et
      final apiKey = _getApiKey();
      if (apiKey.isEmpty) {
        _lastError = 'OpenAI API anahtarı gerekli';
        return false;
      }

      _isInitialized = true;
      _lastError = null;
      notifyListeners();

      return true;
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

  // API anahtarını al
  String _getApiKey() {
    // .env dosyasından ElevenLabs API anahtarını al
    try {
      final envApiKey = dotenv.env['ELEVENLABS_API_KEY'];
      if (envApiKey != null &&
          envApiKey.isNotEmpty &&
          envApiKey != 'YOUR_ELEVENLABS_API_KEY_HERE') {
        return envApiKey;
      }
    } catch (e) {
      // Hata durumunda boş döndür
    }
    return '';
  }

  // Audio dosyasını transkript et (ElevenLabs API ile)
  Future<TranscriptResult?> transcribeAudio(String audioPath) async {
    final initialized = await _ensureInitialized();
    if (!initialized) {
      _lastError = 'Whisper servisi başlatılamadı';
      return null;
    }

    try {
      final apiKey = _getApiKey();
      if (apiKey.isEmpty) {
        return await _transcribeWithFreeApi(audioPath);
      }

      return await _transcribeWithElevenLabsApi(audioPath, apiKey);
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  // ElevenLabs API ile transkript
  Future<TranscriptResult?> _transcribeWithElevenLabsApi(
    String audioPath,
    String apiKey,
  ) async {
    try {
      final audioFile = File(audioPath);
      final audioBytes = await audioFile.readAsBytes();

      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.headers['xi-api-key'] = apiKey;
      request.fields['model_id'] = _model;
      request.fields['language_code'] = 'tr';

      request.files.add(
        http.MultipartFile.fromBytes('file', audioBytes, filename: 'audio.wav'),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseBody);
        return _parseElevenLabsResponse(jsonData);
      } else {
        _lastError =
            'ElevenLabs API hatası: ${response.statusCode} - $responseBody';
        return null;
      }
    } catch (e) {
      _lastError = 'ElevenLabs API hatası: $e';
      return null;
    }
  }

  // Ücretsiz alternatif API ile transkript
  Future<TranscriptResult?> _transcribeWithFreeApi(String audioPath) async {
    try {
      // Basit mock response - gerçek uygulamada ücretsiz API kullanılabilir
      await Future.delayed(Duration(seconds: 2)); // Simüle edilmiş işlem süresi

      return TranscriptResult(
        segments: [
          TranscriptSegment(
            start: 0.0,
            end: 5.0,
            text:
                'Bu bir test transkriptidir. Gerçek API anahtarı ile OpenAI Whisper kullanabilirsiniz.',
            confidence: 0.9,
          ),
        ],
        fullText:
            'Bu bir test transkriptidir. Gerçek API anahtarı ile OpenAI Whisper kullanabilirsiniz.',
        language: 'tr',
        duration: 5.0,
      );
    } catch (e) {
      _lastError = 'Ücretsiz API hatası: $e';
      return null;
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

  // Video'dan audio çıkar (FFmpeg kullanarak)
  Future<String?> _extractAudioFromVideo(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final audioPath = '${tempDir.path}/extracted_audio.wav';

      // FFmpeg komutu çalıştır
      final result = await Process.run('ffmpeg', [
        '-i', videoPath,
        '-vn', // Video stream'i kaldır
        '-acodec', 'pcm_s16le', // 16-bit PCM
        '-ar', '16000', // 16kHz sample rate
        '-ac', '1', // Mono
        '-y', // Overwrite
        audioPath,
      ]);

      if (result.exitCode == 0) {
        return audioPath;
      } else {
        _lastError = 'FFmpeg hatası: ${result.stderr}';
        return null;
      }
    } catch (e) {
      _lastError = 'Audio çıkarma hatası: $e';
      return null;
    }
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
