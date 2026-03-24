# Phase 1.4 — Bağlı platformlar (temel + UX)

## Model

- `IntegrationPlatform` — kart satırı: `IntegrationPlatformId`, ad, logo harfi, `IntegrationSupportLevel`, `PlatformUiCapabilities`, `PlatformConnectionUiState`, `lastSyncAt`, `PlatformErrorUi?`.
- `PlatformConnectionUiState` — `connected` | `disconnected` | `limited` | `needsAttention`.
- `PlatformUiCapabilities` — `canImportListings`, `canUpdatePrice`, `canManageMessages`, `canSync`.
- `AdminPlatformConnectionRow` — ofis yöneticisi için kullanıcı × platform özeti (mock).

## Sağlayıcılar

- `platformListProvider` — tüm platform satırları (mock: `ConnectedPlatformsMock`).
- `platformConnectionProvider(id)` — tek satır, liste üzerinden türetilir.
- `platformStatusProvider(id)` — durum kısayolu.
- `adminPlatformConnectionsProvider` — ofis admin özet satırları (mock).

## UI

- `ConnectedPlatformsPage` — `/settings/connected-accounts` rotası.
- `OfficeAdminPage` — harici platform özet bloğu + bağlı platformlar linki.

## Sonraki adımlar

- `external_connections` + repository ile `platformListProvider` birleştirme.
- OAuth / tarayıcı uzantısı / otomasyon — ayrı faz.
