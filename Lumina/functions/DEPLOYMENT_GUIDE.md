# Lumina TTS Deployment Kılavuzu

Bu kılavuz, Lumina TTS özelliğinin Firebase'e deploy edilmesi için gereken tüm adımları açıklar.

## Ön Koşullar

1. **Node.js 18+** kurulu olmalı
2. **Firebase CLI** kurulu olmalı
3. **Google Cloud Project** oluşturulmuş olmalı
4. **Firebase projesi** oluşturulmuş olmalı

## 1. Firebase Kurulumu

### Firebase CLI Kurulumu
```bash
npm install -g firebase-tools
```

### Firebase'e Giriş
```bash
firebase login
```

### Proje Başlatma (eğer henüz yapılmadıysa)
```bash
# Proje root dizininde
firebase init

# Şunları seçin:
# - Functions (Node.js)
# - Firestore
# - Storage
# - Hosting (isteğe bağlı)
```

## 2. Google Cloud APIs Etkinleştirme

Google Cloud Console'da şu API'leri etkinleştirin:

1. **Cloud Text-to-Speech API**
   - Console: https://console.cloud.google.com/apis/library/texttospeech.googleapis.com
   - "Enable" butonuna tıklayın

2. **Cloud Functions API** (otomatik etkinleşir)
3. **Cloud Firestore API** (otomatik etkinleşir)
4. **Firebase Storage API** (otomatik etkinleşir)

## 3. Güvenlik Kurallarını Deploy Etme

### Firestore Rules
```bash
# firestore.rules dosyasını deploy edin
firebase deploy --only firestore:rules
```

### Storage Rules
```bash
# storage.rules dosyasını deploy edin
firebase deploy --only storage
```

## 4. Cloud Functions Deploy

### Dependencies Kurulumu
```bash
cd functions
npm install
```

### Build Test
```bash
npm run build
```

### Deploy
```bash
# Tüm functions'ları deploy et
npm run deploy

# Veya sadece belirli function'ı deploy et
firebase deploy --only functions:processDocumentForTTS
```

## 5. Firebase Console Konfigürasyonu

### Authentication Setup
1. Firebase Console → Authentication → Sign-in method
2. Email/Password provider'ı etkinleştirin
3. (Opsiyonel) Google provider'ı da etkinleştirin

### Firestore Database
1. Console → Firestore Database → Create database
2. "Start in production mode" seçin
3. Lokasyon seçin (europe-west3 önerilir)

### Storage
1. Console → Storage → Get started
2. Güvenlik kurallarını "Production mode" ile başlatın
3. Lokasyon seçin (europe-west3 önerilir)

## 6. Monitoring ve Logging

### Function Logs
```bash
# Real-time logs
firebase functions:log

# Specific function logs
firebase functions:log --only processDocumentForTTS
```

### Cloud Console'dan Monitoring
- Functions performance: Cloud Console → Cloud Functions
- TTS API usage: Cloud Console → APIs & Services → Text-to-Speech API
- Storage usage: Firebase Console → Storage

## 7. Test ve Doğrulama

### Health Check Test
```bash
curl https://europe-west1-[PROJECT_ID].cloudfunctions.net/healthCheck
```

### Function Test (Local)
```bash
cd functions
npm run serve
```

### Integration Test
1. Flutter uygulamasından dosya yükleyin
2. Firestore'da task oluşturulduğunu kontrol edin
3. Function logs'ları kontrol edin
4. Storage'da audio dosyası oluşturulduğunu kontrol edin

## 8. Production Optimizasyonları

### Function Performance
```javascript
// functions/src/index.ts içinde
.runWith({
  timeoutSeconds: 300,
  memory: "1GB",
  maxInstances: 10  // Aynı anda max 10 instance
})
```

### Cost Optimization
1. **Storage Lifecycle Rules**: Eski dosyaları otomatik sil
2. **Function Timeout**: Gereksiz uzun timeout'ları azalt
3. **TTS Character Limits**: Metin uzunluğunu 5000 karakterle sınırla

### Error Handling
- Function retry logic'i kontrol edin
- Dead letter queues kurabilirsiniz
- Alerting için Cloud Monitoring kullanın

## 9. Güvenlik Best Practices

### Service Account Permissions
- Firebase functions otomatik olarak gerekli izinleri alır
- Manual service account gerekli değil

### Network Security
- Functions sadece HTTPS üzerinden erişilebilir
- CORS ayarları gerekirse yapılandırın

### Data Privacy
- Kullanıcı dosyaları kendi klasörlerine kayıt edilir
- Ses dosyaları signed URL ile paylaşılır
- Firestore rules kullanıcı seviyesinde erişim kontrolü sağlar

## 10. Troubleshooting

### Common Issues

**Function Deploy Hatası:**
```bash
# Node.js version check
node --version  # Should be 18+

# Clear npm cache
npm cache clean --force

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

**TTS API Quota Exceeded:**
- Google Cloud Console'dan TTS quota'yı artırın
- Billing account'ınızın aktif olduğundan emin olun

**Storage Permission Denied:**
- Storage rules'ları kontrol edin
- Authentication durumunu kontrol edin

**Function Timeout:**
- Büyük dosyalar için timeout'ı artırın
- Memory allocation'ı kontrol edin

### Logs ve Debugging
```bash
# Function logs
firebase functions:log

# Firestore logs
# Firebase Console → Firestore → Usage tab

# Storage logs
# Firebase Console → Storage → Usage tab
```

## 11. Production Deployment Checklist

- [ ] All APIs enabled
- [ ] Firestore rules deployed
- [ ] Storage rules deployed
- [ ] Functions deployed successfully
- [ ] Authentication configured
- [ ] Health check returns 200
- [ ] Test file upload works
- [ ] Test TTS conversion works
- [ ] Monitoring alerts configured
- [ ] Backup strategy in place

## Support

- Firebase Documentation: https://firebase.google.com/docs
- Cloud Functions: https://firebase.google.com/docs/functions
- TTS API: https://cloud.google.com/text-to-speech/docs 