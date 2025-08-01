# 🔒 GÜVENLİK REHBERİ

## ⚠️ KRİTİK GÜVENLİK UYARISI ⚠️

Bu projede tespit edilen güvenlik sorunları düzeltilmiştir. Aşağıdaki adımları takip edin:

## 🔐 API Anahtarlarını Güvenli Hale Getirme

### 1. Mevcut API Anahtarlarını İptal Edin
- **ElevenLabs**: Dashboard'dan eski anahtarı iptal edin
- **OpenAI**: OpenAI dashboard'dan eski anahtarı iptal edin  
- **Gemini**: Google Cloud Console'dan eski anahtarı iptal edin
- **Firebase**: Firebase Console'dan yeni anahtarlar oluşturun

### 2. Yeni API Anahtarlarını Güvenli Şekilde Saklayın

#### Seçenek 1: Environment Variables (Önerilen)
```bash
# .env dosyası oluşturun (gitignore'da olmalı)
ELEVENLABS_API_KEY=your_new_key_here
OPENAI_API_KEY=your_new_key_here
GEMINI_API_KEY=your_new_key_here
```

#### Seçenek 2: Flutter Secure Storage
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.write(key: 'elevenlabs_api_key', value: 'your_key_here');
```

#### Seçenek 3: Platform-Specific Storage
- **iOS**: Keychain
- **Android**: EncryptedSharedPreferences

### 3. Firebase Güvenliği
- Firebase Console'dan yeni API anahtarları oluşturun
- Eski anahtarları iptal edin
- Domain kısıtlamaları ekleyin
- API kullanım limitleri belirleyin

## 🛡️ Güvenlik Best Practices

### Kod İçinde API Anahtarları
❌ **YANLIŞ:**
```dart
static const String apiKey = 'sk_1234567890abcdef';
```

✅ **DOĞRU:**
```dart
static String get apiKey => const String.fromEnvironment('API_KEY');
```

### Git Güvenliği
- `.gitignore` dosyasını kontrol edin
- Hassas dosyaları commit'lemeyin
- Git geçmişini temizleyin

### Commit Geçmişini Temizleme
```bash
# Hassas bilgileri git geçmişinden kaldırın
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch lib/services/api_keys.dart" \
  --prune-empty --tag-name-filter cat -- --all
```

## 📋 Kontrol Listesi

- [ ] Eski API anahtarlarını iptal ettiniz mi?
- [ ] Yeni API anahtarlarını güvenli şekilde sakladınız mı?
- [ ] `.gitignore` dosyasını güncellediniz mi?
- [ ] Git geçmişini temizlediniz mi?
- [ ] Firebase güvenlik ayarlarını kontrol ettiniz mi?
- [ ] Environment variables kullanıyor musunuz?

## 🚨 Acil Durum

Eğer API anahtarlarınız açığa çıktıysa:
1. Hemen anahtarları iptal edin
2. Yeni anahtarlar oluşturun
3. Git geçmişini temizleyin
4. Güvenlik taraması yapın

## 📞 Destek

Güvenlik sorunları için:
- GitHub Security Advisories kullanın
- Dependabot alerts'leri aktif edin
- Regular security audits yapın 