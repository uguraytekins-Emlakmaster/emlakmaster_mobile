# Rainbow CRM — Üretim tek özeti (consolidation)

**Amaç:** Önceki prompt çıktıları, mimari dokümanlar ve kod tabanını tek çatı altında birleştirmek. Paralel mimari yok; mevcut Flutter + Firebase + Functions hattı genişletilir.

**Son güncelleme:** Consolidation pass (analytics tek kaynak + bu doküman).

---

## A. What already exists (tamamlanan / kullanılabilir)

| Alan | Durum | Konum / not |
|------|--------|----------------|
| **Auth** | Üretim kalitesi | E-posta, Google; `AuthService`, `LoginAttemptGuard`, `PRODUCTION_AUTH_AND_SCALE.md` |
| **Routing** | Tek `GoRouter` | `lib/core/router/app_router.dart` |
| **Analytics** | Tek sarmalayıcı + olay sabitleri | `AnalyticsService`, `lib/core/analytics/analytics_events.dart` — özel `logEvent` isimleri burada |
| **Ekran görüntüsü** | Route observer | `_AnalyticsRouteObserver` — `logScreenView` route `name` ile (dashboard’da `build()` içinde tekrarlı log **yok**) |
| **Harici ilanlar (Market Pulse)** | İstemci rollup + Functions | `external_listings`, scheduled fetch |
| **Entegrasyon ilanları** | Sunucu yazımı | `integration_listings` + `integrationListingsAdmin.js` |
| **Import Engine** | Kod + kurallar (deploy gerekir) | `functions/listingImportEngine/`, `RAINBOW_CORE_IMPORT_ENGINE.md`, Flutter `listing_import` feature |
| **Shield / iOS** | Pod senkronu | `scripts/shield/fixers/03_ios_pods.sh`; tam onarım: `scripts/ios_pod_repair.sh` |
| **Kök script kısayolları** | Tekil mantık yok | `run_listings_ingest_do_everything.sh` → `scripts/`, `push_firebase_secret_to_github.sh` → `scripts/github_listings_push_secret.sh` |
| **Özellik bayrakları** | SharedPreferences | `AppConstants.keyFeature*` + `SettingsService` / `feature_flags_provider` |

---

## B. Duplicate / conflicting areas (tespit)

| Konu | Açıklama | Çözüm |
|------|-----------|--------|
| **Analytics olay isimleri** | String dağınık kullanım | **Birleştirildi:** `AnalyticsEvents` + tüm çağrı / dashboard / device sync güncellendi |
| **Ekran analytics** | Dashboard’da `build()` içinde `logScreenView` (her rebuild’de tekrar riski) | **Kaldırıldı** — sadece `GoRouter` observer |
| **iOS Pod** | `shield 03` vs `ios_pod_repair` | **Çakışma değil:** shield otomatik hafif; `ios_pod_repair` manuel derin onarım |
| **Import / ingest scriptleri** | Kök `*.sh` vs `scripts/*.sh` | **Duplicate mantık yok** — kök dosyalar `exec` ile yönlendirir |
| **Harici piyasa API** | `ExternalMarketApiPlaceholder` | **Tek “boş” adaptör** — Intel raporu fail-safe; gerçek API sonrası aynı arayüz |

---

## C. What should be kept (korunacaklar)

- **Tek Firebase projesi** — `lib/firebase_options.dart` (tek kaynak).
- **Tek Analytics girişi** — `AnalyticsService`; özel olay adları `AnalyticsEvents`.
- **Mevcut özellik bayrakları** — `AppConstants` + ayarlar; yeni bayraklar için aynı desen.
- **Import Engine modülü** — Functions’da `listingImportEngine/`; istemci `listing_import/`; paralel ikinci “import sistemi” yazma.
- **Shield** — `scripts/shield/shield.sh` + `pub_get_with_fix.sh` / `run_with_shield.sh` (koruma kalkanı).
- **Master mimari** — `RAINBOW_PROTECH_OS_MASTER_ARCHITECTURE.md` (kapsam sınırı).

---

## D. What should be removed or merged (kaldır / birleştir)

| Öğe | Aksiyon |
|-----|---------|
| Dağınık `logEvent('...')` stringleri | **Kaldırıldı** — `AnalyticsEvents` kullan |
| Dashboard’da `build()` içi `logScreenView` | **Kaldırıldı** (zaten yapıldı) |
| Yeni paralel “AnalyticsService2” veya ikinci Analytics wrapper | **Oluşturma** |
| Aynı işi yapan ikinci `listing_import` koleksiyonu | **Oluşturma** — `listing_import_tasks` tek |

---

## E. Final unified roadmap (öncelik sırası)

1. **Release hazırlığı** — `firebase deploy` (Functions + Firestore rules + indexes + Storage), mağaza varlıkları, sürüm numarası (`pubspec`).
2. **Crashlytics sembolleri** — `firebase_app_id_file.json` / `flutterfire configure` (build uyarısı giderilir).
3. **App Check** (opsiyonel ama önerilir) — prod’da abuse azaltma; `PRODUCTION_AUTH_AND_SCALE.md` ile uyumlu.
4. **Import Engine canlı doğrulama** — `enqueueUrlImport` / `extensionImport` uçlarında smoke test.
5. **Harici OAuth** — `stub_platform_adapter` yerine gerçek adapter; capability flag ile aç.
6. **Retention** — Push (`PushNotificationService`) + `feature_flags` ile kampanya / bölüm aç-kapa; ayrı bir “retention SDK” yok.
7. **Monetization** — Uygulama içi IAP/abonelik **yok**; roadmap’e “ürün kimliği + mağaza” eklendiğinde tek `AppConstants` / Remote Config ile yönetilecek şekilde tasarlandı (şu an Remote Config yok).

---

## F. Highest-priority next implementation step

**Tamamlandı (bu consolidation):** Analytics olaylarının `AnalyticsEvents` altında tekilleştirilmesi + dashboard’da hatalı ekran tekrarının önlenmesi.

**Sıradaki en yüksek öncelik (üretim):** Firebase tarafında Import Engine + güncel kuralların **deploy edilmesi** ve indekslerin uygulanması — aksi halde istemci `listing_import` görevleri kuyrukta kalabilir veya sorgu hatası verebilir.

```bash
cd emlakmaster_mobile
bash scripts/deploy_production_stack.sh
# Storage henüz Firebase Console'da açılmadıysa (ilk kurulum):
bash scripts/deploy_production_stack.sh --no-storage
# Sonra: https://console.firebase.google.com/project/emlak-master/storage → Get Started
# Ardından Storage kurallarını da dahil ederek tekrar tam deploy.
```

Ardından: **Crashlytics** için `flutterfire configure` veya `firebase_app_id_file.json` üretimi (iOS upload-symbols uyarısı).

---

## Tek kaynak tabloları

### MVP scope (özet)

- **V1:** Auth, CRM çekirdek (müşteri, çağrı, pipeline, ilan görüntüleme), Market Pulse, bağlı hesaplar UI, import hub (URL/dosya), mesaj merkezi dürüst “desteklenmiyor” durumu (API yoksa).
- **Bilinçli olarak kapalı / stub:** OAuth ile tam portal senkronu (`stub_platform_adapter`), `ExternalMarketApiPlaceholder` canlı API.

### Monetization

- **Şu an:** Kod tabanında satın alma / abonelik akışı yok.
- **Gelecekte:** Tek `ProductIds` sınıfı + mağaza politikası (tek dosyada toplanacak); şimdilik dokümana yazıldı, kod eklenmedi (duplicate sistem yok).

### Retention

- Push bildirimleri (`PushNotificationService`), ayarlardan aç/kapa, güç tasarrufu.
- Ek: günlük özet / resurrection engine (mevcut feature’lar).

### Analytics

- **Olay adları:** `lib/core/analytics/analytics_events.dart`
- **Sarmalayıcı:** `lib/core/services/analytics_service.dart`
- **Ekran:** `GoRouter` + `_AnalyticsRouteObserver`

### Live-ops

- Firestore `app_settings` / feature flags (istemci `SettingsService`).
- Functions: scheduled işler, ingest webhook’ları (mevcut `functions/index.js`).

### Release readiness

| Kontrol | Durum |
|---------|--------|
| `flutter analyze` | CI’de çalıştırılmalı |
| iOS `pod install` | Xcode öncesi / Shield |
| Firestore rules + indexes deploy | Zorunlu |
| Functions deploy | Import Engine için zorunlu |
| `firebase_app_id_file.json` | Crashlytics iOS önerilir |

---

## İlgili dosyalar (bu consolidation’da değişen)

- `lib/core/analytics/analytics_events.dart` — parametre anahtarları genişletildi.
- `lib/core/services/analytics_service.dart` — `AnalyticsEvents` ile uyum (açıklama).
- `lib/screens/consultant_dashboard_page.dart` — `AnalyticsEvents` + gereksiz `logScreenView` yok.
- `lib/features/calls/presentation/pages/consultant_calls_page.dart` — `AnalyticsEvents`.
- `lib/features/calls/data/device_call_log_sync_service.dart` — `AnalyticsEvents`.

---

## Bu oturum özeti

| Madde | Durum |
|-------|--------|
| Tamamlanan iş | Analytics tek kaynak; çağrı akışı olayları sabitlendi |
| Oluşturulan / güncellenen | Yukarıdaki Dart dosyaları + bu doküman |
| Kalan blokörler | Firebase deploy; Crashlytics dosyası; mağaza inceleme |
| Sonraki en iyi aksiyon | `firebase deploy` (Functions + rules + indexes + storage) |
