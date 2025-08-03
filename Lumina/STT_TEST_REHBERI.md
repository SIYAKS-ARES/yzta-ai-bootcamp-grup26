# Sesten Metne Dönüştürücü Test Rehberi

## 🎯 Test Hedefleri

Bu rehber, Lumina uygulamasının sesten metne dönüştürücü özelliğinin doğru çalıştığını doğrulamak için hazırlanmıştır.

## 📋 Test Senaryoları

### 1. Servis Başlatma Testi
- [ ] Uygulama açıldığında STT servisi otomatik başlatılır
- [ ] Durum kartında "Servis Hazır" mesajı görünür
- [ ] Mikrofon izni istenirse kullanıcı izin verebilir
- [ ] Servis başlatılamazsa hata mesajı gösterilir

### 2. Mikrofon İzni Testi
- [ ] İlk kullanımda mikrofon izni istenir
- [ ] İzin reddedilirse uygun hata mesajı gösterilir
- [ ] İzin verildikten sonra servis çalışır
- [ ] Kalıcı olarak reddedilirse ayarlara yönlendirme önerisi

### 3. Dinleme Başlatma Testi
- [ ] "Dinlemeye Başla" butonuna basıldığında dinleme başlar
- [ ] Buton "Dinlemeyi Durdur" olarak değişir
- [ ] Mikrofon ikonu animasyonlu olarak yanıp söner
- [ ] "Dinleniyor..." mesajı görünür
- [ ] Mevcut dil bilgisi gösterilir

### 4. Ses Tanıma Testi
- [ ] Konuşma yapıldığında metin tanınır
- [ ] Tanınan metin text alanında görünür
- [ ] Karakter sayısı gösterilir
- [ ] Başarı mesajı gösterilir
- [ ] Türkçe karakterler doğru tanınır

### 5. Dinleme Durdurma Testi
- [ ] "Dinlemeyi Durdur" butonuna basıldığında dinleme durur
- [ ] Buton "Dinlemeye Başla" olarak değişir
- [ ] Animasyon durur
- [ ] "Dinleme durduruldu" mesajı gösterilir

### 6. Metin İşlemleri Testi
- [ ] "Temizle" butonu metni temizler
- [ ] "Metni Kaydet" butonu metni dosyaya kaydeder
- [ ] Kaydedilen dosyalar listede görünür
- [ ] Dosya içeriği görüntülenebilir
- [ ] Dosya silinebilir

### 7. Hata Yönetimi Testi
- [ ] Mikrofon erişimi olmadığında uygun hata mesajı
- [ ] Ağ bağlantısı olmadığında uygun hata mesajı
- [ ] Servis başlatılamadığında uygun hata mesajı
- [ ] Hata mesajları kırmızı renkte gösterilir

### 8. Debug Özelliği Testi
- [ ] Debug butonu çalışır
- [ ] Debug bilgileri dialog'da gösterilir
- [ ] Servis durumu, dil bilgisi, hata bilgisi görünür

## 🔧 Test Ortamı Gereksinimleri

### Cihaz Gereksinimleri
- Android 6.0+ veya iOS 12.0+
- Mikrofon donanımı
- İnternet bağlantısı
- Yeterli depolama alanı

### Test Verileri
- Türkçe konuşma örnekleri
- Farklı ses seviyeleri
- Gürültülü ortam simülasyonu
- Uzun ve kısa cümleler

## 📱 Platform Özel Testler

### Android
- [ ] Mikrofon izni dialog'u doğru çalışır
- [ ] Arka plan işlemleri doğru yönetilir
- [ ] Donanım geri butonu doğru çalışır

### iOS
- [ ] Mikrofon izni dialog'u doğru çalışır
- [ ] Ses kalitesi ayarları doğru çalışır
- [ ] Arka plan işlemleri doğru yönetilir

## 🚨 Bilinen Sorunlar ve Çözümler

### Sorun 1: Mikrofon İzni Verilmiyor
**Belirtiler:** "Mikrofon izni gerekli" hatası
**Çözüm:** 
- Ayarlar > Uygulamalar > Lumina > İzinler > Mikrofon
- İzin verildikten sonra uygulamayı yeniden başlat

### Sorun 2: Ses Tanınmıyor
**Belirtiler:** Konuşma yapıldığında metin oluşmuyor
**Çözüm:**
- Net ve yavaş konuşun
- Gürültülü ortamlardan kaçının
- Mikrofonu ağzınıza yakın tutun
- İnternet bağlantısını kontrol edin

### Sorun 3: Servis Başlatılamıyor
**Belirtiler:** "Servis başlatılamadı" hatası
**Çözüm:**
- İnternet bağlantısını kontrol edin
- Uygulamayı yeniden başlatın
- Cihazı yeniden başlatın

## 📊 Performans Metrikleri

### Beklenen Performans
- Servis başlatma süresi: < 3 saniye
- Ses tanıma gecikmesi: < 2 saniye
- Doğruluk oranı: > %90 (Türkçe)
- Bellek kullanımı: < 100MB

### Test Sonuçları
- [ ] Servis başlatma süresi: ___ saniye
- [ ] Ses tanıma gecikmesi: ___ saniye
- [ ] Doğruluk oranı: ___ %
- [ ] Bellek kullanımı: ___ MB

## 🎯 Kullanıcı Deneyimi Testleri

### Kolaylık Kullanım
- [ ] Arayüz sezgisel ve kullanıcı dostu
- [ ] Butonlar doğru boyutlarda
- [ ] Renkler erişilebilir
- [ ] Animasyonlar akıcı

### Erişilebilirlik
- [ ] Ekran okuyucu desteği
- [ ] Yüksek kontrast desteği
- [ ] Büyük yazı tipi desteği
- [ ] Dokunma hedefleri yeterli boyutta

## 📝 Test Raporu

### Test Tarihi: ___
### Test Eden: ___
### Platform: ___
### Cihaz Modeli: ___

### Sonuçlar
- [ ] Tüm testler başarılı
- [ ] Bazı testler başarısız (detaylar aşağıda)
- [ ] Kritik sorunlar var

### Başarısız Testler
1. ___
2. ___
3. ___

### Öneriler
1. ___
2. ___
3. ___

### Sonuç
- [ ] Üretime hazır
- [ ] Daha fazla test gerekli
- [ ] Düzeltmeler gerekli

---

**Not:** Bu test rehberi sürekli güncellenmelidir. Yeni sorunlar veya özellikler eklendiğinde rehber de güncellenmelidir. 