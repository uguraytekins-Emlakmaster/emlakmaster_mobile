# EmlakMaster — Premium UI Implementation Map

**Figma source:** [Untitled — DeSfzgIX9eKCeguS0sBxQX](https://www.figma.com/design/DeSfzgIX9eKCeguS0sBxQX/Untitled?node-id=0-1)  
**Audit date:** 2026-05-24  
**Scope:** UI/UX layer only — architecture, routes, providers, Firestore unchanged.

---

## Design DNA (from Figma canvas)

| Token | Value | Flutter |
|-------|-------|---------|
| Obsidian base | `#050506` | `PremiumColorTokens.obsidian` |
| Midnight navy surface | `#111827` | `PremiumColorTokens.midnightNavySurface` |
| Champagne gold accent | `#C9A962` | `PremiumColorTokens.champagneGold` |
| Glass fill | navy @ 80% | `PremiumThemeExtension.glassSurface` |
| Typography | Executive sans, w800 headings | `AppTypography` + `ThemeData.textTheme` |
| Radius | 24px cards, 28px sheets, pill CTAs | `DesignTokens` |
| Motion | 180–280ms easeOutCubic | `PremiumMotionTokens` |

---

## Phase plan ↔ route map

| Phase | Figma frames (observed) | GoRouter / Shell | Primary files | Status |
|-------|-------------------------|------------------|---------------|--------|
| **1** DS foundation | All (tokens) | — | `lib/core/theme/premium/*`, `lib/widgets/premium/v2/*` | **IN PROGRESS** |
| **2** Navigation shell | Bottom nav, top chrome | `/`, shells | `consultant_shell.dart`, `admin_shell.dart`, `client_shell.dart`, `adaptive_shell_scaffold.dart`, `premium_bottom_nav_dock.dart` | Exists — restyle |
| **3** Consultant CRM | Danışman panel, Müşteri listesi, Müşteri detay, Görevler, Takip, Mesajlar | tabs + `/customer/:id` | `consultant_dashboard_page.dart`, `customer_list_page.dart`, `customer_detail_page.dart`, `tasks_page.dart`, `consultant_resurrection_page.dart`, `message_center_page.dart` | Exists — restyle |
| **4** Call system | Çağrı geçmişi, aktif arama, post-call | `/call`, `/call/summary`, `/consultant/calls` | `consultant_calls_page.dart`, `call_screen.dart`, `post_call_wizard.dart` | Exists — restyle |
| **5** Listings + Pipeline | İlan listesi, ilan detay, fırsat hattı | `/listing/:id`, `/pipeline`, listings tab | `listings_screen.dart`, `listing_detail_page.dart`, `pipeline_kanban_page.dart` | Exists — restyle; create/edit **missing** |
| **6** Broker/Admin | Broker dashboard, komuta, savaş odası, raporlar, kadro | `/`, `/command-center`, `/war-room`, `/broker-command`, `/admin/*` | `dashboard_screen.dart`, `command_center_page.dart`, `war_room_page.dart`, `admin_pages.dart`, `admin_*_page.dart` | Exists — restyle; audit log **missing** |
| **7** Analytics + AI | Rainbow analitik, intel geçmişi, AI komutan | `/rainbow-analytics`, `/rainbow-intel-history` | `rainbow_analytics_center_page.dart`, `intel_report_history_page.dart`, `AiSalesAssistantPanel` | Exists — restyle; full AI screen **missing** |
| **8** Integrations | Entegrasyonlar, import hub | `/settings/connected-accounts`, `/settings/import-*` | `connected_platforms_page.dart`, `import_hub_page.dart` | Exists — restyle (mock data) |
| **9** Client portal | Müşteri paneli | client shell tabs | `client_pages.dart` | **mock** — full redesign |

---

## Route → Figma frame → implementation file

| Route | TR (Figma) | Widget | File | Phase |
|-------|------------|--------|------|-------|
| `/login` | Giriş | LoginPage | `features/auth/.../login_page.dart` | 2 |
| `/register` | Kayıt | RegisterPage | `features/auth/.../register_page.dart` | 2 |
| `/onboarding` | Tanıtım | OnboardingPage | `features/onboarding/.../onboarding_page.dart` | 2 |
| `/workspace-setup` | Kurulum | WorkspaceSetupPage | `features/workspace/...` | 2 |
| `/role-selection` | Rol | RoleSelectionPage | `features/auth/...` | 2 |
| `/office/*` | Ofis akışı | Office*Page | `features/office/...` | 2 |
| `/` consultant tab 0 | Danışman panel | ConsultantDashboardPage | `screens/consultant_dashboard_page.dart` | 3 |
| `/` consultant tab 3 | Müşteri listesi | CustomerListPage | `features/crm_customers/.../customer_list_page.dart` | 3 |
| `/customer/:id` | Müşteri detay | CustomerDetailPage | `features/crm_customers/.../customer_detail_page.dart` | 3 |
| `/` consultant tab 6 | Görevler | TasksPage | `features/tasks/.../tasks_page.dart` | 3 |
| `/resurrection` | Takip / geri kazanım | ConsultantResurrectionPage | `screens/consultant_resurrection_page.dart` | 3 |
| `/messages` | Mesaj merkezi | MessageCenterPage | `features/messages/...` | 3 |
| `/consultant/calls` | Çağrı geçmişi | ConsultantCallsPage | `features/calls/.../consultant_calls_page.dart` | 4 |
| `/call` | Aktif arama | CallScreen | `features/calls/call_screen.dart` | 4 |
| `/call/summary` | Post-call sihirbaz | PostCallWizardScreen | `features/calls/post_call_wizard.dart` | 4 |
| `/` listings tab | İlan listesi | ListingsPage | `screens/listings_screen.dart` | 5 |
| `/listing/:id` | İlan detay | ListingDetailPage | `screens/listing_detail_page.dart` | 5 |
| `/pipeline` | Fırsat hattı | PipelineKanbanPage | `features/pipeline/...` | 5 |
| `/` admin dashboard | Broker panel | DashboardPage | `screens/dashboard_screen.dart` | 6 |
| `/command-center` | Komuta merkezi | CommandCenterPage | `features/manager_command_center/...` | 6 |
| `/war-room` | Savaş odası | WarRoomPage | `features/war_room/...` | 6 |
| `/broker-command` | Broker komuta | BrokerCommandPage | `features/broker_command/...` | 6 |
| `/` admin reports | Raporlar | AdminReportsPage | `screens/admin_pages.dart` | 6 |
| `/admin/consultants` | Danışman kadrosu | AdminConsultantsPage | `features/admin_consultants/...` | 6 |
| `/admin/teams` | Ekipler | AdminTeamsPage | `features/admin_teams/...` | 6 |
| `/rainbow-analytics` | Rainbow analitik | RainbowAnalyticsCenterPage | `features/analytics/...` | 7 |
| `/rainbow-intel-history` | Intel geçmişi | IntelReportHistoryPage | `features/analytics/...` | 7 |
| `/settings/connected-accounts` | Entegrasyonlar | ConnectedPlatformsPage | `features/external_integrations/...` | 8 |
| `/settings/import-engine` | Import hub | ImportHubPage | `features/listing_import/...` | 8 |
| client tab 0 | Müşteri keşfet | ClientSearchPage | `screens/client_pages.dart` | 9 |

---

## Component migration strategy

| Legacy | Phase 1 v2 replacement | Migration |
|--------|------------------------|-----------|
| `ThemePalette` dark colors | `PremiumColorTokens` | **Done** — palette aligned |
| `AppThemeExtension` | unchanged API + `PremiumThemeExtension` | **Done** — dual extension |
| `PremiumCtaButton` | `PremiumButton` v2 | Phase 2+ screen-by-screen |
| `PremiumSurfaceCard` | `PremiumCard` v2 | Phase 2+ |
| `PremiumPageHeader` | `PremiumAppBar` v2 | Phase 2+ |
| `EmptyState` | `PremiumStateViews.empty` | Wrapper — same logic |
| `SyncStatusBanner` | `PremiumStateViews.offlineBanner` | Phase 2 shell |
| `PremiumBottomNavDock` | glass dock v2 | Phase 2 |

**Rule:** Screens keep existing widget tree until their phase; only global theme applies immediately.

---

## What NOT to touch (per phase)

- `lib/core/router/app_router.dart` — routes unchanged
- `lib/features/**/data/*`, `**/providers/*`, `**/domain/*` — business logic
- Firestore queries, auth guards, feature flags logic
- GoRouter redirects, role gates

---

## Phase 1 deliverables checklist

- [x] `PremiumColorTokens` — obsidian / navy / gold
- [x] `PremiumShadowTokens`, `PremiumMotionTokens`, `PremiumGlassTokens`
- [x] `PremiumThemeExtension` registered in `AppTheme`
- [x] `ThemePalette` dark mode aligned to Figma DNA
- [x] v2: `PremiumButton`, `PremiumCard`, `PremiumAppBar`
- [x] v2: `PremiumStateViews` (loading/empty/error/offline/skeleton)
- [x] v2: `PremiumSheetHandle`, `PremiumDialogShell`
- [x] Unit test: `test/core/theme/premium_design_system_test.dart`
- [x] Phase 2: wire v2 into shells (navigation chrome)

---

## Inventory reference

Full screen CSV: `docs/product_screen_inventory.csv`
