# Owned listings — resmi senkron mimarisi

Bu doküman **Benim İlanlarım** için üretim odaklı veri modelini ve sunucu akışını tanımlar. Pazar akışı (`external_listings`) burada kapsanmaz; resmi ingest bayrağı ile ayrı yüzeyde kalır.

## İlkeler

- **Scraping varsayımı yok.** Sahibinden / Emlakjet / Hepsiemlak için yalnızca onaylı API, feed veya partner transfer uçları.
- **Dosya içe aktarma (CSV / JSON / Excel)** yedek kanaldır; Cloud Functions `listingSync/canonicalListing` ile `listings` koleksiyonuna canonical yazım yapar.
- **Dedup anahtarı:** `sourcePlatform` + `sourceListingId` (ofis kapsamında deterministic doc id: `listingSync/canonicalListing.js`).

## Firestore koleksiyonları

### `listings` (canonical ofis envanteri)

Zorunlu / önerilen alanlar:

| Alan | Açıklama |
|------|-----------|
| `ownerUserId` | Firebase Auth uid (sorgu: `where('ownerUserId', '==', uid)`) |
| `officeId` | Ofis kapsamı (`where('officeId', '==', officeId)`) |
| `sourcePlatform` | `internal`, `sahibinden`, `emlakjet`, `hepsiemlak`, `import_csv`, … |
| `sourceListingId` | Kaynak sistemdeki ilan id |
| `isOwnedByOffice` | `true` |
| `syncStatus` | `synced` \| `pending` \| `error` \| `stale` |
| `lastSyncedAt` | Sunucu zamanı |
| `contentHash` | Normalize içerik SHA-256 |
| `rawPayloadRef` | Opsiyonel: Storage yolu veya `listing_import_tasks/{id}` |
| `title`, `price`, `location`, `imageUrl` | Normalize görünüm alanları |

**Not:** Eski dokümanlarda yalnızca `source: manual` olabilir; istemci `sourcePlatform` yoksa `source` ile doldurur. Migrasyon için `ownerUserId` / `officeId` eklenmesi önerilir.

### Legacy backfill

Eski `listings` kayıplarını önlemek için yönetici callable: **`backfillLegacyListings`** — ayrıntılar: [`LISTING_LEGACY_BACKFILL.md`](./LISTING_LEGACY_BACKFILL.md).

### `listing_sources`

Ofis başına connector kaydı (Admin SDK yazar).

- `officeId`, `platform` (`sahibinden` \| `emlakjet` \| `hepsiemlak`)
- `connectionId` → `external_connections/{id}` üzerinden `userId` çözülür
- `defaultOwnerUserId` (opsiyonel)
- `connectorType`: `official_api` \| `file_import` \| `internal`
- `status`: `active` \| `disabled` \| `pending_credentials`

### `listing_sync_runs`

`runOfficeSync` her kaynak için bir çalıştırma yazar: `stats` (fetched, upserted, skippedUnchanged, errors), `status`, `message`.

### `listing_sync_errors`

Satır bazlı hatalar (`UPSERT_FAILED`, `UNSUPPORTED_PLATFORM`, `RUN_FAILED`, …).

### `integration_listings` (legacy / paralel)

Mevcut Rainbow / import motoru uyumu korunur. İstemci, canonical `listings` ile aynı `sourcePlatform|sourceListingId` anahtarına sahip satırları tekilleştirir.

## Cloud Functions

| Export | Açıklama |
|--------|----------|
| `syncOwnedListingsForOffice` | Callable — yönetici; `listing_sources` aktif kayıtları için connector çalıştırır |
| Dosya içe aktarma | `fileImportProcessor` → `upsertCanonicalOwnedListing` + mevcut `upsertIntegrationListing` |

### Ortam değişkenleri (resmi API)

- `SAHIBINDEN_OFFICIAL_API_BASE_URL`, `SAHIBINDEN_OFFICIAL_API_TOKEN`
- `EMLAKJET_OFFICIAL_API_BASE_URL`, `EMLAKJET_OFFICIAL_API_TOKEN`
- `HEPSIEMLAK_OFFICIAL_API_BASE_URL`, `HEPSIEMLAK_OFFICIAL_API_TOKEN`

Yapılandırılmadığında connector’lar **boş liste** döner; `listing_sync_runs` mesajında durum açıklanır (scraping’e düşülmez).

## İstemci

- `ListingsPortfolioStream.owned(uid, officeId)` — `listings` (owner + office) + `integration_listings`, dedup.
- `listing_sources_repository` — ileride «bağlantı yok» doğruluk mesajları için.

## Örnek `listing_sources` dokümanı

```json
{
  "officeId": "off_123",
  "platform": "sahibinden",
  "connectionId": "conn_abc",
  "connectorType": "official_api",
  "status": "active"
}
```

Deploy: `firebase deploy --only firestore:rules,functions`
