import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiApiService {
  // 🔒 GÜVENLİ: Gemini API anahtarını .env dosyasından al
  static String get _staticGeminiApiKey {
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (key.isEmpty || key == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception(
        'Gemini API anahtarı yapılandırılmamış! .env dosyasını kontrol edin.',
      );
    }
    return key;
  }

  static String getStaticApiKey() {
    return _staticGeminiApiKey;
  }

  // Güvenlik kontrolü
  static bool get isConfigured {
    try {
      final key = dotenv.env['GEMINI_API_KEY'] ?? '';
      return key.isNotEmpty && key != 'YOUR_GEMINI_API_KEY_HERE';
    } catch (e) {
      return false;
    }
  }
}
