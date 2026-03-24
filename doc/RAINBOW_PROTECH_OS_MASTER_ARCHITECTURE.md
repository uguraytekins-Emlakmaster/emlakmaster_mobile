# Rainbow Gayrimenkul — Proptech OS Master Architecture

**Status:** Implementation-ready specification  
**Audience:** Product, engineering, compliance, ops  
**Companion docs:** `RAINBOW_PRODUCTION_SOURCE_OF_TRUTH.md` (MVP, release, analytics tek özeti), `PHASE1_FOUNDATION.md` (auth, boot, rol, bağlı platform kabuğu), `RAINBOW_CORE_IMPORT_ENGINE.md`, `PRODUCTION_AUTH_AND_SCALE.md`, `EXTERNAL_LISTING_INTEGRATION_ARCHITECTURE.md`, `FIRESTORE_EXTERNAL_CONNECTIONS.md`, `INTEGRATION_LISTINGS_SERVER_CONTRACT.md`

**North star:** Production-grade, legally cautious, scalable real estate operating system — **no fragile hacks**, **no false capability claims**.

---

## 1. Full technical scope summary

| Layer | In scope | Explicitly out of scope (until approved) |
|-------|-----------|------------------------------------------|
| **Client** | Flutter mobile (macOS/iOS/Android targets), Riverpod, go_router, theme tokens | Web CRM parity in one codebase (can share domain; separate shell OK) |
| **Identity** | Firebase Auth: email/password, Google, Apple (iOS/macOS UX + OAuth wiring); deterministic redirects | Storing third-party portal passwords in Firestore |
| **Tenancy** | Office → team → user; role + **permission strings** | Vague “isAdmin” only |
| **Integrations** | Capability matrix; adapter boundary; **Level 1–3** methods (see §2); sync health & logs | Bot-login-as-product; anti-bot bypass as primary UX |
| **Data** | Firestore collections below + Admin SDK writers; `integration_listings` read-only on client | Client write to integration secrets |
| **Import** | URL / file / manual tasks; extension-ready tokens | Scraping as the “happy path” promise |
| **Messaging** | Inbox when adapter + policy allow; honest “unsupported” UI | Implying reply works when it doesn’t |
| **Admin** | Office/global toggles; monitoring tables; audit (no raw secrets) | Raw credential view |

**Integration priority (safest first):**

1. **Level 1 — User-controlled:** URL paste, CSV/Excel/JSON import, structured tasks, “My Listings” management.  
2. **Level 2 — Browser companion:** Extension runs in **user’s** logged-in session; server receives **allowed** payloads; no app-side password vault for portals.  
3. **Level 3 — Advanced:** Official/partner APIs or sustainable server jobs; **capability-flagged**, **admin-gated**.

---

## 2. Auth + signup + onboarding flow

### 2.1 Sign-in methods

| Method | Source of truth | Notes |
|--------|-------------------|--------|
| Email + password | Firebase Auth | Rate limiting / `LoginAttemptGuard` (existing) |
| Google | Google Sign-In + Firebase credential | SHA/package diagnostics documented |
| Apple | Sign in with Apple + Firebase OAuth | Required for App Store parity; wire when Firebase Apple provider enabled |

**Phone OTP:** Not in v1; reserve `users.phone` + future provider.

### 2.2 Routing determinism (no white screen / loops)

**Inputs:** `currentUserProvider` + `users/{uid}` doc + `needsRoleSelectionProvider` + `OnboardingStore` (marketing onboarding + **workspace setup** flag).

**Current production sequence (simplified):**

```
unauthenticated → /onboarding (if first launch) OR /login
authenticated + needs Firestore user doc → /workspace-setup (first) → /role-selection
authenticated + role doc present → / (RoleBasedShell)
```

**Rules:**

- Single `GoRouter` + `refreshListenable` on auth/role changes.  
- Logged-in users hitting `/login` redirect to home **or** workspace/role if incomplete.  
- Paths allowed while `needsRole` + workspace done: connected accounts, my external listings, messages (see `app_router.dart` allowlist).

**Future hardening (recommended):** Replace boolean workspace flag with `users/{uid}.onboardingStep` enum: `profile | office | integrations | completed` for finer analytics and less redirect ambiguity.

### 2.3 Signup (premium)

**Fields:** full name, email, password, confirm password, **optional invite code** (Phase: add field + server validation against `invites`).

**Password policy:** min 8, ≥1 letter, ≥1 digit (existing validators).  
**Legal:** Terms + Privacy checkboxes with deep links (to be added on register page).  
**Post-signup:** Firebase user; Firestore `users/{uid}` created on role selection or invite apply (existing patterns).

### 2.4 First-time onboarding (product order)

1. **Office intent:** create office vs join by invite (implemented: `WorkspaceSetupPage`).  
2. **Role:** inherited from invite **or** chosen / defaulted via `RoleSelectionPage`.  
3. **Integrations:** connect platforms or skip → navigates to Connected Accounts or continues to role (implemented flow).

---

## 3. Office, team, and role model

### 3.1 Conceptual model

```
Office (company)
  └── Team (optional subgroup)
        └── User (consultant, etc.)
```

**Firestore (existing / target):**

- `users/{uid}` — `role`, `teamId`, `managerId`, `officeId` (extend as needed).  
- `teams/{teamId}` — exists.  
- `offices/{officeId}` — **to add** if not present as first-class collection (or embed in `app_settings` until migrated).

### 3.2 Role enum (current code)

`AppRole`: `super_admin`, `broker_owner`, `general_manager`, `office_manager`, `team_lead`, `agent`, `operations`, `finance_investor`, `investor_portal`, `client`, `guest`  
**File:** `lib/features/auth/domain/entities/app_role.dart`

### 3.3 Target business roles vs technical roles

Map product language to `AppRole` + **permissions**:

| Product role | Typical `AppRole` | Notes |
|--------------|-------------------|--------|
| Owner | `broker_owner` / `super_admin` | Office creator |
| Admin | `general_manager`, `office_manager` | Policy + users |
| Broker / Manager | `team_lead`, `office_manager` | Team scope |
| Consultant | `agent` | Default advisor |
| Assistant | `operations` | Narrower write |
| Viewer | custom or `client`-like read-only | May need new role id |

### 3.4 Granular permissions (implement as strings)

Store `users.permissions: string[]` **or** derive from role via `PermissionMatrix` in code + Firestore rules using custom claims **or** server-side checks for sensitive actions.

**Suggested permission keys:**

| Key | Description |
|-----|-------------|
| `manageOfficeSettings` | Office-level integration policy |
| `manageUsers` | Invite, disable users |
| `manageOwnListings` | Own imports/sync |
| `manageTeamListings` | Office/team listing visibility actions |
| `manageOwnIntegrations` | Own `external_connections` |
| `manageOfficeIntegrations` | All connections in office |
| `viewOwnMessages` | Message center own threads |
| `viewOfficeMessages` | Broader inbox |
| `replyMessagesIfSupported` | UI + server allow reply |
| `runManualSync` | Trigger sync job |
| `viewAdminDiagnostics` | Logs, health dashboards |
| `approveIntegrationConnection` | Pending connection approval |

**Rule:** UI gates with `FeaturePermission`-style helpers **and** Firestore rules **and** Cloud Functions verify for mutations.

---

## 4. Integration capability matrix

**Source type in app:** `IntegrationCapabilitySet`  
**File:** `lib/features/external_integrations/domain/integration_capability.dart`

### 4.1 Implemented flags (current)

- `canImportListings`, `canIncrementalSync`, `canReadMessages`, `canReplyMessages`, `canUpdatePrice`, `canUpdateStatus`, `canCreateListing`, `canDeleteListing`, `requiresManualExport`, `requiresReauth`, `supportsWebhook`, `supportsFeedImport`

### 4.2 Planned extensions (align naming in one migration)

| Flag | Purpose |
|------|---------|
| `canManualRefresh` | User-triggered sync (distinct from incremental) |
| `canLinkConversations` | Link thread ↔ lead/customer |
| `canUseBrowserExtension` | Server accepts extension token |
| `canUseFileImport` | CSV/XLSX/JSON path |
| `canUseUrlImport` | Paste URL import |
| `requiresReconnect` | UX badge / adapter state |
| `requiresManualApproval` | Admin gate before active |
| `hasOfficialSupport` | Marketing/legal safe labeling |
| `hasLimitedSupport` | Honest degraded mode |

**Registry:** `integration_capability_registry.dart` — per-platform **defaults**; **snapshot** on `ExternalConnectionEntity.capabilitySnapshot` for audit.

---

## 5. Data model (Firestore)

### 5.1 Collections — naming alignment

| Collection | Purpose | Client write |
|------------|---------|--------------|
| `users` | Profile, role, office refs | Owner-safe fields only (rules exist) |
| `teams`, `invites` | Structure | Manager rules |
| `external_connections` | Linked platform account metadata | **No** (Admin SDK) |
| `integration_listings` | Synced listing rows for “My Listings” | **No** (Admin SDK); see entity |
| `external_listings` | Market Pulse / client-seeded listings | Controlled write (existing rules) |
| `listing_import_tasks` | **New:** URL/file import jobs | Create own task; processing by Functions |
| `integration_sync_logs` or `sync_logs` | **New:** job audit | Functions |
| `office_integration_settings` | **New:** per-office policy | Manager/admin |
| `external_conversations`, `external_messages` | **New:** when messaging phase ships | Rules per office/user |

**Canonical listing row (synced):** `IntegrationSyncedListingEntity`  
**File:** `domain/integration_synced_listing_entity.dart`  
**Server contract:** `doc/INTEGRATION_LISTINGS_SERVER_CONTRACT.md`

### 5.2 ExternalConnection (target shape)

Extends current entity with:

- `officeId`, `connectionType` (`oauth` | `extension` | `import_only` | `server_partner`)  
- `credentialRef` / `tokenRef` (Secret Manager pointers only)  
- `lastValidatedAt`, `lastErrorCode`, `lastErrorMessage`  
- `capabilitySnapshot` (JSON)

### 5.3 ExternalListing / integration_listings

User spec maps to existing **`integration_listings`** docs + optional future **`external_listings_mirror`** if dual storage needed. Prefer **one** normalized listing store keyed by `(platform, externalListingId)` with `ownerUserId` + `officeId`.

### 5.4 ListingImportTask (new)

| Field | Notes |
|-------|--------|
| `importMethod` | `url` \| `csv` \| `xlsx` \| `json` \| `extension` |
| `sourceReference` | URL or Storage path |
| `status` | `pending` \| `processing` \| `completed` \| `failed` |
| Counters | parsed/imported/duplicate/error |

### 5.5 SyncLog

| Field | Notes |
|-------|--------|
| `syncType` | `full` \| `incremental` \| `manual` \| `message` |
| `itemCount`, `errorCode`, `details` | Structured, not free-text only |

---

## 6. Adapter architecture

### 6.1 Types

- `IntegrationPlatformId` — `lib/.../domain/integration_platform_id.dart`  
- `IntegrationResult` / `IntegrationErrorCode` — `domain/integration_result.dart`, `integration_error_code.dart`  
- `PlatformAdapter` — `application/platform_adapter.dart`

### 6.2 Interface (current)

`connect`, `disconnect`, `validateConnection`, `fetchListings`, `syncListings`, `fetchMessages`, `sendReply`, `updateListing`, `mapRawConnection`

### 6.3 Planned extensions

- `importFromUrl(String url)` → `IntegrationResult<ImportJobRef>`  
- `importFromFile(StorageRef)` → same  
- `getCapabilities()` → `IntegrationCapabilitySet` (instance may narrow registry defaults)  
- `mapExternalListingToInternal` / conversation mappers as pure functions for tests

**Stub:** `infrastructure/stub_platform_adapter.dart` — always returns typed unsupported/failure for production safety until real adapters registered.

**Registration:** `IntegrationProvider` — `lib/.../application/integration_provider.dart`

---

## 7. Admin settings — information architecture

### 7.1 Surfaces

- **Mobile:** `AdminShellPage` / settings sections (incremental).  
- **Web/desktop CRM (future):** Dedicated admin routes; same Firestore collections.

### 7.2 Admin nav (suggested)

1. **Integrations overview** — KPIs: active connections, failed syncs, reauth required.  
2. **Connections table** — filter: office, user, platform, health.  
3. **Import queue** — `listing_import_tasks` pending/failed.  
4. **Sync logs** — drill-down to `sync_logs`.  
5. **Policies** — `office_integration_settings`: allowed methods, roles, toggles.  
6. **Audit** — admin actions (disconnect, force sync) without secret payloads.

### 7.3 Actions (server-side only)

Force sync, disconnect, revalidate, approve connection, remap listing — **Callable Functions** + `audit_logs` entry.

---

## 8. Screen tree (routes)

| Screen | Route constant | Implementation |
|--------|----------------|----------------|
| Marketing onboarding | `/onboarding` | `OnboardingPage` |
| Login | `/login` | `LoginPage` + `AuthPageShell` |
| Register | `/register` | `RegisterPage` (2-step) |
| Workspace setup | `/workspace-setup` | `WorkspaceSetupPage` |
| Role selection | `/role-selection` | `RoleSelectionPage` |
| Home shell | `/` | `RoleBasedShellSelector` |
| Connected accounts | `/settings/connected-accounts` | `ConnectedAccountsPage` |
| My external listings | `/listings/my-external` | `MyExternalListingsPage` + inner on Listings tab |
| Message center | `/messages` | `MessageCenterPage` |
| Message thread | `/messages/thread` | `MessageThreadPage` (extra) |
| Admin integration settings | **TBD** e.g. `/admin/integrations` | **Not built** — placeholder route acceptable |

**Listings tab:** `ListingsPage` — segmented Portfolio / My listings when feature flag on.

---

## 9. Implementation file map

### 9.1 Exists (reference)

| Area | Path |
|------|------|
| Theme / DS | `lib/core/theme/design_tokens.dart`, `app_theme.dart`, `app_theme_extension.dart`, `rainbow_crm_theme.dart` |
| Router | `lib/core/router/app_router.dart` |
| Onboarding store | `lib/core/services/onboarding_store.dart` |
| Workspace UI | `lib/features/workspace/presentation/pages/workspace_setup_page.dart` |
| Auth | `lib/features/auth/presentation/pages/login_page.dart`, `register_page.dart`, `role_selection_page.dart`, `auth_page_shell.dart` |
| Integrations domain | `lib/features/external_integrations/domain/*` |
| Adapters | `application/platform_adapter.dart`, `integration_provider.dart`, `stub_platform_adapter.dart` |
| Capability registry | `application/integration_capability_registry.dart` |
| Repos | `data/external_connections_repository.dart`, `data/integration_listings_repository.dart` |
| UI | `presentation/pages/connected_accounts_page.dart`, `my_external_listings_page.dart`, widgets under `presentation/widgets/` |
| Messages | `lib/features/messages/presentation/pages/message_center_page.dart`, `message_thread_page.dart` |
| Rules | `firestore.rules`; docs: `FIRESTORE_EXTERNAL_CONNECTIONS.md`, `INTEGRATION_LISTINGS_SERVER_CONTRACT.md` |
| Backend helper | `functions/integrationListingsAdmin.js` |

### 9.2 To build (prioritized)

| Priority | Deliverable |
|----------|-------------|
| P0 | `users.permissions` + matrix; Firestore `offices` if missing |
| P0 | `listing_import_tasks` + URL import Cloud Function + mobile wizard entry |
| P0 | Extend `IntegrationCapabilitySet` + registry + **honest** Connected Accounts cards |
| P1 | File import wizard + Storage upload + mapping UI |
| P1 | `integration_sync_logs` + admin list (mobile or web) |
| P1 | Apple Sign-In E2E (Firebase + iOS) |
| P2 | `external_conversations` / messages when adapter supports |
| P2 | Extension token model + HTTPS handoff endpoint spec |
| P2 | Admin integration routes + audit |

---

## 10. Phased coding plan

### Phase 1 (foundation — align with current sprint)

1. **Permissions:** Add `Permission` enum/string set + `FeaturePermission` extensions; gate Connected Accounts / import / admin.  
2. **Data:** Firestore indexes for `listing_import_tasks` (status + officeId).  
3. **Capabilities:** Extend `IntegrationCapabilitySet` + migrate JSON snapshots.  
4. **UI:** Connected Accounts cards = logo placeholder, status chips, actions wired to stub with **explicit** unsupported SnackBars.  
5. **Legal:** Terms/Privacy on signup; store `termsAcceptedAt`.

### Phase 2 (import + observability)

1. URL import: `POST` Callable → validates URL → enqueue task → worker parses → writes `integration_listings`.  
2. File import: upload → task → preview screen (duplicate detection).  
3. Sync logs UI (consultant + admin).  
4. My Listings: office-wide mode behind permission; merge duplicates (hash + fuzzy).

### Phase 3 (messages + extension-ready + admin)

1. Adapter `fetchConversations` backed by real source **only** if capability.  
2. Message composer gated by `replyMessagesIfSupported`.  
3. Extension session tokens + rotation policy documented + minimal endpoint.  
4. Admin dashboards + force actions + alerts.

---

## 11. Failure handling (typed)

**Client:** Map `IntegrationErrorCode` → localized banner; never throw in widget build.  
**Server:** Structured `errorCode` in `sync_logs`; retry policy for transient errors.  
**User-facing copy:** Distinguish reauth, unsupported, partial success, platform down.

---

## 12. Security & compliance checklist

- [ ] No plaintext portal passwords in Firestore  
- [ ] `tokenRef` / Secret Manager for OAuth/extension  
- [ ] Firestore rules: user can only read own connections unless manager  
- [ ] Admin audit log for destructive actions  
- [ ] UI masks emails/account ids where required  
- [ ] Capability-driven UI — **no fake buttons**

---

*This document is the master index; detailed field-level schemas remain in `EXTERNAL_LISTING_INTEGRATION_ARCHITECTURE.md` and should be merged when collections are finalized.*
