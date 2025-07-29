# Text-to-Speech Test Rehberi

## 🎯 Test Adımları

### 1. Uygulamayı Başlatın
```bash
cd Lumina
flutter run
```

### 2. Text-to-Speech Sayfasına Gidin
- Ana sayfada "Metinden Sese" özelliğine tıklayın
- Veya direkt olarak TextToSpeechPage'e gidin

### 3. Manuel Metin Testi
1. **Metin kutusuna yazın**: "Merhaba, bu bir test metnidir."
2. **Oynat butonuna tıklayın**
3. **Beklenen sonuç**: Metin sesli olarak okunmalı

### 4. Hızlı Örnekler Testi
1. **"Merhaba, nasılsınız?" chip'ine tıklayın**
2. **Beklenen sonuç**: Metin otomatik olarak oynatılmalı

### 5. Dosya Yükleme Testi
1. **"PDF/TXT Dosyası Seç" butonuna tıklayın**
2. **test_dosyasi.txt dosyasını seçin**
3. **Beklenen sonuç**: Dosyadan metin çıkarılmalı ve text kutusuna yazılmalı

### 6. Debug Testi
1. **"TTS Debug" butonuna tıklayın**
2. **Konsolu kontrol edin** (debug bilgileri görünmeli)

## 🔧 Sorun Giderme

### Ses Çıkmıyorsa:
1. **Cihaz sesinin açık olduğundan emin olun**
2. **Debug butonuna tıklayın ve konsolu kontrol edin**
3. **Farklı bir metin deneyin**

### Dosya Yüklenmiyorsa:
1. **Dosya izinlerini kontrol edin**
2. **Desteklenen formatları kullanın** (.txt, .pdf)
3. **Dosya boyutunu kontrol edin**

### Hata Mesajları:
- **"TTS Error"**: TTS servisi başlatılamadı
- **"Dosya bulunamadı"**: Dosya yolu sorunu
- **"Desteklenmeyen dosya türü"**: Yanlış format

## 📱 Platform Özellikleri

### Android:
- Google TTS Engine kullanır
- Türkçe dil desteği mevcut
- Ses dosyası kaydetme desteklenir

### iOS:
- Apple TTS Engine kullanır
- Türkçe dil desteği mevcut
- Ses dosyası kaydetme desteklenir

## 🎵 Ses Ayarları

### Konuşma Hızı:
- **0.1 - 1.0** arası ayarlanabilir
- **0.5** varsayılan değer

### Ses Seviyesi:
- **0.0 - 1.0** arası ayarlanabilir
- **1.0** varsayılan değer

### Ses Tonu:
- **0.5 - 2.0** arası ayarlanabilir
- **1.0** varsayılan değer

## 📋 Test Kontrol Listesi

- [ ] Manuel metin girişi çalışıyor
- [ ] Hızlı örnekler çalışıyor
- [ ] TXT dosyası yükleme çalışıyor
- [ ] PDF dosyası yükleme çalışıyor
- [ ] Ses dosyası kaydetme çalışıyor
- [ ] Debug fonksiyonu çalışıyor
- [ ] Türkçe dil desteği çalışıyor
- [ ] Ses ayarları çalışıyor

## 🚀 Performans İpuçları

1. **Kısa metinlerle test edin** (100 karakterden az)
2. **Uzun metinler için ses dosyası kaydetmeyi kullanın**
3. **Ağ bağlantısı gerektiren özellikler için internet bağlantısını kontrol edin** 