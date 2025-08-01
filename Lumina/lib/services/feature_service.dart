import 'package:flutter/material.dart';
import '../models/feature_card_model.dart';
import '../pages/features/text_to_speech_page.dart';
import '../pages/features/advanced_tts_page.dart';
import '../pages/features/experimental_tts_page.dart';
import '../pages/features/speech_to_text_page.dart';
import '../pages/features/chat_bot_page.dart';
import '../pages/features/video_to_transcript_page.dart';

class FeatureService {
  static List<FeatureCardModel> getAllFeatures(BuildContext context) {
    return [
      FeatureCardModel(
        id: 'text_to_speech',
        icon: '🔊',
        title: 'Metinden Sese',
        description:
            'Metin dosyalarınızı sesli hale getirin.\nDinlemeye hemen başlayın.',
        buttonText: 'Başla',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TextToSpeechPage()),
          );
        },
      ),
      FeatureCardModel(
        id: 'advanced_tts',
        icon: '🚀',
        title: 'Gelişmiş TTS',
        description:
            'Cihaz ve bulut TTS seçenekleri.\nYüksek kaliteli ses sentezi.',
        buttonText: 'Başla',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdvancedTTSPage()),
          );
        },
      ),
      FeatureCardModel(
        id: 'experimental_tts',
        icon: '🧪',
        title: 'Deneysel TTS',
        description:
            'AI tabanlı TTS seçenekleri.\nElevenLabs, OpenAI entegrasyonu.',
        buttonText: 'Test Et',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExperimentalTTSPage(),
            ),
          );
        },
      ),
      FeatureCardModel(
        id: 'speech_to_text',
        icon: '🎤',
        title: 'Sesten Metne',
        description: 'Ses dosyalarınızı metne çevirin.\nYazıya dönüştürün.',
        buttonText: 'Başla',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SpeechToTextPage()),
          );
        },
      ),
      FeatureCardModel(
        id: 'chat_bot',
        icon: '🤖',
        title: 'AI Asistan',
        description:
            'Yapay zeka destekli asistan ile\nsorularınızı yanıtlayın.',
        buttonText: 'Sohbet Et',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatBotPage()),
          );
        },
      ),
      FeatureCardModel(
        id: 'video_to_transcript',
        icon: '🎬',
        title: 'Video Transkript',
        description: 'Video dosyalarınızı metne çevirin.\nAltyazı oluşturun.',
        buttonText: 'Başla',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VideoToTranscriptPage(),
            ),
          );
        },
      ),
    ];
  }

  static List<FeatureCardModel> getFeaturesByStudentType(
    BuildContext context,
    StudentType studentType,
  ) {
    switch (studentType) {
      case StudentType.blind:
        return [
          FeatureCardModel(
            id: 'text_to_speech',
            icon: '🔊',
            title: 'Metinden Sese',
            description: 'PDF ve metin dosyalarınızı sesli hale getirin.',
            buttonText: 'Başla',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TextToSpeechPage(),
                ),
              );
            },
          ),
          FeatureCardModel(
            id: 'advanced_tts',
            icon: '🚀',
            title: 'Gelişmiş TTS',
            description:
                'Cihaz ve bulut TTS seçenekleri ile yüksek kaliteli ses.',
            buttonText: 'Başla',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdvancedTTSPage(),
                ),
              );
            },
          ),
          FeatureCardModel(
            id: 'chat_bot',
            icon: '🤖',
            title: 'AI Asistan',
            description: 'Sesli komutlarla AI asistanınızla konuşun.',
            buttonText: 'Sohbet Et',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatBotPage()),
              );
            },
          ),
        ];
      case StudentType.deaf:
        return [
          FeatureCardModel(
            id: 'speech_to_text',
            icon: '🎤',
            title: 'Sesten Metne',
            description: 'Ses dosyalarını metne çevirin.',
            buttonText: 'Başla',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SpeechToTextPage(),
                ),
              );
            },
          ),
          FeatureCardModel(
            id: 'video_to_transcript',
            icon: '🎬',
            title: 'Video Transkript',
            description: 'Video dosyalarını altyazılı hale getirin.',
            buttonText: 'Başla',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VideoToTranscriptPage(),
                ),
              );
            },
          ),
        ];
      default:
        return getAllFeatures(context);
    }
  }
}

enum StudentType { none, blind, deaf }
