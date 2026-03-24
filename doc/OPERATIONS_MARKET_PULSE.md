# Market Pulse — operasyon (tek seferlik)

Bu dosya **sizin manuel yapmanız gerekenleri** minimize eder; mümkün olanlar `scripts/` ile otomatiktir.

## 0) Blaze yok (Spark) — istemci rollup

Cloud Functions deploy **gerekmez**. `doc/MARKET_PULSE_SPARK_NO_BLAZE.md` — yalnızca güncel **Firestore kuralları** deploy edin:

```bash
./scripts/deploy_firestore_rules.sh
```

## 1) Cloud Functions deploy (Blaze gerekir)

```bash
cd emlakmaster_mobile
./scripts/deploy_firebase_functions.sh
```

veya hepsi bir arada (deploy + seed denemesi):

```bash
./scripts/setup_market_pulse_backend.sh
```

Deploy başarısızsa: [Firebase Console](https://console.firebase.google.com/project/emlak-master/usage/details) → faturalandırma (Blaze), `firebase login`.

## 2) Ortam değişkenleri (Google Cloud Console)

Firebase Functions, Google Cloud üzerinde çalışır. [Cloud Functions](https://console.cloud.google.com/functions?project=emlak-master) → ilgili fonksiyon → **Düzenle** → **Çalışma zamanı, yapılandırma, bağlantılar** → **Çalışma zamanı ortam değişkenleri**:

| Değişken | Örnek | Açıklama |
|----------|--------|----------|
| `INGEST_SECRET` | `./scripts/generate_ingest_secret.sh` çıktısı | `ingestListingsPipeline` için zorunlu |
| `SCRAPER_MODE` | `ingest_only` veya `hybrid` | Doğrudan HTML / sadece ingest |
| `HTTPS_PROXY` | Sağlayıcı URL’si | İsteğe bağlı (Bright Data / Zyte) |

Değişiklikten sonra fonksiyon **yeniden deploy** edilmeli veya konsolda yeni sürüm oluşturulmalıdır.

## 3) Firestore `intelligence_pipeline`

Sunucu rollup kullanılırken istemci demo yazımını kapatmak için:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
./scripts/seed_intelligence_pipeline_only.sh
```

Veya [Firestore Console](https://console.firebase.google.com/project/emlak-master/firestore) → `app_settings` → `intelligence_pipeline`:

```json
{
  "clientSeedWritesEnabled": false,
  "opportunityPriceRatio": 0.85
}
```

Geliştirmede demo istiyorsanız:

```bash
CLIENT_SEED_INTELLIGENCE=true ./scripts/seed_intelligence_pipeline_only.sh
```

## 4) Firestore kuralları

Güncel kurallar:

```bash
./scripts/deploy_firestore_rules.sh
```

## 5) İlgili dokümanlar

- `doc/MARKET_PULSE_SERVERLESS_ARCHITECTURE.md` — mimari
- `functions/.env.example` — ortam değişkeni özetleri
