import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/language_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  final bool _isLoading = false;
  final LanguageService _languageService = LanguageService();

  // 🔒 GÜVENLİ: API anahtarını doğrudan .env dosyasından al
  String? get _geminiApiKey {
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (key.isEmpty || key == 'YOUR_GEMINI_API_KEY_HERE') {
      return null;
    }
    return key;
  }

  @override
  void initState() {
    super.initState();
    _loadGeminiApiKey();
    // Hoş geldin mesajı
    _messages.add(
      ChatMessage(
        text: 'Merhaba! Ben Lumina AI Asistan. Size nasıl yardımcı olabilirim?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _loadGeminiApiKey() async {
    // API anahtarı zaten yüklendi, sadece kontrol et
    if (_geminiApiKey == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gemini API anahtarı yapılandırılmamış!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen önce Ayarlar sayfasından Gemini API Key ekleyin.',
          ),
        ),
      );
      return;
    }
    final userMessage = ChatMessage(
      text: _messageController.text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();
    // Gemini API'ye istek at
    final aiResponse = await _fetchGeminiResponse(userMessage.text);
    final aiMessage = ChatMessage(
      text: aiResponse,
      isUser: false,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(aiMessage);
      _isTyping = false;
    });
    _scrollToBottom();
  }

  Future<String> _fetchGeminiResponse(String prompt) async {
    // Sistem promptu: Asistanın kendini tanıtması ve uygulamanın amacını vurgulaması
    const systemPrompt = '''
Senin adın Lumina AI Asistan. Sen, görme ve işitme engelli öğrencilerin dijital ders materyallerine engelsiz erişimini sağlamak için geliştirilen, yapay zeka destekli bir eğitim ve erişilebilirlik platformunun akıllı asistanısın. 

Platformun temel amacı, eğitimde fırsat eşitliğini teknolojiyle desteklemek ve öğrenme sürecindeki tüm bariyerleri ortadan kaldırmaktır. PDF, ses ve video gibi statik içerikleri, her öğrencinin engel durumundan bağımsız olarak tam ve eşit şekilde faydalanabileceği dinamik, etkileşimli ve erişilebilir formatlara dönüştürürsün.

Senin önceliklerin:
- Kullanıcıya her zaman sıcak, destekleyici ve kapsayıcı bir dil ile yardımcı olmak,
- Erişilebilirlik ve eğitim odaklı çözümler sunmak,
- Görme ve işitme engelli bireylerin ihtiyaçlarını ön planda tutmak,
- Platformun Text-to-Speech, Speech-to-Text, çoklu dil desteği, video transkripsiyon, OCR, sesli açıklama, öğretmen admin profili ve gamification gibi özelliklerini gerektiğinde tanıtmak ve açıklamak,
- WCAG 2.1 AA standartlarına uygun erişilebilirlik konusunda rehberlik etmek,
- Eğitimde kapsayıcılığı ve fırsat eşitliğini vurgulamak,
- Platformun misyonunu ve vizyonunu gerektiğinde özetlemek.

Kullanıcıdan gelen her soruya, Lumina AI Asistan olarak, yukarıdaki değerleri ve platformun amacını göz önünde bulundurarak yanıt ver. Gerektiğinde platformun özelliklerini ve erişilebilirlik avantajlarını örneklerle açıkla. 
''';
    final fullPrompt = '$systemPrompt\nKullanıcı: $prompt';
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiApiKey',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': fullPrompt},
            ],
          },
        ],
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return text ?? 'Yanıt alınamadı.';
    } else {
      return 'API hatası:  [response.statusCode}';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2563EB);
    final Color softBlue = const Color(0xFF60A5FA);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Asistan'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    text:
                        'Merhaba! Ben Lumina AI Asistan. Size nasıl yardımcı olabilirim?',
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue, softBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Mesaj listesi
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessage(_messages[index]);
                    },
                  ),
                ),
              ),
            ),

            // Mesaj girişi
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Mesajınızı yazın...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: primaryBlue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final Color primaryBlue = const Color(0xFF2563EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser ? primaryBlue : Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [_buildDot(0), _buildDot(1), _buildDot(2)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        shape: BoxShape.circle,
      ),
    );
  }
}
