# Changelog

## [Unreleased]

### Market Pulse — operasyon & şeffaflık
- **`ingestedAt` / `ingestedBy`** Firestore alanları `ExternalListingEntity` üzerinden okunur.
- **`MarketPulseListingsMeta`:** «Son senkron» (en güncel CI ingest) + üçüncü taraf veri uyarısı.
- **Boş liste:** Cihazda USB ile doğrulama notu.
- **doc/MARKET_PULSE_OPERATIONS.md** — kablo olmadan yapılabilecek checklist.

## [1.0.5] – 2025-03-19

### Market Pulse — yatırım terminali UI
- **Bölge analizi:** `MarketPulseRegionComparisonStrip` — Kayapınar / Bağlar / Yenişehir için yatay karşılaştırma kartları; fiyat bandı, talep %, mini yarım daire gösterge + sparkline; cam efektli zemin; boş veride varsayılan üçlü (`marketPulseDefaultRegionScores`).
- **Bölge detayı:** Kart dokunuşu → `AppRouter.routeRegionInsight` (`/region-insight/:regionId`, `extra: RegionHeatmapScore`) → `RegionInsightPage` (özet metrikler + Google Haritalar’da «{bölge} Diyarbakır» araması). Varsayılan liste `region_heatmap_defaults.dart` içinde tek kaynak.
- **Derin link:** `app_links` + `emlakmaster://` (Android/iOS/macOS manifest), `PendingDeepLinkStore` (oturum yokken `/region-insight/…` saklanır, girişten sonra `router.go`), `RegionDeepLinkBootstrap`, `regionInsightPathFromUri`, `resolveRegionHeatmapForRoute` için Türkçe/URL decode ile eşleşme. `doc/DEEP_LINKS.md`.
- **Liste satırı:** `MarketPulseInvestmentListingTile` — terminal tarzı kart, sol altın çizgi, tabular fiyat.
- **Fiyat trendi:** ₺ sembolünün solunda yeşil yukarı ok (pozitif trend göstergesi).
- **Emlak tipi rozeti:** Başlık satırı sonunda koyu mavi (#0D47A1) badge + beyaz metin (`propertyType` alanı).
- **Platform kökeni:** «örnek» metni yerine mikro marka rozetleri (S/E/H); `demo` kaynakta üçlü şerit.
- **Başlık metinleri:** Panelde «Yatırım istihbaratı», «Son işlemler — çoklu kaynak» alt başlıkları.

### Harici ilanlar (istemci senkron)
- **`ClientExternalListingsSyncService`:** Blaze olmadan HTML çekme + Firestore yazımı; boşta otomatik örnek seed.
- **`ExternalListingsSyncOutcome`:** `liveWritten`, `demoWritten`, `usedDemoFallback`.
- **`ExternalListingEntity.propertyType`:** Firestore `propertyType` alanı; örnek seed’de kaynak başına sahibinden/emlakjet/hepsiEmlak + gerçekçi başlıklar.

### Rainbow PDF (Analytics Center)
- **`RainbowPdfBuilder`:** Kurumsal yeniden düzen — üst sağ **Rainbow Gayrimenkul**, **Rainbow Analytics Center** filigranı, ince altın çizgi, dairesel skor halkası + üç mini halka, Kayapınar/Bağlar **ızgara tablo** (canlı heatmap veya varsayılan).
- **`DistrictSnapshotRow` / `districtSnapshots`:** Rapor modeli + `buildFullReport` heatmap okuma.
- **doc/RAINBOW_PDF_REPORTING.md**

### Spark (Blaze olmadan) — Market Pulse istemci rollup
- **`MarketPulseClientRollupService`**: `external_listings` → `analytics_daily` heatmap + fırsat keşfi; `source: client_rollup_v1`.
- **Firestore kuralları**: `isClientHeatmapRollup` / `isClientDiscoveryRollup` — giriş yapmış kullanıcı güvenli yazım.
- **`intelligenceRunTriggerProvider`**: throttle’lı rollup; **`ClientExternalListingsSyncService`** sonrası `force` rollup.
- **doc/MARKET_PULSE_SPARK_NO_BLAZE.md**, test: `market_pulse_client_rollup_test.dart`.

### Operasyon scriptleri
- **`scripts/setup_market_pulse_backend.sh`**: Functions deploy + (ADC varsa) `intelligence_pipeline` seed.
- **`scripts/seed_intelligence_pipeline_only.sh`**, **`functions/tools/seed_intelligence_pipeline.js`**: Firestore `app_settings/intelligence_pipeline` (Admin SDK).
- **`scripts/generate_ingest_secret.sh`**: `INGEST_SECRET` üretimi.
- **`doc/OPERATIONS_MARKET_PULSE.md`**: Tek seferlik kurulum özeti.

### Sunucu Market Pulse (Cloud Functions)
- **`scheduledFetchListings`:** 15 dk yerine **6 saatte bir**; doğrudan çekim + **`rollupMarketIntelligence`** (`analytics_daily` heatmap + fırsat keşfi).
- **`ingestListingsPipeline`:** `x-ingest-secret` ile JSON ingest (FlareSolverr / proxy worker); isteğe bağlı **`HTTPS_PROXY`** (Bright Data / Zyte).
- **`httpClient.js`:** Ortak axios + proxy desteği; fetcher’lar buna geçirildi.
- **`app_settings/intelligence_pipeline`:** `clientSeedWritesEnabled` — sunucu rollup kullanılırken istemci demo yazımını kapatma (`BackgroundIntelligenceService`).
- **doc/MARKET_PULSE_SERVERLESS_ARCHITECTURE.md**

### Dokümantasyon ve otomasyon
- **doc/MARKET_PULSE_FREE.md**, **doc/MARKET_PULSE_FIREBASE.md**, **doc/AUTOMATION.md**, **doc/BACKLOG.md**, **doc/QA_CHECKLIST.md** vb. eklendi/güncellendi.
- **Firebase Functions / emülatör:** `scripts/deploy_firebase_functions.sh`, `scripts/run_functions_emulator.sh`; `firebase_functions_bootstrap.dart`.

### iOS / bildirim
- **AppDelegate / SceneDelegate:** Uzaktan bildirim kaydı ve FCM hazırlığı ile ilgili güncellemeler.

### Shield uyumu
- Değişiklikler `scripts/shield/` ile uyumlu tutuldu; çalıştırma: `scripts/shield/shield.sh`, `scripts/run_with_shield.sh`, `scripts/build_with_shield.sh`.

---

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
