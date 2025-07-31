# Flutter Entegrasyon Örnekleri

Bu klasör, frontend ekibinin Firebase Functions ile entegrasyon yapabilmesi için örnek kodları içerir.

## Dosyalar

### 1. `tts_service.dart`
**Hedef:** `lib/services/tts_service.dart`

Firebase Functions ile TTS (Text-to-Speech) servisi entegrasyonu için örnek kod.

### 2. `upload_screen.dart`
**Hedef:** `lib/screens/tts_upload_screen.dart`

Dosya yükleme ve TTS işlemlerini yöneten ekran örneği.

### 3. `task_model.dart`
**Hedef:** `lib/models/task_model.dart`

Görev verilerini temsil eden model sınıfı.

### 4. `required_pubspec_dependencies.yaml`
**Hedef:** `pubspec.yaml` (dependencies bölümüne ekleyin)

Gerekli bağımlılıkların listesi.

## Kurulum Adımları

### 1. Bağımlılıkları Ekleyin

`pubspec.yaml` dosyanıza aşağıdaki bağımlılıkları ekleyin:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  cloud_functions: ^4.5.8
  
  # Dosya işlemleri
  file_picker: ^6.1.1
  path: ^1.8.3
  
  # Ses oynatma
  just_audio: ^0.9.36
```

### 2. Dosyaları Kopyalayın

1. `tts_service.dart` → `lib/services/tts_service.dart`
2. `upload_screen.dart` → `lib/screens/tts_upload_screen.dart`
3. `task_model.dart` → `lib/models/task_model.dart`

### 3. Firebase Yapılandırması

Firebase projenizi yapılandırdığınızdan emin olun:

```dart
// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

### 4. Kullanım

```dart
// Ekranınızda TTS servisini kullanın
final ttsService = TTSService();

// Dosya yükleme
final taskId = await ttsService.uploadFileAndCreateTask(
  file: selectedFile,
  userId: currentUser.uid,
);

// Görev durumunu dinleme
ttsService.getTaskStream(taskId).listen((task) {
  print('Görev durumu: ${task.status}');
  if (task.status == 'completed') {
    // Ses dosyası hazır
    print('Ses URL: ${task.audioUrl}');
  }
});
```

## Önemli Notlar

- Bu örnek kodlar sadece referans amaçlıdır
- Kendi projenize uyarlarken gerekli düzenlemeleri yapın
- Firebase Functions'ın deploy edilmiş olması gerekir
- Kullanıcı kimlik doğrulaması gerekir

## Hata Ayıklama

Eğer bağımlılık hataları alıyorsanız:

1. `flutter pub get` komutunu çalıştırın
2. Tüm bağımlılıkların doğru versiyonlarda olduğundan emin olun
3. Firebase yapılandırmanızı kontrol edin

## Destek

Sorunlar için backend ekibi ile iletişime geçin. 