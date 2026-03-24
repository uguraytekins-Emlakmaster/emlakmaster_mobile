# Market Pulse & Fırsat Radarı — sunucu odaklı mimari ($0 → ölçek)

Bu doküman **pil dostu** (ağır iş telefonda değil), **tek doğruluk kaynağı** (Firestore) ve **Cloudflare** gerçeği ile uyumlu bir veri akışını tanımlar.

## İlkeler

| İlke | Uygulama |
|------|-----------|
| Pil | Uygulama yalnızca **Firestore snapshot** dinler; HTML parse / tarayıcı yok. |
| Kota | Zamanlayıcı **6 saatte bir**; gereksiz 15 dk döngü yok. |
| Maliyet | **$0**: kendi Oracle/GCP free tier VPS’inizde FlareSolverr + scraper; veya **ücretli** residential proxy (Bright Data / Zyte). |
| Cloudflare | Ham `axios` ile çoğu sitede **bot sayfası** döner; üretimde **ingest pipeline** veya **proxy** gerekir. |

## Veri akışı (özet)

```
┌─────────────────────────────────────────────────────────────────┐
│  A) Ücretsiz yol ($0)                                            │
│  [FlareSolverr + scraper] → (VPS / cron) → POST ingest JSON      │
│       ↓                                                           │
│  [Cloud Functions ingestListingsPipeline] → external_listings    │
│       ↓                                                           │
│  [rollupMarketIntelligence] → analytics_daily (heatmap, discovery)│
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  B) Ücretli proxy (Bright Data / Zyte residential)               │
│  Cloud Functions HTTP istemcisi: HTTPS_PROXY ortam değişkeni     │
│  → fetchers (sahibinden / emlakjet / hepsi) aynı kod            │
│  → yine rollup → Firestore                                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Mobil uygulama (Flutter)                                        │
│  StreamProvider → analytics_daily + external_listings snapshots  │
│  (yenileme yok; gerçek zamanlı güncelleme)                        │
└─────────────────────────────────────────────────────────────────┘
```

## Firestore yapılandırması

### `app_settings/intelligence_pipeline`

Sunucu rollup kullanıldığında istemci demo yazımını kapatın (tek kaynak):

```json
{
  "clientSeedWritesEnabled": false,
  "opportunityPriceRatio": 0.85
}
```

- **`clientSeedWritesEnabled`**: `false` → `BackgroundIntelligenceService` keşif/heatmap tohumu **yazmaz** (sunucu verisi ezilmez).
- **`opportunityPriceRatio`**: Bölge medyanının altındaki ilanlar “fırsat” adayı (varsayılan Cloud Functions’da 0.85).

## Cloud Functions (bu repo)

| Fonksiyon | Açıklama |
|-----------|----------|
| `scheduledFetchListings` | **6 saatte bir** (Europe/Istanbul): `SCRAPER_MODE` ≠ `ingest_only` ise doğrudan HTML çekimi; ardından **rollup**. |
| `ingestListingsPipeline` | **HTTPS** `POST` + header `x-ingest-secret: <INGEST_SECRET>`. Body: `{ "listings": [ ... ] }`. Sonra rollup. |
| `fetchListingsNow` | Callable; **giriş yapmış kullanıcı** gerekir. Manuel çekim + rollup. |

### Ortam değişkenleri (Firebase Console → Functions → yapılandırma)

| Değişken | Örnek | Anlam |
|----------|--------|--------|
| `SCRAPER_MODE` | `hybrid` | Doğrudan çekim + rollup (varsayılan). |
| `SCRAPER_MODE` | `ingest_only` | Sadece ingest + rollup; CF’den hedef sitelere istek yok. |
| `INGEST_SECRET` | güçlü rastgele string | Ingest endpoint’i için. |
| `HTTPS_PROXY` | `http://user:pass@host:port` | Bright Data / Zyte residential veya kurumsal proxy. |

## Ingest örnek gövde (worker → Functions)

```http
POST https://<region>-<project>.cloudfunctions.net/ingestListingsPipeline
x-ingest-secret: <INGEST_SECRET>
Content-Type: application/json
```

```json
{
  "listings": [
    {
      "source": "pipeline_sahibinden",
      "externalId": "123456789",
      "title": "Örnek başlık",
      "priceValue": 3500000,
      "priceText": "3.500.000 TL",
      "link": "https://...",
      "districtName": "Kayapınar",
      "postedAt": "2025-03-19T10:00:00.000Z"
    }
  ]
}
```

## Rollup mantığı (özet)

- `external_listings` içinde `cityCode` eşleşen örnek (en fazla 500 doküman).
- İlçe adından **bölge** (`kayapinar` / `baglar` / `yenisehir`) çıkarımı.
- Bölge başına **medyan fiyat**; fiyatı medyan × `opportunityPriceRatio` altındaki ilanlar **fırsat** listesine (skor 0.80–0.98).
- `analytics_daily/heatmap_<YYYY-MM-DD>` ve `discovery_<YYYY-MM-DD>` güncellenir.

## Yasal uyarı

Hedef sitelerin **hizmet şartları**, **robots.txt** ve **KVKK** kapsamındaki yükümlülükler size aittir. Bu mimari teknik altyapıdır; veri toplama izinlerini ayrıca değerlendirin.

## İlgili dosyalar

- `functions/index.js` — zamanlanmış iş, ingest, callable.
- `functions/rollupMarketPulse.js` — rollup.
- `functions/httpClient.js` — isteğe bağlı proxy.
- `lib/core/intelligence/background_intelligence_service.dart` — istemci tohum bayrağı.
- `doc/OPERATIONS_MARKET_PULSE.md` — deploy, ortam değişkenleri, seed (tek seferlik).
