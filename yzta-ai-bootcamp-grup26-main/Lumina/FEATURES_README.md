# Lumina - Modüler Özellik Sistemi

Bu dokümantasyon, Lumina uygulamasının modüler özellik sistemini açıklar.

## 📁 Dosya Yapısı

```
lib/
├── models/
│   └── feature_card_model.dart          # Özellik kartı modeli
├── services/
│   └── feature_service.dart             # Özellik servisi
├── widgets/
│   └── feature_card_widget.dart         # Özellik kartı widget'ı
├── pages/
│   ├── home_page.dart                   # Ana sayfa (modüler yapı)
│   └── features/                        # Özellik sayfaları
│       ├── text_to_speech_page.dart     # Metinden Sese
│       ├── speech_to_text_page.dart     # Sesten Metne
│       ├── chat_bot_page.dart           # AI Asistan
│       └── video_to_transcript_page.dart # Video Transkript
```

## 🚀 Mevcut Özellikler

### 1. Metinden Sese (Text to Speech)
- **Dosya**: `pages/features/text_to_speech_page.dart`
- **Açıklama**: Metin dosyalarını sesli hale getirme
- **Durum**: ✅ Temel UI tamamlandı

### 2. Sesten Metne (Speech to Text)
- **Dosya**: `pages/features/speech_to_text_page.dart`
- **Açıklama**: Ses dosyalarını metne çevirme
- **Durum**: ✅ Temel UI tamamlandı

### 3. AI Asistan (Chat Bot)
- **Dosya**: `pages/features/chat_bot_page.dart`
- **Açıklama**: Yapay zeka destekli sohbet asistanı
- **Durum**: ✅ Temel UI tamamlandı

### 4. Video Transkript
- **Dosya**: `pages/features/video_to_transcript_page.dart`
- **Açıklama**: Video dosyalarını metne çevirme
- **Durum**: ✅ Temel UI tamamlandı

## 🔧 Yeni Özellik Ekleme

Yeni bir özellik eklemek için şu adımları takip edin:

### 1. Özellik Sayfası Oluşturma
```dart
// lib/pages/features/yeni_ozellik_page.dart
import 'package:flutter/material.dart';

class YeniOzellikPage extends StatefulWidget {
  const YeniOzellikPage({super.key});

  @override
  State<YeniOzellikPage> createState() => _YeniOzellikPageState();
}

class _YeniOzellikPageState extends State<YeniOzellikPage> {
  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2563EB);
    final Color softBlue = const Color(0xFF60A5FA);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Özellik'),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Özellik içeriği buraya
            ],
          ),
        ),
      ),
    );
  }
}
```

### 2. Feature Service'e Ekleme
```dart
// lib/services/feature_service.dart
import '../pages/features/yeni_ozellik_page.dart';

// getAllFeatures metoduna ekleyin:
FeatureCardModel(
  id: 'yeni_ozellik',
  icon: '🎯',
  title: 'Yeni Özellik',
  description: 'Yeni özelliğin açıklaması.',
  buttonText: 'Başla',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const YeniOzellikPage()),
    );
  },
),
```

### 3. Öğrenci Tipine Göre Özelleştirme
```dart
// getFeaturesByStudentType metodunda uygun case'e ekleyin:
case StudentType.blind:
  return [
    // Mevcut özellikler...
    FeatureCardModel(
      id: 'yeni_ozellik',
      icon: '🎯',
      title: 'Yeni Özellik',
      description: 'Görme engelli kullanıcılar için özelleştirilmiş açıklama.',
      buttonText: 'Başla',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const YeniOzellikPage()),
        );
      },
    ),
  ];
```

## 🎨 Tema ve Tasarım

Tüm özellik sayfaları aşağıdaki tema standartlarını takip eder:

### Renkler
- **Primary Blue**: `#2563EB`
- **Soft Blue**: `#60A5FA`
- **Background**: Gradient (Primary Blue → Soft Blue)
- **Cards**: White with shadow

### Tasarım Öğeleri
- **Border Radius**: 12-20px
- **Padding**: 16-20px
- **Shadow**: `primaryBlue.withOpacity(0.08)`
- **Typography**: Consistent font weights and sizes

## 📱 Responsive Tasarım

Ana sayfada özellik kartları:
- **Genel kullanıcılar**: 2x2 grid layout
- **Özel öğrenci tipleri**: Liste layout

## 🔄 Durum Yönetimi

Her özellik sayfası kendi state'ini yönetir:
- Loading states
- Error handling
- User interactions
- Data persistence

## 🚀 Gelecek Özellikler

- [ ] PDF to Speech
- [ ] Image to Text (OCR)
- [ ] Real-time Translation
- [ ] Voice Commands
- [ ] Accessibility Settings
- [ ] Offline Mode

## 📝 Notlar

- Tüm özellik sayfaları temel UI ile tamamlanmıştır
- Gerçek işlevsellik için API entegrasyonu gereklidir
- Her özellik bağımsız olarak geliştirilebilir
- Tema tutarlılığı korunmalıdır 