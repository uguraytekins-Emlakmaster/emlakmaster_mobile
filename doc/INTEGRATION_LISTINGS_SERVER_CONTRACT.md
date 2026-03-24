# `integration_listings` — sunucu sözleşmesi

Mobil uygulama bu koleksiyona **yalnızca okur** (`firestore.rules`: istemci yazımı kapalı).  
Yazma **Firebase Admin SDK** ile yapılır (Cloud Functions, güvenilir backend veya Rainbow CRM köprüsü).

## Zorunlu alan: `ownerUserId`

- Değer: **Firebase Authentication `uid`** — ilanın sahibi olan kullanıcı.
- Mobil sorgu: `where('ownerUserId', '==', currentUser.uid)`.
- Kural: `resource.data.ownerUserId == request.auth.uid` (veya yönetici okuması).

Bu alan olmadan kullanıcı kendi ilanlarını listede göremez.

## Önerilen şema (Flutter `IntegrationSyncedListingEntity` ile uyumlu)

| Alan | Tip | Not |
|------|-----|-----|
| `ownerUserId` | string | **Zorunlu** (Auth uid) |
| `connectionId` | string | Harici bağlantı kaydı id |
| `platform` | string | `sahibinden` \| `hepsiemlak` \| `emlakjet` |
| `externalListingId` | string | Platformdaki ilan id |
| `title` | string | |
| `sourceUrl` | string | Kaynak sayfa (HTTPS) |
| `importedAt` | timestamp | |
| `syncedAt` | timestamp | Son senkron |
| `officeId` | string | Ofis (opsiyonel iş kuralı) |
| `price`, `currency`, `city`, `district`, … | | İsteğe bağlı |

## Kod referansı

- Node.js yardımcı: `functions/integrationListingsAdmin.js` — `buildIntegrationListingPayload`, `upsertIntegrationListing`.
- Senkron tetikleyiciyi (HTTP / scheduled / Rainbow webhook) `functions/index.js` içinde bu modülü kullanarak bağlayın.
- **Import Engine (URL / dosya / uzantı / duplicate / sync log):** `doc/RAINBOW_CORE_IMPORT_ENGINE.md`

## Deploy

```bash
cd emlakmaster_mobile
firebase deploy --only firestore:rules
```

Kurallar `firestore.rules` içinde `match /integration_listings/{listingId}` altında tanımlıdır.
