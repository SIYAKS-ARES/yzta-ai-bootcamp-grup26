# Speech to Text (Sesten Metne) Özelliği Test Rehberi

## Özellik Açıklaması
Bu özellik, kullanıcının mikrofon üzerinden konuşmasını dinleyerek konuşulan metni yazıya çevirir. Özellikle işitme engelli öğrenciler için sesli içerikleri metin haline getirmek amacıyla tasarlanmıştır.

## Kurulum ve Gereksinimler

### Gerekli Paketler
- `speech_to_text: ^6.6.0` - Ana speech to text paketi
- `permission_handler: ^12.0.1` - Mikrofon izinleri için
- `path_provider: ^2.1.4` - Dosya yönetimi için

### Android İzinleri
Android manifest dosyasına eklenen izinler:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MICROPHONE" />
```

## Kullanım Adımları

### 1. Uygulamayı Başlatma
```bash
cd Lumina
flutter run
```

### 2. Speech to Text Sayfasına Erişim
- Ana sayfada "Sesten Metne" kartına tıklayın
- Veya işitme engelli öğrenci seçeneğini seçin

### 3. Mikrofon İzni
- İlk kullanımda mikrofon izni istenecek
- "İzin Ver" butonuna tıklayın

### 4. Dinleme İşlemi
- "Dinlemeye Başla" butonuna tıklayın
- Kırmızı "Dinleniyor..." göstergesi görünecek
- Net ve yavaş konuşun
- Konuşma bittiğinde otomatik olarak durur

### 5. Sonuçları Yönetme
- Tanınan metin metin kutusunda görünür
- "Temizle" butonu ile metni silebilirsiniz
- "Metni Kaydet" butonu ile dosya olarak kaydedebilirsiniz

## Özellikler

### Temel Özellikler
- ✅ Gerçek zamanlı ses tanıma
- ✅ Türkçe dil desteği
- ✅ Otomatik dinleme durdurma
- ✅ Tanınan metni kaydetme
- ✅ Kaydedilen dosyaları yönetme

### Gelişmiş Özellikler
- ✅ Mikrofon izin kontrolü
- ✅ Hata yönetimi
- ✅ Debug modu
- ✅ Kullanım ipuçları

## Test Senaryoları

### Senaryo 1: Temel Kullanım
1. Speech to text sayfasını açın
2. Mikrofon iznini verin
3. "Dinlemeye Başla" butonuna tıklayın
4. "Merhaba, nasılsınız?" deyin
5. Metnin tanındığını kontrol edin

### Senaryo 2: Uzun Metin
1. Dinlemeye başlayın
2. Uzun bir paragraf okuyun
3. Otomatik durma işlemini kontrol edin
4. Metni kaydedin

### Senaryo 3: Dosya Yönetimi
1. Birkaç metin kaydedin
2. Kaydedilen dosyaları görüntüleyin
3. Dosyaları silin

### Senaryo 4: Hata Durumları
1. Mikrofon iznini reddedin
2. Hata mesajını kontrol edin
3. İzni tekrar verin

## Sorun Giderme

### Yaygın Sorunlar

#### 1. Mikrofon İzni Verilmedi
**Belirti:** "Mikrofon izni gerekli" hatası
**Çözüm:** 
- Ayarlar > Uygulamalar > Lumina > İzinler > Mikrofon
- İzni manuel olarak verin

#### 2. Ses Tanınmıyor
**Belirti:** Konuşma tanınmıyor
**Çözüm:**
- Net ve yavaş konuşun
- Gürültülü ortamlardan kaçının
- Mikrofonu ağzınıza yakın tutun

#### 3. Uygulama Çöküyor
**Belirti:** Dinleme sırasında çökme
**Çözüm:**
- Uygulamayı yeniden başlatın
- Debug modunu kullanın
- Logları kontrol edin

### Debug Modu
- "STT Debug" butonuna tıklayın
- Konsol loglarını kontrol edin
- Desteklenen dilleri görün

## Teknik Detaylar

### Servis Yapısı
```
lib/services/speech_to_text_service.dart
├── initialize() - Servisi başlatma
├── startListening() - Dinlemeye başlama
├── stopListening() - Dinlemeyi durdurma
├── saveRecognizedTextToFile() - Metni kaydetme
└── debugSTT() - Debug bilgileri
```

### Sayfa Yapısı
```
lib/pages/features/speech_to_text_page.dart
├── Mikrofon kontrolü
├── Tanınan metin alanı
├── Kontrol butonları
├── Kaydedilen dosyalar
└── Kullanım ipuçları
```

### Dosya Yönetimi
- Tanınan metinler: `app_documents/recognized_text/`
- Dosya formatı: `.txt`
- Dosya adı: `taninan_metin_[timestamp].txt`

## Gelecek Geliştirmeler

### Planlanan Özellikler
- [ ] Farklı dil desteği
- [ ] Ses dosyası yükleme
- [ ] Gerçek zamanlı çeviri
- [ ] Ses kalitesi ayarları
- [ ] Özel kelime tanıma

### Entegrasyon Planları
- [ ] TTS ile entegrasyon
- [ ] Chat bot entegrasyonu
- [ ] Dosya düzenleme özelliği
- [ ] Bulut senkronizasyonu

## Performans Notları

### Optimizasyon
- Dinleme süresi: 30 saniye
- Duraklama süresi: 3 saniye
- Dosya boyutu: ~1KB/100 karakter

### Sınırlamalar
- Sadece Android desteği
- İnternet bağlantısı gerekli
- Ses kalitesi bağımlılığı

## Test Sonuçları

### Başarılı Testler
- ✅ Mikrofon izni kontrolü
- ✅ Türkçe ses tanıma
- ✅ Dosya kaydetme
- ✅ Hata yönetimi

### Beklenen İyileştirmeler
- Ses tanıma doğruluğu
- Çoklu dil desteği
- Offline mod
- Ses dosyası desteği 