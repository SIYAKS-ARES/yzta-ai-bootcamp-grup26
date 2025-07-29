# Web Platformu Özel Notları

## 🎯 Web Platformu Sınırlamaları

### ❌ Web'de Çalışmayan Özellikler:
1. **Dosya sistemi erişimi** - `File.copy()` çalışmaz
2. **Kalıcı dosya depolama** - Dosyalar tarayıcı belleğinde tutulur
3. **Dosya yolu erişimi** - `file.path` null olabilir

### ✅ Web'de Çalışan Özellikler:
1. **Dosya seçimi** - `FilePicker` çalışır
2. **Dosya verisi okuma** - `file.bytes` kullanılabilir
3. **TTS** - Web Speech API kullanılır
4. **PDF işleme** - Syncfusion PDF çalışır

## 🔧 Web Platformu Çözümleri

### Dosya İşleme:
```dart
// Web için dosya verilerini doğrudan işle
if (file.bytes != null) {
  final String text = await _processFileBytes(file.bytes!, fileName);
}
```

### TTS:
```dart
// Web Speech API kullan
await _flutterTts.setLanguage("tr-TR");
await _flutterTts.speak(text);
```

### PDF İşleme:
```dart
// Syncfusion PDF ile doğrudan işle
final PdfDocument document = PdfDocument(inputBytes: bytes);
final PdfTextExtractor extractor = PdfTextExtractor(document);
final String text = extractor.extractText();
```

## 📱 Platform Karşılaştırması

| Özellik | Web | Android | iOS |
|---------|-----|---------|-----|
| Dosya Seçimi | ✅ | ✅ | ✅ |
| Dosya Kopyalama | ❌ | ✅ | ✅ |
| Kalıcı Depolama | ❌ | ✅ | ✅ |
| TTS | ✅ | ✅ | ✅ |
| PDF İşleme | ✅ | ✅ | ✅ |

## 🚀 Web Optimizasyonu

### Performans:
- Dosyaları doğrudan işle
- Gereksiz kopyalama işlemlerini atla
- Bellek kullanımını optimize et

### Kullanıcı Deneyimi:
- Web'e özel hata mesajları
- Yükleme göstergeleri
- Responsive tasarım

## 🔍 Test Senaryoları

### Web Testi:
1. **Dosya seçimi**: TXT ve PDF dosyaları
2. **Metin çıkarma**: Dosya içeriğini okuma
3. **TTS**: Sesli okuma
4. **Hata yönetimi**: Geçersiz dosyalar

### Mobil Testi:
1. **Dosya seçimi**: Cihaz dosyaları
2. **Kalıcı depolama**: Dosyaları saklama
3. **Dosya listesi**: Yüklenen dosyaları görme
4. **Dosya silme**: Dosyaları kaldırma

## 💡 Gelecek İyileştirmeler

### Web Platformu:
- IndexedDB ile dosya önbelleği
- Service Worker ile offline destek
- WebAssembly ile PDF işleme

### Mobil Platform:
- Cloud storage entegrasyonu
- Dosya senkronizasyonu
- Gelişmiş dosya yönetimi 