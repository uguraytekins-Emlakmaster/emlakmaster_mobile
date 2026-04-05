# Legacy `listings` backfill — Benim İlanlarım uyumluluğu

## Problem

Yeni owned-listings sorguları şunlara dayanır:

- `where('ownerUserId', '==', uid)` ve/veya `where('officeId', '==', officeId)`
- Ayrıca kart modeli: `sourcePlatform`, `sourceListingId`, `isOwnedByOffice`, `syncStatus`

Eski dokümanlarda sık görülen eksikler:

| Alan | Tipik legacy durum |
|------|---------------------|
| `ownerUserId` | Sadece `createListingManual` sonrası dolu; çok eski kayıtlarda yok |
| `officeId` | Yok (veya sadece kullanıcı doc’unda) |
| `sourcePlatform` | Yok; bazen sadece `source: manual` |
| `sourceListingId` | Yok |
| `isOwnedByOffice` | Alan hiç yok |
| `syncStatus` | Alan hiç yok |

## Strateji

1. **Tek seferlik, kontrollü güncelleme** — Cloud Function callable `backfillLegacyListings` (yalnızca yönetici).
2. **Mevcut alanları ezme** — `merge: true`; yalnızca **eksik** alanlar doldurulur.
3. **Çift kayıt yok** — Yeni doküman oluşturulmaz; yalnızca mevcut `listings/{id}` güncellenir.
4. **Canonical senkron kayıtları** — `sourcePlatform` / `sourceListingId` / `contentHash` zaten doluysa aynı değerler korunur; sadece eksik yardımcı alanlar tamamlanır.
5. **Sayfalama** — `cursor` (son işlenen doküman id) ile büyük koleksiyonlar parça parça işlenir.

## Callable: `backfillLegacyListings`

**Yetki:** Firebase Callable; `users/{uid}.role` yönetici rollerinden biri olmalı (`userHasManagerRole`).

### İstek parametreleri

| Parametre | Açıklama |
|-----------|-----------|
| `dryRun` | `true` ise yazma yok; `wouldUpdate`, `samples` döner |
| `maxDocs` | 1–500 (varsayılan 400) |
| `cursor` | Önceki çağrının `lastDocId` değeri (bir sonraki sayfa) |
| `applyFallbackOwner` | `true` ise ve `confirmBulkFallback: true` ise |
| `applyFallbackOffice` | `true` ise ve `confirmBulkFallback: true` ise |
| `fallbackOwnerUserId` | Toplu atama için (dikkatli kullanın) |
| `fallbackOfficeId` | Toplu atama için |
| `confirmBulkFallback` | `fallback*` kullanımını açar (yanlışlıkla toplu atamayı önler) |

### Doldurma kuralları

**ownerUserId** (sırayla):

1. Zaten varsa → dokunulmaz  
2. Şu alanlardan ilkinin string uid değeri: `ownerUserId`, `createdBy`, `createdByUid`, `agentId`, `advisorId`, `userId`, `ownerUid`  
3. İsteğe bağlı: `applyFallbackOwner` + `confirmBulkFallback` + `fallbackOwnerUserId`

**officeId**:

1. Zaten varsa → dokunulmaz  
2. `ownerUserId` (merge sonrası veya mevcut) için `users/{uid}.officeId`  
3. İsteğe bağlı: `applyFallbackOffice` + `confirmBulkFallback` + `fallbackOfficeId`

**sourceListingId**: Yoksa → `doc.id` (mevcut Firestore kimliği).

**sourcePlatform**: Yoksa → `internal` (veya `source` alanı `manual` / boş ise `internal`).

**isOwnedByOffice**: `undefined` / `null` ise → `true`.

**syncStatus**: Yoksa → `synced`.

**Denetim**: Her güncellenen dokümanda `listingMigration: { backfillVersion: 1, backfilledAt, dryRun, notes[] }` ve `updatedAt`.

## Önerilen çalıştırma

1. **dry-run** (örnek):  
   `dryRun: true`, `maxDocs: 50` → `samples` ile inceleyin.

2. **İlk gerçek batch**:  
   `dryRun: false`, `maxDocs: 400` → `lastDocId` not edin.

3. **Sonraki sayfalar**:  
   `cursor: "<lastDocId>"` ile tekrarlayın ta ki `scanned < maxDocs` veya koleksiyon bitene kadar.

4. **Toplu fallback** (yalnızca gerekirse, örn. hiç uid alanı kalmamış eski veri):  
   `confirmBulkFallback: true`, `applyFallbackOwner: true`, `fallbackOwnerUserId: "<ofis sorumlusu uid>"` — **yanlış kişiye atamayı** önlemek için önce dry-run ile doğrulayın.

## Otomasyon sonrası hâlâ manuel gerekebilir

- **Hem `ownerUserId` hem `officeId` çıkarılamayan** dokümanlar: `stillMissingOwnerAndOffice` sayısı > 0.  
  Seçenekler: Firestore konsolunda tek tek düzeltme, uygun `fallback*`, veya kaydı arşivleme/silme kararı.
- **Yanlış `agentId` / `advisorId` ile eşleşme**: Eski şemada yanlış alan doluysa `ownerUserId` yanlış atanabilir — önce dry-run `samples` kontrol edin.
- **İki farklı dokümanda aynı mantıksal ilan** (canonical `own_*` + eski random id): Backfill **birleştirmez**; dedup ayrı bir operasyon.

## İlgili dosyalar

- `functions/listingMigration/backfillLegacyListings.js` — callable uygulaması  
- `functions/index.js` — export  
- `doc/LISTING_SYNC_ARCHITECTURE.md` — owned modeli

## Deploy

```bash
cd emlakmaster_mobile
firebase deploy --only functions:backfillLegacyListings
```

Çağrı: Firebase SDK `httpsCallable` veya Admin / konsol testi ile `officeId` / parametreler gönderilir.
