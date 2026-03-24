# Market Pulse — Blaze olmadan (Firebase Spark)

Cloud Functions **Blaze** gerektirir. Bu projede **alternatif** olarak tüm rollup mantığı Dart’ta (`lib/core/intelligence/market_pulse_client_rollup.dart`, `MarketPulseClientRollupService`) çalışır:

- `external_listings` okunur (şehir kodu ile, max 500).
- Bölge medyanı + “fırsat” skoru hesaplanır.
- `analytics_daily/heatmap_*` ve `discovery_*` yazılır; `source: client_rollup_v1`.

## Gereksinimler

1. **Firestore kuralları** bu yazıma izin vermeli — güncel `firestore.rules` repoda; deploy edin:

   ```bash
   ./scripts/deploy_firestore_rules.sh
   ```

2. **Giriş yapmış kullanıcı** (rollup Firestore yazar).

3. **Pil / kota**: Aynı cihazda rollup en fazla ~**30 dakikada bir** (ayar: `AppConstants.marketPulseClientRollupMinInterval`). İlan senkronundan sonra **zorunlu** rollup (`force: true`) çalışır.

## Blaze ile Cloud Functions farkı

| | Spark (istemci rollup) | Blaze (Functions) |
|---|------------------------|-------------------|
| Zamanlama | Uygulama açılışı + senkron sonrası | 6 saatte bir sunucu |
| Pil | Düşük (tek batch yazım, throttle) | Telefonda yok |
| Cloudflare aşma | Yok; ilanlar yine `ClientExternalListingsSyncService` ile | Ingest / proxy |

## Öneri

- **Spark**: Bu dosyadaki akış yeterli.
- **Üretim ölçeği / 7/24 güncelleme**: Blaze + `functions/` ingest pipeline.
