# Dosya Yükleme ve TTS Test Rehberi

## 🎯 Yeni Özellikler

### ✅ Düzeltilen Sorunlar:
1. **Dosyalar artık uygulama içinde kalıcı olarak saklanıyor**
2. **Yüklenen dosyalar listesi görüntüleniyor**
3. **Dosyalar tekrar yüklenebiliyor**
4. **Dosyalar silinebiliyor**
5. **Dosya boyutu gösteriliyor**

## 📁 Test Dosyaları

### 1. TXT Dosyası
- **Dosya**: `test_dosyasi.txt`
- **İçerik**: Türkçe test metni
- **Boyut**: ~500 byte

### 2. PDF Dosyası
- **Dosya**: `test_dosyasi.pdf`
- **İçerik**: Basit PDF test metni
- **Boyut**: ~1 KB

## 🔧 Test Adımları

### Adım 1: Uygulamayı Başlatın
```bash
cd Lumina
flutter run
```

### Adım 2: Text-to-Speech Sayfasına Gidin
- Ana sayfada "Metinden Sese" özelliğine tıklayın

### Adım 3: TXT Dosyası Testi
1. **"PDF/TXT Dosyası Seç" butonuna tıklayın**
2. **test_dosyasi.txt dosyasını seçin**
3. **Beklenen sonuçlar**:
   - ✅ Dosya yüklendi mesajı görünmeli
   - ✅ Metin kutusuna içerik yazılmalı
   - ✅ "Yüklenen Dosyalar" bölümünde dosya listelenmeli
   - ✅ Dosya boyutu gösterilmeli

### Adım 4: PDF Dosyası Testi
1. **"PDF/TXT Dosyası Seç" butonuna tıklayın**
2. **test_dosyasi.pdf dosyasını seçin**
3. **Beklenen sonuçlar**:
   - ✅ PDF'den metin çıkarılmalı
   - ✅ Metin kutusuna yazılmalı
   - ✅ Dosya listesinde görünmeli

### Adım 5: Yüklenen Dosyaları Test Edin
1. **"Yüklenen Dosyalar" bölümünü bulun**
2. **Dosya yanındaki ▶️ butonuna tıklayın**
3. **Beklenen sonuç**: Dosya içeriği yüklenmeli ve oynatılabilir olmalı

### Adım 6: Dosya Silme Testi
1. **Dosya yanındaki 🗑️ butonuna tıklayın**
2. **Beklenen sonuç**: Dosya listeden kaldırılmalı

### Adım 7: TTS Testi
1. **Yüklenen metni oynatın**
2. **Beklenen sonuç**: Metin sesli olarak okunmalı

## 📱 Dosya Yönetimi Özellikleri

### ✅ Kalıcı Depolama
- Dosyalar uygulama dizininde saklanır
- Uygulama kapanınca dosyalar kaybolmaz
- Benzersiz dosya adları oluşturulur

### ✅ Dosya Listesi
- Yüklenen tüm dosyalar görüntülenir
- Dosya boyutu gösterilir
- Dosya türü ikonu gösterilir (PDF/TXT)

### ✅ Dosya İşlemleri
- **Yükle**: Dosyayı tekrar yükle
- **Sil**: Dosyayı kalıcı olarak sil
- **Oynat**: Dosya içeriğini TTS ile oynat

## 🔍 Debug Bilgileri

### Konsol Çıktıları:
```
Dosya yöneticisi başlatıldı: /path/to/app/documents/uploaded_files
Seçilen dosya: /path/to/selected/file.txt
Dosya kopyalandı: /path/to/app/documents/uploaded_files/file_1234567890.txt
Dosya işlendi: /path/to/app/documents/uploaded_files/file_1234567890.txt, Metin uzunluğu: 150
Yüklenen dosyalar: 2
```

### Hata Durumları:
- **"Kaynak dosya bulunamadı"**: Dosya seçimi başarısız
- **"Dosya kopyalanamadı"**: İzin sorunu
- **"Dosyadan metin çıkarılamadı"**: Format sorunu

## 🎯 Test Kontrol Listesi

### Dosya Yükleme:
- [ ] TXT dosyası yükleniyor
- [ ] PDF dosyası yükleniyor
- [ ] Dosya listesinde görünüyor
- [ ] Dosya boyutu gösteriliyor
- [ ] Benzersiz dosya adları oluşturuluyor

### Dosya İşlemleri:
- [ ] Dosya tekrar yüklenebiliyor
- [ ] Dosya silinebiliyor
- [ ] Dosya içeriği TTS ile okunabiliyor
- [ ] Hata mesajları doğru gösteriliyor

### TTS Özellikleri:
- [ ] Manuel metin okunuyor
- [ ] Yüklenen dosya metni okunuyor
- [ ] Hızlı örnekler çalışıyor
- [ ] Debug fonksiyonu çalışıyor

## 🚀 Performans İpuçları

1. **Büyük dosyalar için**: Dosya boyutunu kontrol edin
2. **Çoklu dosya**: Birden fazla dosya yükleyebilirsiniz
3. **Dosya temizliği**: Kullanılmayan dosyaları silin
4. **Bellek yönetimi**: Çok fazla dosya yüklemeyin

## 🔧 Sorun Giderme

### Dosya Yüklenmiyorsa:
1. **Dosya izinlerini kontrol edin**
2. **Desteklenen formatları kullanın** (.txt, .pdf)
3. **Dosya boyutunu kontrol edin**
4. **Debug butonuna tıklayın**

### TTS Çalışmıyorsa:
1. **Cihaz sesini kontrol edin**
2. **Farklı metin deneyin**
3. **Debug bilgilerini kontrol edin**
4. **Uygulamayı yeniden başlatın**

---

**Not**: Artık dosyalar kalıcı olarak saklanıyor ve görme engelli bireyler için daha güvenilir bir deneyim sunuluyor! 