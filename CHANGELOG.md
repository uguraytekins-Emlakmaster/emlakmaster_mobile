# Changelog

## [1.0.4] – 2025-03-15

### Performans (No-Lag)
- **Deferred init:** SyncManager, OnboardingStore, Hive (AppCacheService) ilk frame sonrası; ilk paint hızlandı.
- **Deferred sayfalar:** War Room, Broker Command, Command Center lazy yükleme (`deferred_dashboard_pages.dart`).
- **CachedNetworkImage + Shimmer:** İlan/liste görselleri; placeholder shimmer.
- **Riverpod `.select()`:** Pipeline, bildirimler, görevler, danışman paneli — gereksiz rebuild azaltıldı.
- **Portfolio match isolate:** Ağır eşleştirme `compute()` ile UI thread dışında.
- **RepaintBoundary:** War room, müşteri/ilan listesi item’larında.
- **Hive / AppCacheService:** Yerel cache; init post-frame.

### Rehber ve uygulamaya kaydet (Contact Save)
- **Sesli komut + manuel:** PostCallWizard ve CustomerCard’dan rehbere + Firestore müşteri kaydı.
- **extract_contact_from_voice:** Türkçe isim/telefon/not çıkarma.
- **SaveContactSheet:** “Rehbere kaydet” / “Uygulamaya kaydet” seçenekleri; FirestoreService.createCustomer().

### Özel rehber izin akışı
- **permission_handler:** İzin durumu (granted / denied / permanentlyDenied).
- **ContactPermissionHelper:** İstek + kalıcı red kontrolü + `openSystemSettings()` (Ayarlara git).
- **SaveToDeviceResult:** success / denied / permanentlyDenied; kalıcı redde “Rehber izni kapalı” diyaloğu + “Ayarlara git” butonu.

### Platform izinleri
- iOS/Android/macOS rehber, mikrofon, konuşma tanıma, galeri/kamera tanımlı; tablo `doc/PLATFORM_PERMISSIONS.md` güncellendi.

### Stabilite
- **finance_bar:** Overflow düzeltmesi (font/padding/constraint).
- **FinanceService:** Null-safe JSON; hata durumunda cache/varsayılan oran.
- **PushNotificationService:** getToken() macOS/web’de çağrılmıyor (APNS hatası önlenir).
- **macOS Podfile:** platform :osx 11.0 (speech_to_text uyumu).

### Dokümantasyon
- **doc/GUNCELLEMELER_BAGLAMLAR.md:** Tüm güncellemeler bağlamlarıyla (performans, izinler, contact save, stabilite, dosya referansları).
- **doc/PERFORMANCE.md**, **doc/PLATFORM_PERMISSIONS.md**, **doc/CONTACT_SAVE_FEATURE.md** güncellendi.

### Bağımlılıklar
- `permission_handler: ^11.3.1`

---

## [1.0.3] – 2025-03-15

### Premium UI/UX ve efektler
- **Shimmer**: İlan görselleri yüklenirken `ShimmerPlaceholder` (shimmer paketi) ile yükleme efekti.
- **Hero animasyonları**: Market Pulse ilan kartlarında görsele `Hero` tag eklendi (detay sayfasına geçişte kullanılabilir).
- **AnimateDo**: Market Pulse ilan listesinde `FadeInUp` ile sıralı giriş animasyonu.
- **Etkileşimli butonlar**: `PressableScaleButton` — basıldığında hafif küçülme + haptic; Empty State aksiyonunda kullanıldı.
- **Renk paleti (Rainbow Gayrimenkul)**: Lacivert (`#1A237E`), Altın (`#D4AF37`), Beyaz — `DesignTokens` ve `AppTheme` güncellendi. Dark/Light mode destekli.
- **AppToaster**: Başarı/hata/uyarı/bilgi için tutarlı floating SnackBar (ikon + renk). Market Pulse, SyncStatusBanner, ayarlar logo mesajları buna taşındı.
- **Empty State**: Premium illüstrasyon alanı (gradient daire + ikon), opsiyonel `illustration` widget.

### Bağımlılıklar
- `shimmer: ^3.0.0`
- `animate_do: ^4.2.0`

---

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
