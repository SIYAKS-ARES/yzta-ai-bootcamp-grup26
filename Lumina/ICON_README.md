# Lumina - Uygulama İkonu

Bu dokümantasyon, Lumina uygulamasının ikon değişikliklerini açıklar.

## 🎨 İkon Tasarımı

### Logo Açıklaması
Lumina logosu, modern ve anlamlı bir tasarıma sahiptir:

- **Açık Kitap**: Eğitim ve bilgiyi temsil eder
- **Büyüyen Bitki**: Gelişim ve ilerlemeyi simgeler
- **Renkli Parçacıklar**: Işık ve enerjiyi temsil eder
- **Alev Şekli**: İlham ve yaratıcılığı simgeler
- **Koyu Mavi Arka Plan**: Güven ve profesyonellik

### Renk Paleti
- **Arka Plan**: Koyu Mavi (#1E3A8A)
- **Ana Grafik**: Beyaz
- **Vurgu Renkleri**: Turuncu, Mavi, Yeşil
- **Metin**: Beyaz

## 📱 Platform Desteği

### Android
- **Dosya Konumu**: `android/app/src/main/res/mipmap-*/`
- **Boyutlar**:
  - mdpi: 48x48px
  - hdpi: 72x72px
  - xhdpi: 96x96px
  - xxhdpi: 144x144px
  - xxxhdpi: 192x192px
- **Format**: PNG
- **Manifest**: `@mipmap/launcher_icon`

### iOS
- **Dosya Konumu**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Boyutlar**: 20x20px'den 1024x1024px'e kadar
- **Format**: PNG (Alpha kanalı kaldırıldı)
- **App Store Uyumlu**: ✅

### Web
- **Dosya Konumu**: `web/icons/`
- **Boyutlar**: 192x192px, 512x512px
- **Format**: PNG
- **Arka Plan Rengi**: #2563EB

### Windows
- **Dosya Konumu**: `windows/runner/resources/`
- **Boyut**: 48x48px
- **Format**: ICO

### macOS
- **Dosya Konumu**: `macos/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Boyutlar**: 16x16px'den 1024x1024px'e kadar
- **Format**: PNG

## 🔧 Teknik Detaylar

### Flutter Launcher Icons Konfigürasyonu
```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icon.png"
  remove_alpha_ios: true
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/icon.png"
    background_color: "#2563EB"
    theme_color: "#2563EB"
  windows:
    generate: true
    image_path: "assets/icon.png"
    icon_size: 48
  macos:
    generate: true
    image_path: "assets/icon.png"
```

### Kaynak Dosya
- **Orijinal Logo**: `../GK & SS/Icon/Lumina Small.png`
- **Proje İçi Kopya**: `assets/icon.png`
- **Boyut**: 1024x1024px (önerilen)

## 🚀 Kurulum Adımları

### 1. Logo Dosyasını Kopyalama
```bash
mkdir -p assets
cp "../GK & SS/Icon/Lumina Small.png" ./assets/icon.png
```

### 2. Pubspec.yaml Güncelleme
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter:
  assets:
    - assets/icon.png

flutter_launcher_icons:
  # Konfigürasyon buraya
```

### 3. İkonları Oluşturma
```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

### 4. Temizlik ve Yeniden Oluşturma
```bash
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons:main
```

## 📋 Kontrol Listesi

### ✅ Tamamlanan İşlemler
- [x] Logo dosyası kopyalandı
- [x] Flutter Launcher Icons paketi eklendi
- [x] Pubspec.yaml konfigürasyonu yapıldı
- [x] Android ikonları oluşturuldu
- [x] iOS ikonları oluşturuldu (alpha kanalı kaldırıldı)
- [x] Web ikonları oluşturuldu
- [x] Windows ikonları oluşturuldu
- [x] macOS ikonları oluşturuldu
- [x] Android manifest güncellendi
- [x] Uygulama adı "Lumina" olarak ayarlandı

### 🔄 Güncelleme Süreci
İkon değişikliği yapmak için:
1. `assets/icon.png` dosyasını değiştirin
2. `flutter pub run flutter_launcher_icons:main` komutunu çalıştırın
3. Uygulamayı yeniden derleyin

## 🎯 Tasarım Prensipleri

### Erişilebilirlik
- Yüksek kontrast oranı
- Net ve okunabilir tasarım
- Farklı boyutlarda tanınabilir

### Marka Kimliği
- Eğitim ve teknoloji teması
- Modern ve profesyonel görünüm
- Tutarlı renk paleti

### Platform Uyumluluğu
- Her platform için optimize edilmiş
- Platform standartlarına uygun
- Farklı çözünürlüklerde kaliteli

## 📝 Notlar

- iOS App Store için alpha kanalı kaldırıldı
- Tüm platformlarda tutarlı görünüm sağlandı
- Yüksek kaliteli vektör kaynak kullanıldı
- Responsive tasarım prensipleri uygulandı 