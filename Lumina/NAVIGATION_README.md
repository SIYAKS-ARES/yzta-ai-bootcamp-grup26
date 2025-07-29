# Lumina - Navigasyon Sistemi

Bu dokümantasyon, Lumina uygulamasının navigasyon sistemini açıklar.

## 🧭 Navigasyon Yapısı

### Ana Sayfa (Home Page)
- **Dosya**: `lib/pages/home_page.dart`
- **Açıklama**: Uygulamanın ana giriş noktası

#### Navigasyon Öğeleri:
1. **Hoş Geldiniz Kutusu**
   - Kullanıcı adı gösterimi
   - Profil ve Ayarlar butonları

2. **Öğrenci Tipi Seçimi**
   - Görme engelli öğrenci
   - İşitme engelli öğrenci
   - Genel kullanıcı

3. **Özellik Kartları**
   - Modüler özellik sistemi
   - Öğrenci tipine göre özelleştirilmiş

4. **Hızlı Erişim Menüsü**
   - Dosyalar (File Explorer)
   - Profil
   - Ayarlar

## 📱 Sayfa Yapısı

### 1. Ana Sayfa (Home Page)
```
┌─────────────────────────────────┐
│ ✨ Hoş geldiniz, [Kullanıcı]!   │
│ [Profil] [Ayarlar]              │
├─────────────────────────────────┤
│ Nasıl yardımcı olabilirim?      │
│ [👁️ Görme Engelli] [🦻 İşitme] │
├─────────────────────────────────┤
│ 🚀 Özellikler                   │
│ [Grid/Liste Layout]             │
├─────────────────────────────────┤
│ ⚡ Hızlı Erişim                 │
│ [Dosyalar] [Profil] [Ayarlar]   │
├─────────────────────────────────┤
│ 📂 Son Yüklenen Dosyalarım      │
└─────────────────────────────────┘
```

### 2. Profil Sayfası
- **Dosya**: `lib/pages/profile_page.dart`
- **Navigasyon**: AppBar ile geri dönüş
- **Özellikler**:
  - Kullanıcı bilgileri düzenleme
  - Profil fotoğrafı
  - Hesap silme

### 3. Ayarlar Sayfası
- **Dosya**: `lib/pages/settings_page.dart`
- **Navigasyon**: AppBar ile geri dönüş
- **Özellikler**:
  - Dil seçimi
  - Bildirim ayarları
  - Tema ayarları
  - Profil düzenleme (Profil sayfasına yönlendirir)

### 4. Özellik Sayfaları
- **Text to Speech**: `lib/pages/features/text_to_speech_page.dart`
- **Speech to Text**: `lib/pages/features/speech_to_text_page.dart`
- **AI Asistan**: `lib/pages/features/chat_bot_page.dart`
- **Video Transkript**: `lib/pages/features/video_to_transcript_page.dart`

## 🔗 Navigasyon Akışı

### Ana Sayfa → Özellik Sayfaları
```
Ana Sayfa
├── Text to Speech → TextToSpeechPage
├── Speech to Text → SpeechToTextPage
├── AI Asistan → ChatBotPage
└── Video Transkript → VideoToTranscriptPage
```

### Ana Sayfa → Diğer Sayfalar
```
Ana Sayfa
├── Profil → ProfilePage
├── Ayarlar → SettingsPage
└── Dosyalar → FileExplorerPage
```

### Ayarlar → Profil
```
Ayarlar Sayfası
└── Profil Düzenle → ProfilePage
```

## 🎨 Tasarım Standartları

### AppBar Tasarımı
```dart
AppBar(
  title: const Text('Sayfa Adı'),
  backgroundColor: const Color(0xFF2563EB),
  foregroundColor: Colors.white,
  elevation: 0,
)
```

### Buton Tasarımı
```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TargetPage()),
    );
  },
  icon: const Icon(Icons.icon_name, size: 20),
  label: const Text('Buton Metni'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.grey[100],
    foregroundColor: primaryBlue,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
)
```

## 📍 Navigasyon Noktaları

### 1. Hoş Geldiniz Kutusu
- **Konum**: Ana sayfa üst kısmı
- **Butonlar**: Profil, Ayarlar
- **Stil**: İki sütunlu buton layout

### 2. Hızlı Erişim Menüsü
- **Konum**: Ana sayfa alt kısmı
- **Butonlar**: Dosyalar, Profil, Ayarlar
- **Stil**: Üç sütunlu buton layout

### 3. Özellik Kartları
- **Konum**: Ana sayfa orta kısmı
- **Layout**: Grid (2x2) veya Liste
- **Navigasyon**: Her karta tıklama

## 🔄 Geri Dönüş Sistemi

### AppBar Geri Butonu
- Tüm sayfalarda standart AppBar
- Otomatik geri dönüş navigasyonu
- Tutarlı tasarım

### Sayfa Geçişleri
- `Navigator.push()` ile sayfa açma
- `Navigator.pop()` ile geri dönme
- MaterialPageRoute kullanımı

## 📱 Responsive Tasarım

### Mobil Optimizasyon
- Buton boyutları dokunmatik için optimize
- Padding ve margin değerleri mobil için ayarlanmış
- Grid layout mobil ekranlara uygun

### Tablet Desteği
- Geniş ekranlarda daha fazla içerik
- Buton boyutları tablet için uygun
- Layout esnekliği

## 🚀 Gelecek Geliştirmeler

### Planlanan Özellikler
- [ ] Bottom Navigation Bar
- [ ] Drawer Menu
- [ ] Tab Navigation
- [ ] Deep Linking
- [ ] Route Management (GoRouter)

### Navigasyon İyileştirmeleri
- [ ] Animasyonlu geçişler
- [ ] Gesture navigation
- [ ] Accessibility improvements
- [ ] Voice navigation support

## 📝 Notlar

- Tüm navigasyon Material Design standartlarını takip eder
- Tutarlı renk paleti kullanılır
- Erişilebilirlik standartları gözetilir
- Performans optimizasyonu yapılmıştır 