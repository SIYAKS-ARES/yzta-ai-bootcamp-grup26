# Lumina TTS Firebase Cloud Functions

Bu klasör, Lumina uygulamasının Text-to-Speech (Metinden Sese) özelliği için Firebase Cloud Functions kodlarını içerir.

## Özellikler

- **Otomatik Belge İşleme**: PDF ve DOCX dosyalarından metin çıkarma
- **Google Cloud TTS Entegrasyonu**: Yüksek kaliteli Türkçe ses sentezi
- **Firebase Storage Entegrasyonu**: Dosya yükleme ve ses dosyası saklama
- **Firestore Real-time Updates**: Anlık durum güncellemeleri
- **Güvenlik**: Kullanıcı kimlik doğrulaması ve yetkilendirme

## Kurulum

### 1. Bağımlılıkları Yükle
```bash
cd functions
npm install
```

### 2. Firebase CLI Kurulumu (eğer kurulu değilse)
```bash
npm install -g firebase-tools
```

### 3. Firebase'e Giriş Yap
```bash
firebase login
```

### 4. Google Cloud TTS API'yi Etkinleştir
- Google Cloud Console'da projenizi açın
- Text-to-Speech API'yi etkinleştirin
- Service account key oluşturun (opsiyonel, Firebase projesi otomatik kullanır)

## Geliştirme

### Local Test
```bash
npm run serve
```

### Build
```bash
npm run build
```

### Deploy
```bash
npm run deploy
```

## Cloud Functions

### 1. processDocumentForTTS
- **Trigger**: Firebase Storage'a dosya yüklendiğinde otomatik çalışır
- **İşlev**: PDF/DOCX dosyalarını MP3 ses dosyasına dönüştürür
- **Bölge**: europe-west1
- **Timeout**: 300 saniye
- **Memory**: 1GB

### 2. healthCheck
- **Type**: HTTP Request
- **İşlev**: Servisin durumunu kontrol eder
- **URL**: `https://europe-west1-[PROJECT_ID].cloudfunctions.net/healthCheck`

### 3. getTaskStatus
- **Type**: Callable Function
- **İşlev**: Görev durumunu manuel olarak kontrol eder
- **Güvenlik**: Kimlik doğrulaması gerekli

## Dosya Yapısı

```
uploads/[userId]/[taskId].pdf|docx  → Yüklenen dosyalar
audio/[userId]/[taskId].mp3         → Oluşturulan ses dosyaları
```

## Firestore Koleksiyonları

### tasks Collection
```typescript
{
  id: string,           // Task ID
  userId: string,       // Kullanıcı ID
  fileName: string,     // Dosya adı
  status: string,       // pending | processing | completed | failed
  audioUrl?: string,    // Ses dosyası URL'i
  audioPath?: string,   // Storage'daki ses dosyası yolu
  errorMessage?: string,// Hata mesajı (eğer varsa)
  processedTextLength: number, // İşlenen metin uzunluğu
  createdAt: Timestamp,
  updatedAt?: Timestamp
}
```

## Hata Durumları

- **Desteklenmeyen dosya formatı**: Sadece PDF ve DOCX desteklenir
- **Boş dosya**: Metin çıkarılamayan dosyalar
- **TTS API hatası**: Google Cloud TTS servisi hataları
- **Storage hatası**: Firebase Storage bağlantı sorunları
- **Firestore hatası**: Veritabanı bağlantı sorunları

## Güvenlik

- Tüm dosya yüklemeleri kullanıcı kimlik doğrulaması gerektirir
- Her kullanıcı sadece kendi dosyalarına erişebilir
- Ses dosyaları signed URL ile güvenli şekilde paylaşılır

## Monitoring

- Firebase Console'dan function logs'ları kontrol edin
- Cloud Functions metrics'ları izleyin
- Firestore usage'ı takip edin

## Troubleshooting

### Function Deploy Hatası
- Firebase CLI sürümünü kontrol edin
- Node.js sürümünün 18 olduğundan emin olun
- TypeScript derlemesi başarılı mı kontrol edin

### TTS API Hatası
- Google Cloud TTS API'nin etkinleştirildiğini kontrol edin
- API quota'nızı kontrol edin
- Service account permissions'ları kontrol edin

### Storage Hatası
- Firebase Storage rules'ları kontrol edin
- Dosya boyut limitlerini kontrol edin
- Network bağlantısını kontrol edin 