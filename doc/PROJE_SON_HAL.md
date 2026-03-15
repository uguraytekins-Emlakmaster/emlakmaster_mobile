# EmlakMaster Mobile – Proje Son Hal Özeti

*Son güncelleme: Mart 2025*

---

## Genel

- **Uygulama:** EmlakMaster (emlak CRM / broker yönetim)
- **Stack:** Flutter 3.x, Dart ^3.5, Firebase (Auth + Firestore), Riverpod, go_router
- **Tema:** Koyu (0xFF0D1117), vurgu rengi yeşil (0xFF00FF41), Cmd+K ile Command Palette
- **Dosya sayısı:** ~92 Dart dosyası (`lib/`)

---

## Giriş ve yetkilendirme

- **Login:** `/login` → Firebase Auth + Google Sign-In
- **Roller (AppRole):** Super Admin, Broker/Owner, Genel Yönetici, Ofis Müdürü, Team Lead, Danışman, Operasyon, Finans/Yatırım, Yatırımcı Portal, Demo
- **Panel seçimi:** Giriş sonrası rol + tercih:
  - **Yönetici paneli:** Admin tier (super_admin, broker_owner, general_manager) + isteğe bağlı danışman görünümü
  - **Danışman paneli:** Agent vb. her zaman danışman; yönetici kullanıcı “danışman gibi görün” diyebilir

---

## Routing (go_router)

| Rota | Açıklama |
|------|----------|
| `/login` | Giriş sayfası |
| `/` | Ana sayfa → RoleBasedShellSelector (Admin veya Consultant shell) |
| `/call` | Arama ekranı (Magic Call) |
| `/call/summary` | Arama sonrası özet sihirbazı |
| `/command-center` | Yönetici çağrı merkezi |
| `/war-room` | War Room |
| `/broker-command` | Broker komut sayfası |

---

## Yönetici paneli (AdminShell)

Alt sekmeler:

1. **Dashboard** – KPI’lar, özet
2. **War Room** – Operasyon odası
3. **Çağrı Merkezi** – CommandCenterPage
4. **Ekonomi** – AdminEconomyPage (placeholder)
5. **Raporlar** – AdminReportsPage (placeholder)
6. **Ayarlar** – SettingsPlaceholderPage

---

## Danışman paneli (ConsultantShell)

Alt sekmeler:

1. **Özetim** – ConsultantDashboardPage
2. **Müşterilerim** – CustomerListPage
3. **İlanlar** – ListingsPage
4. **Takip** – ConsultantResurrectionPage (resurrection kuyruğu)
5. **Ayarlar** – SettingsPlaceholderPage

+ **Magic Call FAB** (Özetim sekmesindeyken)

---

## Özellik modülleri (features/)

| Modül | Kısa açıklama |
|-------|----------------|
| **auth** | Giriş, roller, yetkiler, AuthGuard |
| **calls** | CallScreen, PostCallWizard (arama + özet) |
| **ai_call_brain** | Çağrı özeti kaydetme (retry ile) |
| **crm_customers** | Müşteri listesi, CustomerCard |
| **dashboard** | KPI bölümü, welcome overlay |
| **manager_command_center** | CommandCenterPage |
| **broker_command** | BrokerCommandPage |
| **war_room** | WarRoomPage |
| **lead_temperature_engine** | Lead sıcaklık hesaplama, provider |
| **deal_health_engine** | Deal sağlık skoru |
| **resurrection_engine** | Takip kuyruğu, segment, provider |
| **smart_matching_engine** | İlan–müşteri eşleştirme skoru |
| **hot_lead_radar** | Hot lead radar paneli |
| **daily_brief** | Günlük özet paneli |
| **opportunity_radar** | Fırsat radarı widget |
| **missed_opportunities** | Kaçan fırsatlar paneli |
| **market_heatmap** | Market pulse paneli |
| **market_settings** | Piyasa ayarları (entity, repo, provider) |
| **deal_discovery** | Keşif paneli |
| **customer_timeline** | Müşteri zaman çizelgesi entity |
| **automation_rules_engine** | Kural tanımı (domain) |

---

## Core (lib/core/)

- **router:** app_router.dart (go_router tanımları)
- **theme:** app_theme, design_tokens
- **services:** FirestoreService, SyncManager, AuthService, FinanceService, OperationsHealth, AuditLogService
- **intelligence:** skor modelleri, Firestore, background service, provider’lar
- **errors / result:** AppException, ExceptionMapper, Result
- **config / constants:** AppConfig, AppConstants
- **logging:** AppLogger
- **widgets:** CommandPalette (Cmd+K)

---

## Paylaşılan modeller (shared/models/)

- customer, call, call_summary, listing, pipeline, task, offer, visit, note  
- lead_temperature, deal_health

---

## Paylaşılan widget’lar (shared/widgets/)

- EmptyState, ErrorState, UnauthorizedScreen, SkeletonLoader

---

## Dokümantasyon (doc/)

- ARCHITECTURE.md  
- AUTH_AND_ROLES.md  
- PRIVACY_AND_OFFLINE.md  
- RELEASE_READINESS.md  
- VISION_AND_GAPS.md  
- **PROJE_SON_HAL.md** (bu dosya)

---

## Çalıştırma

- Workspace: **Projeler** (File → Open Folder)
- macOS: `./run_macos.sh` veya `cd EmlakMaster_Proje/emlakmaster_mobile && flutter run -d macos`
- Flutter lockfile hatası: `sudo chown -R $(whoami) /Users/uguraytekin/flutter`
