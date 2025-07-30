import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiApiService {
  // Uygulama genelinde kullanılacak sabit Gemini API Key
  static String get _staticGeminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static String getStaticApiKey() {
    return _staticGeminiApiKey;
  }
}
