import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../api.dart';
import '../frb_generated.dart';

class WhisperService {
  static final WhisperService _instance = WhisperService._internal();
  factory WhisperService() => _instance;
  WhisperService._internal();

  RsWhisperGptApi? _rustService;
  bool _isInitialized = false;
  String? _lastError;

  String? get lastError => _lastError;

  Future<bool> initialize() async {
    try {
      // Model dosyasının yolunu belirle
      final modelPath = await _getModelPath();

      // Rust servisini başlat
      _rustService = RsWhisperGptApiImpl(
        handler: const SseHandler(),
        wire: RsWhisperGptWire(),
        generalizedFrbRustBinding: GeneralizedFrbRustBinding(),
        portManager: PortManager(),
      );

      // Whisper'ı başlat
      final initialized = await _rustService!.crateApiInitializeWhisper(
        modelPath: modelPath,
      );

      _isInitialized = initialized;
      _lastError = null;

      return initialized;
    } catch (e) {
      _lastError = e.toString();
      _isInitialized = false;
      return false;
    }
  }

  Future<String> _getModelPath() async {
    // Önce assets'te ara
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDir.path}/whisper_models');

    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }

    final modelPath = '${modelDir.path}/ggml-tiny.bin';

    // Model dosyası yoksa indir
    if (!await File(modelPath).exists()) {
      await _downloadModel(modelPath);
    }

    return modelPath;
  }

  Future<void> _downloadModel(String modelPath) async {
    // Whisper tiny model'ini indir
    const modelUrl =
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin';

    try {
      final response = await HttpClient().getUrl(Uri.parse(modelUrl));
      final httpResponse = await response.close();

      final file = File(modelPath);
      final sink = file.openWrite();

      await for (final chunk in httpResponse) {
        sink.add(chunk);
      }

      await sink.close();
    } catch (e) {
      throw Exception('Model indirilemedi: $e');
    }
  }

  Future<TranscriptResult?> transcribeVideo(String videoPath) async {
    if (!_isInitialized) {
      _lastError = 'Whisper servisi başlatılmamış';
      return null;
    }

    try {
      final modelPath = await _getModelPath();
      final result = await transcribeVideoWithWhisper(
        modelPath: modelPath,
        videoPath: videoPath,
      );

      _lastError = null;
      return result;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  Future<TranscriptResult?> transcribeAudio(String audioPath) async {
    if (!_isInitialized) {
      _lastError = 'Whisper servisi başlatılmamış';
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

  bool get isInitialized => _isInitialized;

  void dispose() {
    _isInitialized = false;
    RsWhisperGpt.dispose();
  }
}
