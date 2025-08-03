import 'frb_generated.dart';
import 'api.dart';
import 'package:flutter/foundation.dart';

class MockRsWhisperGptApi implements RsWhisperGptApi {
  @override
  Future<bool> crateApiInitializeWhisper({required String modelPath}) async {
    if (kDebugMode) {
      debugPrint('Mock: Whisper initialize edildi - $modelPath');
    }
    return true;
  }

  @override
  Future<TranscriptResult> crateApiTranscribeAudioWithWhisper({
    required String modelPath,
    required String audioPath,
  }) async {
    if (kDebugMode) {
      debugPrint('Mock: Audio transkript edildi - $audioPath');
    }
    return TranscriptResult(
      segments: [
        TranscriptSegment(
          start: 0.0,
          end: 5.0,
          text: 'Mock transkript: Bu bir test ses dosyasıdır.',
          confidence: 0.95,
        ),
      ],
      fullText: 'Mock transkript: Bu bir test ses dosyasıdır.',
      language: 'tr',
      duration: 5.0,
    );
  }

  @override
  Future<TranscriptResult> crateApiTranscribeVideoWithWhisper({
    required String modelPath,
    required String videoPath,
  }) async {
    if (kDebugMode) {
      debugPrint('Mock: Video transkript edildi - $videoPath');
    }
    return TranscriptResult(
      segments: [
        TranscriptSegment(
          start: 0.0,
          end: 10.0,
          text: 'Mock video transkript: Bu bir test video dosyasıdır.',
          confidence: 0.90,
        ),
      ],
      fullText: 'Mock video transkript: Bu bir test video dosyasıdır.',
      language: 'tr',
      duration: 10.0,
    );
  }
}
