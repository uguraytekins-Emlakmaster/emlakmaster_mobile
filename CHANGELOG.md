# Changelog

## [1.0.2] – 2025-03-15

### Eklenenler
- **Dashboard pull-to-refresh**: Aşağı çekince KPI, Market Pulse, Discovery, Daily Brief, Missed Opportunities ve intelligence verileri yenilenir.
- **Market Pulse**: Harici ilan görselleri için `cached_network_image` (placeholder + hata görseli).
- **Market Pulse "İlanları güncelle"**: Cloud Functions `fetchListingsNow` callable tetikleyen buton (europe-west1).
- **Tutarlı hata ekranı**: Tüm async panellerde (Market Pulse, Discovery, Daily Brief, Missed Opportunities, Opportunity Radar) ErrorState + "Tekrar Dene" butonu.
- **Offline bant**: Çevrimdışıyken üstte "İnternet yok. Veriler önbellekten gösteriliyor." bantı (SyncStatusBanner güncellendi).
- **Skeleton loader**: İlgili panellerde yükleme durumunda spinner yerine SkeletonLoader kullanımı.
- **Haptic feedback**: Tekrar Dene, Başla, Giriş, logo seçimi, İlanları güncelle gibi önemli aksiyonlarda titreşim.
- **Ayarlar yardım metni**: İlan kaynakları & ofis bölümünde bilgi ikonu + tooltip açıklaması.
- **Firebase Analytics**: Ekran görüntüleme (NavigatorObserver), giriş olayları (email/google), `AnalyticsService` (logEvent, logListingView, logSettingsChange).
- **Onboarding**: İlk açılışta 2 slayt + "Başla"; SharedPreferences ile bir kez gösterim.
- **CI**: `.github/workflows/ci.yml` — `flutter pub get`, `flutter analyze --no-fatal-infos`, `flutter test`.
- **Widget testleri**: `test/error_state_test.dart` (ErrorState).

### Bağımlılıklar
- `cached_network_image: ^3.4.1`
- `firebase_analytics: ^11.3.3`
- `cloud_functions: ^5.2.0`

### Notlar
- Cloud Functions `fetchListingsNow` deploy edilmiş olmalı (region: europe-west1).
- Onboarding tamamlandığında `onboarding_completed` anahtarı SharedPreferences’a yazılır.
