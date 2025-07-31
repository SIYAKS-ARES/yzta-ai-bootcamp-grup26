# Lumina Text-to-Speech Özelliği

## Genel Bakış

Lumina uygulamasının text-to-speech (TTS) özelliği, görme engelli bireyler için PDF ve metin dosyalarını sesli olarak okuma imkanı sağlar. Bu özellik sayesinde kullanıcılar:

- PDF dosyalarını sesli olarak dinleyebilir
- TXT dosyalarını kolayca okuyabilir
- Metinleri ses dosyası olarak kaydedebilir
- Konuşma hızı ve ses seviyesini ayarlayabilir

## Özellikler

### 📁 Dosya Desteği
- **PDF Dosyaları**: PDF'lerden metin çıkarma ve sesli okuma
- **TXT Dosyaları**: Metin dosyalarını sesli okuma
- **Manuel Metin Girişi**: Kullanıcının yazdığı metinleri sesli okuma

### 🔊 Ses Özellikleri
- **Türkçe Dil Desteği**: Doğal Türkçe sesli okuma
- **Ayarlanabilir Hız**: %10 - %100 arası konuşma hızı
- **Ses Seviyesi Kontrolü**: %0 - %100 arası ses seviyesi
- **Ses Dosyası Kaydetme**: Metinleri WAV formatında kaydetme

### ⚙️ Ayarlar
- **Konuşma Hızı**: Slider ile kolay ayarlama
- **Ses Seviyesi**: Slider ile kolay ayarlama
- **Ses Testi**: Ayarları test etme özelliği

## Kullanım Kılavuzu

### 1. Dosya Seçme
1. Ana sayfada "Metinden Sese" kartına tıklayın
2. "PDF/TXT Dosyası Seç" butonuna tıklayın
3. Dosya seçici açılacak, PDF veya TXT dosyanızı seçin
4. Dosya işlendikten sonra metin otomatik olarak yüklenecek

### 2. Metin Düzenleme
- Yüklenen metni düzenleyebilirsiniz
- Hızlı örneklerden birini seçebilirsiniz
- Manuel olarak metin yazabilirsiniz

### 3. Sesli Okuma
- **Oynat**: Metni sesli olarak okumaya başlar
- **Durdur**: Sesli okumayı durdurur
- **Ses Olarak Kaydet**: Metni WAV dosyası olarak kaydeder

### 4. Ayarları Düzenleme
1. Ayarlar sayfasına gidin
2. "Ses Ayarları" bölümünü bulun
3. Konuşma hızını ve ses seviyesini ayarlayın
4. "Ses Testi" butonu ile ayarları test edin

## Teknik Detaylar

### Kullanılan Teknolojiler
- **Flutter TTS**: Ana text-to-speech motoru
- **Syncfusion PDF**: PDF metin çıkarma
- **AudioPlayers**: Ses dosyası oynatma
- **File Picker**: Dosya seçimi

### Platform Desteği
- **Android**: Google TTS Engine
- **iOS**: Apple TTS Engine
- **Web**: Web Speech API

### Desteklenen Dosya Formatları
- PDF (.pdf)
- Metin (.txt)

### Ses Formatları
- WAV (.wav) - Kaydetme formatı
- Platform native - Oynatma formatı

## Erişilebilirlik Özellikleri

### Görme Engelli Kullanıcılar İçin
- **Sesli Geri Bildirim**: Tüm işlemler sesli olarak bildirilir
- **Kolay Navigasyon**: Büyük butonlar ve net etiketler
- **Hızlı Erişim**: Ana sayfadan tek tıkla erişim
- **Ayarlanabilir Ses**: Kişisel tercihlere göre ayarlama

### Kullanım İpuçları
1. **Dosya Seçimi**: Dosya seçerken sesli geri bildirim dinleyin
2. **Metin Düzenleme**: Metni düzenlerken kısa bölümler halinde test edin
3. **Ses Ayarları**: Rahat dinleme için hızı %50-70 arasında tutun
4. **Kaydetme**: Önemli metinleri ses dosyası olarak kaydedin

## Sorun Giderme

### Yaygın Sorunlar

**Ses çıkmıyor:**
- Cihaz sesinin açık olduğundan emin olun
- Ayarlar sayfasından ses seviyesini kontrol edin
- Ses testi butonunu deneyin

**PDF okunmuyor:**
- PDF'in metin içerdiğinden emin olun
- Görsel PDF'ler desteklenmez
- Dosya boyutunun çok büyük olmadığından emin olun

**Dosya seçilemiyor:**
- Dosya izinlerini kontrol edin
- Sadece PDF ve TXT dosyaları desteklenir
- Dosya adında özel karakter olmadığından emin olun

### Destek
Sorun yaşarsanız:
- Ayarlar > Yardım ve Destek bölümünü kullanın
- destek@lumina.com adresine yazın

## Gelecek Özellikler

- **Çoklu Dil Desteği**: İngilizce, Almanca vb.
- **Farklı Sesler**: Erkek/kadın ses seçenekleri
- **Gelişmiş PDF Desteği**: Görsel PDF'ler için OCR
- **Bulut Senkronizasyon**: Ayarları bulutta saklama
- **Offline Mod**: İnternet olmadan çalışma

---

**Not**: Bu özellik görme engelli bireylerin eğitim materyallerine erişimini kolaylaştırmak için geliştirilmiştir. Herhangi bir sorun yaşarsanız lütfen geri bildirimde bulunun. 