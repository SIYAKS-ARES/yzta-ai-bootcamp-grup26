import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/advanced_tts_service.dart';

class ExperimentalTTSPage extends StatefulWidget {
  const ExperimentalTTSPage({super.key});

  @override
  State<ExperimentalTTSPage> createState() => _ExperimentalTTSPageState();
}

class _ExperimentalTTSPageState extends State<ExperimentalTTSPage> {
  final TextEditingController _textController = TextEditingController();
  final AdvancedTTSService _ttsService = AdvancedTTSService();

  bool isPlaying = false;
  bool isProcessing = false;
  TTSProvider selectedProvider = TTSProvider.device;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
  }

  @override
  void dispose() {
    _textController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _initializeTTS() async {
    try {
      await _ttsService.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS başlatma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2563EB);
    final Color softBlue = const Color(0xFF60A5FA);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Deneysel TTS'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
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
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TTS Sağlayıcı Seçimi
                  _buildProviderSelectionCard(),
                  const SizedBox(height: 20),

                  // Metin girişi
                  _buildTextInputCard(),
                  const SizedBox(height: 20),

                  // Kontrol butonları
                  _buildControlButtons(),
                  const SizedBox(height: 20),

                  // Durum kartı
                  _buildStatusCard(),
                  const SizedBox(height: 20),

                  // Bilgi kartı
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔧 TTS Sağlayıcısı',
            style: TextStyle(
              color: const Color(0xFF2563EB),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildProviderChip(
                TTSProvider.device,
                'Cihaz',
                'Hızlı, düşük kalite',
                Icons.phone_android,
              ),
              _buildProviderChip(
                TTSProvider.cloud,
                'Bulut',
                'Yavaş, yüksek kalite',
                Icons.cloud,
              ),
              _buildProviderChip(
                TTSProvider.elevenlabs,
                'ElevenLabs',
                'Çok doğal ses',
                Icons.psychology,
              ),
              _buildProviderChip(
                TTSProvider.openai,
                'OpenAI',
                'AI kalitesi',
                Icons.smart_toy,
              ),
              _buildProviderChip(
                TTSProvider.gemini,
                'Gemini',
                'Google AI',
                Icons.psychology,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderChip(
    TTSProvider provider,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = selectedProvider == provider;
    final isLoggedIn = _getCurrentUserId() != null;
    final isDisabled =
        provider == TTSProvider.cloud && !isLoggedIn ||
        provider == TTSProvider.elevenlabs &&
            !_isProviderConfigured(provider) ||
        provider == TTSProvider.openai && !_isProviderConfigured(provider) ||
        provider == TTSProvider.gemini && !_isProviderConfigured(provider);

    // Bulut TTS için Blaze plan uyarısı
    final showBlazeWarning = provider == TTSProvider.cloud && isSelected;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                selectedProvider = provider;
                _ttsService.setProvider(provider);
              });
            },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDisabled ? Colors.grey[200] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDisabled ? Colors.grey[400]! : Colors.grey[300]!),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDisabled ? Colors.grey[400] : Colors.grey[600]),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDisabled ? Colors.grey[500] : Colors.grey[800]),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? Colors.white70
                    : (isDisabled ? Colors.grey[400] : Colors.grey[600]),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
            // Blaze plan uyarısı kaldırıldı - test için aktif
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔊 Test Metni',
            style: TextStyle(
              color: const Color(0xFF2563EB),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Test etmek istediğiniz metni yazın...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _textController.text.trim().isEmpty || isProcessing
                ? null
                : _togglePlayback,
            icon: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(isPlaying ? Icons.stop : Icons.play_arrow),
            label: Text(
              isProcessing
                  ? 'İşleniyor...'
                  : (isPlaying ? 'Durdur' : 'Test Et'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _testQuickSamples,
            icon: const Icon(Icons.speed),
            label: const Text('Hızlı Test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Durum',
            style: TextStyle(
              color: const Color(0xFF2563EB),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isPlaying ? Icons.play_circle : Icons.stop_circle,
                color: isPlaying ? Colors.green : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Durum: ${isPlaying
                          ? "Oynatılıyor"
                          : isProcessing
                          ? "İşleniyor"
                          : "Hazır"}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Sağlayıcı: ${_getProviderName(selectedProvider)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final isLoggedIn = _getCurrentUserId() != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ℹ️ Bilgi',
            style: TextStyle(
              color: const Color(0xFF2563EB),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoItem('Cihaz', 'Hızlı, ücretsiz, düşük kalite'),
          _buildInfoItem(
            'Bulut',
            'Yavaş, ücretsiz, simüle edilmiş (Blaze plan gerekli)',
          ),
          _buildInfoItem('ElevenLabs', 'Hızlı, ücretli, çok doğal'),
          _buildInfoItem('OpenAI', 'Hızlı, ücretli, AI kalitesi'),
          _buildInfoItem('Gemini', 'Hızlı, ücretli, Google AI'),
          const SizedBox(height: 12),

          // Giriş durumu uyarısı
          if (!isLoggedIn)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bulut TTS için giriş yapmanız gerekiyor (simüle edilmiş)',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!isLoggedIn) const SizedBox(height: 12),

          // API durumu uyarıları
          if (!_isProviderConfigured(TTSProvider.elevenlabs))
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.api, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ElevenLabs için API anahtarı gerekli',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!_isProviderConfigured(TTSProvider.elevenlabs))
            const SizedBox(height: 12),

          if (!_isProviderConfigured(TTSProvider.openai))
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.api, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OpenAI için API anahtarı gerekli',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!_isProviderConfigured(TTSProvider.openai))
            const SizedBox(height: 12),

          // OpenAI kota uyarısı kaldırıldı - test için aktif
          if (!_isProviderConfigured(TTSProvider.gemini))
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.api, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gemini için API anahtarı gerekli',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!_isProviderConfigured(TTSProvider.gemini))
            const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎯 Tüm TTS Sağlayıcıları Aktif!',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Cihaz TTS: Hızlı, düşük kalite\n• Bulut TTS: Simüle edilmiş (Blaze plan gerekli)\n• ElevenLabs: Çok doğal ses\n• OpenAI: AI kalitesi\n• Gemini: Google AI',
                  style: TextStyle(color: Colors.green[700], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getProviderName(TTSProvider provider) {
    switch (provider) {
      case TTSProvider.device:
        return 'Cihaz TTS';
      case TTSProvider.cloud:
        return 'Firebase Cloud';
      case TTSProvider.elevenlabs:
        return 'ElevenLabs API';
      case TTSProvider.openai:
        return 'OpenAI TTS';
      case TTSProvider.gemini:
        return 'Gemini TTS';
    }
  }

  Future<void> _togglePlayback() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen test metni girin'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      if (isPlaying) {
        await _ttsService.stopSpeaking();
        setState(() {
          isPlaying = false;
        });
      } else {
        setState(() {
          isPlaying = true;
        });

        final userId = _getCurrentUserId();

        // Bulut TTS için kullanıcı ID kontrolü
        if (selectedProvider == TTSProvider.cloud && userId == null) {
          setState(() {
            isPlaying = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bulut TTS için giriş yapmanız gerekiyor'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        await _ttsService.speakText(text, userId: userId);
      }
    } catch (e) {
      setState(() {
        isPlaying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hata: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _testQuickSamples() async {
    final samples = [
      'Merhaba, bu bir test cümlesidir.',
      'Yapay zeka teknolojileri geleceğimizi şekillendiriyor.',
      'Erişilebilirlik herkes için önemlidir.',
    ];

    for (final sample in samples) {
      _textController.text = sample;
      await Future.delayed(const Duration(milliseconds: 500));
      await _togglePlayback();
      await Future.delayed(const Duration(seconds: 3));
      await _ttsService.stopSpeaking();
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  String? _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // 🔒 GÜVENLİ: API anahtarlarını doğrudan .env dosyasından kontrol et
  bool _isProviderConfigured(TTSProvider provider) {
    switch (provider) {
      case TTSProvider.elevenlabs:
        final key = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
        return key.isNotEmpty && key != 'YOUR_ELEVENLABS_API_KEY_HERE';
      case TTSProvider.openai:
        final key = dotenv.env['OPENAI_API_KEY'] ?? '';
        return key.isNotEmpty && key != 'YOUR_OPENAI_API_KEY_HERE';
      case TTSProvider.gemini:
        final key = dotenv.env['GEMINI_API_KEY'] ?? '';
        return key.isNotEmpty && key != 'YOUR_GEMINI_API_KEY_HERE';
      case TTSProvider.cloud:
        return true; // Firebase her zaman mevcut
      case TTSProvider.device:
        return true; // Cihaz TTS her zaman mevcut
    }
  }
}
