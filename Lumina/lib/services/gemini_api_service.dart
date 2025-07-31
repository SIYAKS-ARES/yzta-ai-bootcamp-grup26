import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiApiService {
  // Uygulama genelinde kullanılacak sabit Gemini API Key
  static String get _staticGeminiApiKey =>
      dotenv.env['AIzaSyCGP_vJsi8GOXJVpZxOCLuoRFKf_7Px_uw'] ?? '';

  static String getStaticApiKey() {
    return _staticGeminiApiKey;
  }
}
