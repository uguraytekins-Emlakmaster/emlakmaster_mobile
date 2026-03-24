# Market Pulse – Cloud Functions (çekim + rollup + ingest)

Bu klasör:

1. **Doğrudan HTML** (sahibinden / emlakjet / hepsi emlak) – `axios` + `cheerio` – Cloudflare yüzünden çoğu zaman **boş** dönebilir.
2. **`rollupMarketPulse.js`** – `external_listings` → `analytics_daily` (**heatmap** + **fırsat keşfi**).
3. **`ingestListingsPipeline`** – FlareSolverr / Selenium / ücretli proxy worker’ınızdan **JSON POST** ile doldurma.

Uygulama telefonda **sadece Firestore dinler** (pil dostu). Mimari: `doc/MARKET_PULSE_SERVERLESS_ARCHITECTURE.md`.

## Kurulum

```bash
cd functions
npm install
```

Örnek ortam değişkenleri: `.env.example` (Firebase Console / Cloud üzerinde tanımlayın).

## Dağıtım

**Önemli:** Firebase projesi **Blaze (pay-as-you-go)** olmalı; Spark planda Cloud Functions deploy edilemez.

```bash
# Proje kökünden (emlakmaster_mobile)
./scripts/deploy_firebase_functions.sh
```

Alternatif:

```bash
cd functions && npm install && cd .. && firebase deploy --only functions --project emlak-master
```

Yerel emülatör (Blaze gerekmez, `USE_FUNCTIONS_EMULATOR=true` ile uygulama bağlanır):

```bash
./scripts/run_functions_emulator.sh
```

Ayrıntı: `doc/MARKET_PULSE_FIREBASE.md`.

## Fonksiyonlar

| Export | Açıklama |
|--------|-----------|
| **scheduledFetchListings** | **Her 6 saatte bir** (Europe/Istanbul): `SCRAPER_MODE` ≠ `ingest_only` ise doğrudan çekim; ardından **rollup**. |
| **ingestListingsPipeline** | HTTPS `POST`, header `x-ingest-secret`. Body: `{ "listings": [ ... ] }`. Sonra rollup. |
| **fetchListingsNow** | Callable (`onCall`), **oturum zorunlu**. Manuel çekim + rollup. |

### Ortam

- `SCRAPER_MODE`: `hybrid` (varsayılan) \| `ingest_only` \| `direct_only`
- `INGEST_SECRET`: ingest endpoint’i için
- `HTTPS_PROXY` / `HTTP_PROXY`: Bright Data, Zyte vb. residential proxy (isteğe bağlı)

## Ayarlar

- İlanlar: `app_settings/listing_display_settings` → `cityCode`, `cityName`, `districtName`.
- İstemci demo vs sunucu: `app_settings/intelligence_pipeline` → `clientSeedWritesEnabled` (sunucu aktifken `false` önerilir).

## Harici hesap senkronu — `integration_listings`

Mobil uygulama **Benim İlanlarım** ekranı `integration_listings` koleksiyonunu okur; yazma **yalnızca Admin SDK**.

- Yardımcı modül: **`integrationListingsAdmin.js`** — `ownerUserId` (Firebase Auth uid) zorunlu; `upsertIntegrationListing(db, docId, ownerUserId, fields)`.
- Şema ve deploy: `doc/INTEGRATION_LISTINGS_SERVER_CONTRACT.md`.

Rainbow / OAuth senkronu bu modülü `index.js` içinden (HTTPS veya scheduled) çağıracak şekilde bağlanmalıdır.

## Notlar

- Site HTML yapıları zamanla değişebilir; `fetchers/*.js` güncellenebilir.
- Kullanım şartları ve robots.txt sizin sorumluluğunuzdadır.
- `cityCode` sorgusu için gerekirse Firestore index konsoldan eklenir.
