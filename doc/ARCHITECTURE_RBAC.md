# RBAC & Adaptive Navigation

## Roller (AppRole)

| Rol | Panel | Erişim |
|-----|--------|--------|
| **ADMIN** (super_admin, broker_owner, general_manager, office_manager, team_lead, operations) | AdminShell | Dashboard, War Room, Çağrı Merkezi, Ekonomi, Raporlar, Ayarlar. Tam yetki. |
| **CONSULTANT** (agent, guest, finance_investor, investor_portal) | ConsultantShell | Özetim, Müşterilerim, İlanlar, Takip, Görevler, Ayarlar. Magic Call FAB. |
| **CLIENT** (client) | ClientShell | Arama, Favoriler, Mesajlar, Sanal Tur, Profil. Staff-only route’lara erişemez. |

- Rol, Firestore `users/{uid}.role` alanından okunur (`AppRole.fromFirestoreRole`).
- Ayarlar (debug): Super Admin/Broker test kullanıcıları rol değiştirebilir (override); Client rolü listede seçilebilir.

## Route guard

- **Client** kullanıcılar şu path’lere gidemez (redirect → `/`):
  - `/call`, `/call/*`, `/command-center`, `/war-room`, `/broker-command`, `/pipeline`, `/notifications`, `/customer/*`

## Adaptif layout

- **Breakpoint:** `DesignTokens.breakpointWide` = 600px.
- **Geniş ekran (Web/Desktop):** `NavigationRail` (sol sidebar) + içerik.
- **Dar ekran (Mobile):** Alt `BottomNavigationBar` + içerik.
- Tüm shell’ler `AdaptiveShellScaffold` kullanır: AdminShell, ConsultantShell, ClientShell.

## Dosya yapısı

- `lib/features/auth/domain/entities/app_role.dart` — enum + `isClientTier`, `isConsultantTier`, `fromFirestoreRole('client')`.
- `lib/features/auth/domain/permissions/feature_permission.dart` — `seesClientPanel`, `seesAdminPanel`, `seesConsultantPanel` + client izinleri.
- `lib/core/layout/adaptive_shell_scaffold.dart` — ortak scaffold (rail / bottom nav).
- `lib/screens/role_based_shell.dart` — rol → AdminShell | ConsultantShell | ClientShell seçimi.
- `lib/screens/client_shell.dart` — müşteri paneli (placeholder sayfalar).
- `lib/screens/client_pages.dart` — ClientSearchPage, ClientFavoritesPage, ClientMessagesPage, ClientVirtualTourPage, ClientProfilePage.

## Strategic AI Modules (PropTech)

### Data model (Listing / Lead)

- **Listing:** `ListingStrategicFields` — swap_compatible, swap_compatibility_score/verdict/updated_at, investment_score/updated_at, hotspot_tags, voice_note_summary, media_360_urls, lidar_scan_id, property_vault_doc_id. (Firestore: `listings` + AppConstants field names.)
- **Lead/Customer:** `CustomerEntity` + optional voiceNoteSummary, voiceNoteSummaryUpdatedAt, isVipInvestor, investmentAlertEnabled. Mapper: `CustomerMapper.fromDoc` (Firestore `voice_note_summary`, `is_vip_investor`, etc.).

### War Room (Command Center)

- **UI:** `WarRoomCommandCenter` — full-screen, glassmorphism, Navy/Gold. Adaptive: Grid (width ≥ 600) vs single column.
- **Widgets:** Lead Pulse (glowing dots + recent leads count), Top Performers (agents by totalCalls, trophies), Market Ticker (office_activity), Daily Target Tracker (deals vs monthly target).
- **Providers:** `recentLeadsStreamProvider`, `liveCallsCountProvider`, `agentsSnapshotProvider`, `dealsCountProvider`, `officeMonthlyTargetProvider`. Firestore: `recentLeadsStream()` (updatedAt desc), `officeMonthlyTargetStream()` (app_settings/office_targets).

### Barter & Swap Engine (Takas Zekası)

- **Domain:** `SwapCompatibilityVerdict` (profitable / fair / risky), `ComputeSwapCompatibility` (listing vs counter-party value → score + verdict).
- **Data integrity:** `SwapCompatibilityRepository.saveSwapScore()` writes to `listings/{id}` with `swap_compatibility_updated_at` (server timestamp).

### Mülk Sağlık Karnesi (Property Vault)

- **Domain:** `PropertyVaultItem` (renovation invoice, past photo, technical report). Subcollection: `listings/{id}/property_vault`.
- **Repository:** `PropertyVaultRepository.vaultStream(listingId)`, `addItem(...)`.

### Regional Investment Radar

- **Domain:** `HotspotTag` (label, region, highYieldPotential). Listings: `hotspot_tags` array; VIP notify: `customers.is_vip_investor` + `investment_alert_enabled` (backend/Cloud Function ile bildirim tetiklenebilir).

### Hands-Free CRM (Voice)

- **UI:** `PushToTalkButton` — basılı tut = kayıt, bırak = durdur (STT pipeline TODO).
- **Domain:** `VoiceCrmIntent` — updateLead, addOffer, setReminderAt, rawSummary. Ses → metin → yapılandırılmış aksiyon (ileride NLP/Cloud Function).

### AR/VR ready

- **Listing alanları:** `media_360_urls`, `lidar_scan_id`. Widget: `ListingMedia360Placeholder` (360° + Lidar chip’ler; viewer TODO).

### Self-healing / data freshness

- `recentLeadsStream()`: try/catch → hata durumunda boş stream (index yoksa çökmez).
- Tüm AI skorları: Firestore’a yazarken `*_updated_at` veya `computedAt` / `serverTimestamp()` kullanılır.

## Sonraki adımlar (spec’e göre)

- CLIENT: Arama UI, Favoriler (Firestore), Mesajlar, Sanal tur linkleri, Profil/çıkış.
- Firestore rules: `client` rolü için koleksiyon erişimleri (favorites, messages).
- Voice: speech_to_text entegrasyonu + NLP intent extraction.
- War Room: Firestore index `customers` orderBy updatedAt desc (gerekirse).
