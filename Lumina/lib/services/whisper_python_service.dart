import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class WhisperPythonService extends ChangeNotifier {
  static final WhisperPythonService _instance =
      WhisperPythonService._internal();
  factory WhisperPythonService() => _instance;
  WhisperPythonService._internal();

  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _lastError;
  String? _pythonScriptPath;

  String? get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;

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
        # Whisper modelini yükle (küçük model)
        model = whisper.load_model("tiny")
        
        # Audio dosyasını transkript et
        result = model.transcribe(audio_path, language="tr")
        
        # Sonuçları JSON formatında kaydet
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
        
        return True
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <audio_path> <output_path>", file=sys.stderr)
        sys.exit(1)
    
    audio_path = sys.argv[1]
    output_path = sys.argv[2]
    
    success = transcribe_audio(audio_path, output_path)
    sys.exit(0 if success else 1)
''';

    await scriptFile.writeAsString(scriptContent);
    return scriptPath;
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
      // Python script'ini oluştur
      _pythonScriptPath = await _createPythonScript();

      // Android için basit Python kontrolü
      final pythonCheck = await Process.run('python3', ['--version']);
      if (pythonCheck.exitCode != 0) {
        _lastError = 'Python3 bulunamadı - Android için uygun değil';
        return false;
      }

      // Whisper kütüphanesini kontrol et
      final whisperCheck = await Process.run('python3', [
        '-c', 'import whisper; print("Whisper available")'
      ]);

      if (whisperCheck.exitCode != 0) {
        // Whisper kütüphanesini yükle
        if (kDebugMode) {
          debugPrint('Whisper kütüphanesi yükleniyor...');
        }

        final installResult = await Process.run('pip3', [
          'install',
          'openai-whisper',
        ]);

        if (installResult.exitCode != 0) {
          _lastError =
              'Whisper kütüphanesi yüklenemedi: ${installResult.stderr}';
          return false;
        }
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

      // Çıktı dosyası için geçici dosya oluştur
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/whisper_output.json';

      // Python script'ini çalıştır
      final result = await Process.run('python3', [
        _pythonScriptPath!, audioPath, outputPath,
      ]);

      if (result.exitCode == 0) {
        // JSON çıktısını oku
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          final jsonContent = await outputFile.readAsString();
          final jsonData = json.decode(jsonContent);

          // JSON'dan TranscriptResult oluştur
          final segments = _parseWhisperJson(jsonData);
          final fullText = jsonData['text'] ?? '';
          final language = jsonData['language'] ?? 'tr';
          final duration = jsonData.get('duration', 0.0);

          return TranscriptResult(
            segments: segments,
            fullText: fullText,
            language: language,
            duration: duration.toDouble(),
          );
        }
      } else {
        _lastError = 'Python script hatası: ${result.stderr}';
      }

      return null;
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) {
        debugPrint('Whisper transkript hatası: $e');
      }
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

  // dispose metodu gerekli değil - ChangeNotifier'dan geliyor
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
