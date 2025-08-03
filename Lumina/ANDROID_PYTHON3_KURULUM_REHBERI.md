# Android'de Python3 Kurulum Rehberi

## 🎯 Amaç
Android'de Python3 kurarak yerel Whisper transkript özelliğini çalıştırmak.

## 📋 Gereksinimler
- Android 7.0+ (API level 24+)
- En az 500MB boş alan
- İnternet bağlantısı

## 🔧 Kurulum Adımları

### 1. Termux Kurulumu
1. **F-Droid**'den Termux'u indirin:
   - https://f-droid.org/en/packages/com.termux/
   - veya Google Play Store'dan "Termux" arayın

2. **Termux'u açın** ve ilk kurulumu tamamlayın

### 2. Python3 Kurulumu
Termux'ta şu komutları çalıştırın:

```bash
# Paket listesini güncelle
pkg update

# Python3'ü kur
pkg install python

# pip3'ü kur
pkg install python-pip

# Whisper kütüphanesini kur
pip3 install openai-whisper

# Gerekli bağımlılıkları kur
pkg install ffmpeg
```

### 3. Kurulum Kontrolü
```bash
# Python3 versiyonunu kontrol et
python3 --version

# Whisper'ı test et
python3 -c "import whisper; print('Whisper kuruldu!')"
```

### 4. Flutter Uygulaması ile Entegrasyon
Termux'ta Python3 kurulduktan sonra, Flutter uygulaması şu yolları deneyecek:
- `/data/data/com.termux/files/usr/bin/python3`
- `/system/bin/python3`
- `python3` (PATH'te varsa)

## ⚠️ Önemli Notlar
- Termux kurulumu gerekli
- Python3 PATH'e eklenmeli
- Whisper modeli ilk kullanımda indirilecek (~39MB)
- Android sandbox kısıtlamaları nedeniyle dosya erişimi sınırlı olabilir

## 🔍 Sorun Giderme
1. **Permission denied:** Termux'a gerekli izinleri verin
2. **Python3 bulunamadı:** PATH'i kontrol edin
3. **Whisper import hatası:** pip3 ile yeniden kurun
4. **Model indirme hatası:** İnternet bağlantısını kontrol edin

## 📱 Alternatif Çözümler
1. **Pydroid 3:** Python IDE (sınırlı entegrasyon)
2. **QPython:** Python IDE (sınırlı entegrasyon)
3. **Chaquopy:** Android Python SDK (ücretli)
4. **API tabanlı çözüm:** OpenAI Whisper API (ücretli)

## 🎯 Sonraki Adımlar
1. Termux kurulumu tamamlandıktan sonra Flutter uygulamasını test edin
2. Debug loglarını kontrol edin
3. Whisper modelini test edin 