# External Listing Platform Integration — Production Architecture

**Product:** Rainbow Gayrimenkul CRM (Flutter + Firebase)  
**Scope:** Account linking, listing sync, optional messaging, admin observability — **not** a generic scraper.  
**Version:** 1.0 (architecture & implementation plan)

---

## 1. Technical scope summary

| Layer | In scope | Out of scope (v1) |
|-------|-----------|-------------------|
| **Identity** | Firebase Auth (email, Google, Apple); office/team membership; RBAC extension | Phone OTP (optional later) |
| **Connections** | Register platform adapters; store **token refs** only; capability matrix per platform | Storing plaintext passwords in Firestore |
| **Sync** | Scheduled + manual sync; idempotent upsert; `syncHash`; conflict rules | Full two-way CRUD for every platform |
| **Data** | `ExternalConnection`, `ExternalListing`, `ExternalConversation`, `ExternalMessage` (+ internal mapping) | Real-time bidirectional message sync where API absent |
| **Client UI** | Connected Accounts, My Listings, Message Center (gated by capabilities) | End-user OAuth for platforms without official API (unless product/legal approves bridge) |
| **Admin** | Office/global integration settings; monitoring tables; force actions | Raw credential viewing |

**Hard constraints:**

- Every adapter method returns **`IntegrationResult<T>`** (success / unsupported / typed error). No throws for “not supported”.
- Capabilities come from **registry + per-connection snapshot** (immutable audit of what was true at link time).
- Secrets: **only** via Cloud Secret Manager / encrypted fields + **reference IDs** in Firestore (`tokenRef`, `encryptedCredentialRef`), never raw tokens in client-readable documents.

---

## 2. Auth / signup / login flow design

### 2.1 Sign-in methods (Firebase)

| Method | Implementation |
|--------|----------------|
| Email + password | `FirebaseAuth.createUserWithEmailAndPassword` / `signInWithEmailAndPassword` |
| Google | `GoogleSignIn` + `FirebaseAuth.signInWithCredential` |
| Apple | `SignInWithApple` + `FirebaseAuth.signInWithCredential` (iOS required for App Store parity) |

### 2.2 Signup screen (premium)

**Fields (required):** full name, email, password, confirm password.  
**Optional:** office invite code (`inviteToken` or `officeId` + short code).  
**Required UX:** Terms + Privacy checkboxes (links to in-app WebView or external URLs).  
**Validation:** email format, password policy (min 8, complexity as product defines), match confirmation.

**Post-submit:**

1. Create Firebase user.
2. Write `users/{uid}` with: `displayName`, `email`, `createdAt`, `onboardingStep`, `role` (see below).
3. If **valid invite**: resolve invitation doc → set `role`, `officeId`, `teamId` from invite; mark invite consumed.
4. If **no invite**: `role` = `consultant` (or `broker_owner` if “create office” path selected in wizard — product decision: default **consultant** until office created).
5. Navigate to **post-login setup wizard** (`onboardingStep != completed`).

### 2.3 Login screen

- Email + password + Google + Apple buttons (same visual hierarchy as signup).
- **Password reset:** dedicated route/modal; on submit show **explicit** success (“E-posta gönderildiyse…”) or error from Firebase; no generic spinner without terminal state.
- **Keyboard:** `ScrollView` + `FocusScope` + dismiss on tap outside; `resizeToAvoidBottomInset: true`.

### 2.4 Routing determinism (no white screen / no loops)

**Single source of truth:** `AsyncValue<User?>` + `users/{uid}.onboardingStep` + `users/{uid}.role`.

**State machine (conceptual):**

```
unauthenticated → /login
authenticated + emailVerified? (if required) → /verify-email OR next
authenticated + onboardingStep == null | 'profile' → /onboarding/profile
authenticated + onboardingStep == 'office' → /onboarding/office
authenticated + onboardingStep == 'integrations' → /onboarding/integrations (skippable)
authenticated + onboardingStep == 'completed' → role shell (Admin/Consultant/Client)
```

**Rules:**

- **One** `GoRouter` redirect that reads `authState` + Firestore user doc (cache-first with timeout to avoid infinite loading — show skeleton, not white).
- After login, **never** bounce between `/` and `/login` because of a race: use `refreshListenable` or `ref.listen` with debounce; **do not** redirect until `users/{uid}` exists (create on first signup if missing).

### 2.5 Post-login setup wizard (first time)

**Step A — Office mode**

- “Ofis oluştur” → create `offices/{officeId}`, set user as owner/admin; `users/officeId` set.
- “Davet kodu ile katıl” → validate invite → attach `officeId` / team.

**Step B — Role** (only if not fixed by invite)

- Show allowed roles for office (e.g. consultant vs team lead) per `office policy`.

**Step C — Integrations** (skippable)

- Short explanation + CTA “Harici bağlantıları yönet” → `/settings/connected-accounts` or skip → `onboardingStep = completed`.

---

## 3. Data model (Firestore + references)

### 3.1 Collections (recommended names)

| Collection | Purpose |
|------------|---------|
| `external_connections` | One doc per linked platform account |
| `external_listings` | Normalized listing copy + mapping |
| `external_conversations` | Inbox threads (if supported) |
| `external_messages` | Subcollection `external_conversations/{id}/messages` OR top-level with `conversationId` (prefer subcollection for pagination) |
| `integration_sync_runs` | Audit log of sync jobs (optional Phase 2) |
| `integration_audit_logs` | Admin + user action audit |
| `office_integration_settings` | Per-office overrides (doc id = `officeId`) |
| `platform_integration_defaults` | Global defaults (single doc or `app_settings/integration`) |

### 3.2 `ExternalConnection` (document fields)

| Field | Type | Notes |
|-------|------|--------|
| `id` | string | Doc id |
| `userId` | string | Owner consultant |
| `officeId` | string | Required for multi-tenant |
| `platform` | string | `sahibinden` \| `hepsiemlak` \| `emlakjet` |
| `externalAccountId` | string | Platform’s user/store id |
| `accountDisplayName` | string | Masked if needed |
| `connectionStatus` | string | `connected` \| `disconnected` \| `needs_reauth` \| `limited` \| `error` |
| `authMethod` | string | `oauth2` \| `api_key` \| `manual_export` \| `browser_session` \| `unknown` |
| `encryptedCredentialRef` | string? | Pointer to Secret Manager path or KMS key id |
| `tokenRef` | string? | Pointer to refresh token blob |
| `capabilitySnapshot` | map | Copy of capabilities at connect time |
| `lastValidatedAt` | timestamp? | |
| `lastSyncedAt` | timestamp? | |
| `lastError` | string? | User-safe message |
| `lastErrorCode` | string? | Typed: `authExpired`, … |
| `createdAt` | timestamp | |
| `updatedAt` | timestamp | |
| `createdBy` | string | uid |
| `disabledByAdmin` | bool | |

**Indexes:** `(officeId, platform)`, `(userId, platform)`, `(connectionStatus, lastSyncedAt)`.

### 3.3 `ExternalListing`

| Field | Type | Notes |
|-------|------|--------|
| `id` | string | Doc id (stable: hash or `${platform}_${externalListingId}`) |
| `connectionId` | string | FK |
| `platform` | string | |
| `externalListingId` | string | |
| `internalListingId` | string? | Map to `listings/{id}` if exists |
| `title`, `description` | string | |
| `price` | number? | |
| `currency` | string | `TRY` default |
| `listingType` | string | sale / rent / … |
| `category` | string | |
| `city`, `district`, `neighborhood` | string | |
| `images` | array of strings | URLs |
| `status` | string | active / sold / withdrawn / platform-specific |
| `sourceUrl` | string | |
| `platformUpdatedAt` | timestamp? | |
| `importedAt` | timestamp | |
| `syncedAt` | timestamp | |
| `syncHash` | string | For change detection |
| `ownerUserId` | string | |
| `officeId` | string | |
| `rawPayload` | map | Sanitized; size limit |
| `duplicateGroupId` | string? | For dedup UI |
| `createdAt`, `updatedAt` | timestamp | |

**Indexes:** `(ownerUserId, platform)`, `(officeId, platform, syncedAt desc)`, `externalListingId` + `platform` composite for upsert.

### 3.4 `ExternalConversation` / `ExternalMessage`

As specified; add:

- `external_conversations.syncStatus`: `synced` \| `pending` \| `failed`
- `external_messages.deliveryStatus`: `sent` \| `delivered` \| `failed` \| `unknown`

---

## 4. Integration adapter architecture

### 4.1 Core types (Dart)

```text
lib/features/external_integrations/
  domain/
    integration_platform_id.dart      // enum: sahibinden, hepsiemlak, emlakjet
    integration_capability.dart       // enum flags + CapabilitySet
    integration_result.dart           // sealed: Success | Unsupported | Failure
    integration_error_code.dart       // authExpired, rateLimited, ...
    external_connection_entity.dart
    external_listing_entity.dart
    external_conversation_entity.dart
    external_message_entity.dart
  application/
    integration_capability_registry.dart  // static matrix per platform
    platform_adapter.dart                 // abstract interface
  infrastructure/
    adapters/
      sahibinden_adapter.dart
      hepsiemlak_adapter.dart
      emlakjet_adapter.dart
    integration_provider.dart             // resolves adapter by platform
```

### 4.2 `PlatformAdapter` interface (methods)

Each method returns `Future<IntegrationResult<T>>`.

| Method | Purpose |
|--------|---------|
| `connect(ConnectRequest)` | OAuth / token exchange; returns `ExternalConnection` draft |
| `disconnect(connectionId)` | Revoke locally + optional remote |
| `validateConnection(connectionId)` | Health check |
| `fetchListings(cursor?)` | Page import |
| `syncListings()` | Full/incremental per capability |
| `fetchMessages(cursor?)` | If supported |
| `sendReply(conversationId, body)` | If supported |
| `updateListing(externalListingId, patch)` | Price/status/metadata |
| `mapExternalListingToInternal(raw)` | DTO → entity |
| `mapExternalConversationToInternal(raw)` | DTO → entity |

**Unsupported:** return `IntegrationResult.unsupported('fetchMessages')` — never throw.

### 4.3 Capability registry (example structure)

Not hardcoded behavior in UI — **read from registry** + **snapshot on connection**.

| Platform | canImportListings | canIncrementalSync | canReadMessages | … |
|----------|-------------------|--------------------|-----------------|----|
| sahibinden | true | false | **TBD** (often false without official API) | … |
| hepsiemlak | **TBD** | **TBD** | **TBD** | … |
| emlakjet | **TBD** | **TBD** | **TBD** | … |

Product + legal fills “TBD”; engineering **implements** flags, does not assume.

### 4.4 Server-side orchestration

- **Cloud Functions** (or Cloud Run) for: token refresh, sync jobs, webhook endpoints (`supportsWebhook`), rate limiting.
- **Client** calls HTTPS Callable: `startSync`, `forceSync`, `sendReply` — validates permissions server-side.

---

## 5. Admin settings — information architecture

### 5.1 Navigation

**Admin → Ayarlar → Platform entegrasyonları** (new section)

Subsections:

1. **Genel** — default sync interval, global enable/disable per platform, duplicate mode, manual approval.
2. **Ofis politikaları** — which roles may connect accounts; per-office overrides.
3. **Mesajlar** — import inbound messages; auto-link to leads.
4. **Bildirimler** — error email / webhook URL for sync failures.
5. **İzleme** — tables (read-only + actions).

### 5.2 Settings keys (Firestore)

| Key | Type | Description |
|-----|------|-------------|
| `integration.defaultSyncIntervalMinutes` | int | e.g. 60 |
| `integration.platforms.sahibinden.enabled` | bool | |
| `integration.duplicateHandling` | string | `keep_both` \| `merge_suggested` \| `manual` |
| `integration.manualApprovalNewConnections` | bool | |
| `integration.autoLinkToLeads` | bool | |
| `integration.allowedRoles` | array | e.g. `consultant`, `team_lead` |
| `integration.errorWebhookUrl` | string (secret ref) | |

### 5.3 Admin monitoring views (columns)

**Connections table:** user, office, platform, status, last sync, last error, reauth flag, actions.  
**Listings health:** orphan count, duplicate count, last global sync.  
**Failures:** failed sync count (24h), rate limit hits.

### 5.4 Admin actions (callable + audit)

Each action writes `integration_audit_logs` with `adminUid`, `action`, `targetId`, `timestamp`.

---

## 6. Screen tree (routes)

Paths are illustrative; align with `app_router.dart`.

| Route | Screen | Notes |
|-------|--------|------|
| `/auth/register` | `RegisterPage` (polish) | + terms |
| `/auth/login` | `LoginPage` | + reset password |
| `/auth/forgot-password` | `ForgotPasswordPage` | explicit states |
| `/onboarding` | `OnboardingShell` | stepper |
| `/onboarding/office` | `OfficeSetupPage` | create / join |
| `/onboarding/integrations` | `IntegrationsIntroPage` | skip |
| `/settings/connected-accounts` | `ConnectedAccountsPage` | platform cards |
| `/settings/connected-accounts/:platform` | `PlatformConnectionDetailPage` | reconnect, sync |
| `/listings/my` | `MyExternalListingsPage` | **Benim İlanlarım** |
| `/listings/my/:id` | `MyExternalListingDetailPage` | capabilities, edit |
| `/messages/external` | `ExternalMessageCenterPage` | unified inbox |
| `/messages/external/:conversationId` | `ExternalConversationDetailPage` | reply if supported |
| `/admin/settings/integrations` | `AdminIntegrationSettingsPage` | |
| `/admin/monitoring/integrations` | `AdminIntegrationMonitoringPage` | |

**Consultant shell:** add tab or menu entry “Benim İlanlarım” / “Harici bağlantılar”.

---

## 7. Permissions (typed)

Map to existing `FeaturePermission` / custom claims:

| Permission | Description |
|------------|-------------|
| `manageOwnIntegrations` | Connect/disconnect own accounts |
| `manageOfficeIntegrations` | Office-wide connections (manager) |
| `viewExternalMessages` | See Message Center |
| `replyExternalMessages` | Send reply (if platform supports) |
| `updateExternalListings` | Price/status updates |
| `forceSync` | Manual sync (self or office) |
| `managePlatformSettings` | Admin settings |

Firestore rules: enforce `officeId` match + role + permission flags (stored in `users` or custom claims).

---

## 8. Failure handling (typed errors)

```dart
enum IntegrationErrorCode {
  unsupported,
  authExpired,
  rateLimited,
  malformedPayload,
  temporaryUnavailable,
  permissionDenied,
  reconnectRequired,
}
```

UI maps each to **one** user-facing string + optional “Tekrar dene” / “Yeniden bağlan”.

---

## 9. Implementation phases (code planning)

### Phase 1 (foundation)

1. **Domain models** + Firestore serializers for `ExternalConnection`, `ExternalListing` (conversations optional stub).
2. **`integration_capability_registry` + `PlatformAdapter` interface + `IntegrationResult`** sealed types.
3. **Stub adapters** for three platforms (all methods return `unsupported` or mock data behind feature flag).
4. **Connected Accounts UI** — cards + status chips + empty states (no real OAuth yet if not approved).
5. **Auth polish** — register page fields, terms, forgot password states; router onboarding flags.
6. **Office wizard** — reuse/create office flows; persist `onboardingStep`.

### Phase 2 (sync + My Listings + admin)

1. **Callable `syncExternalListings`** + Cloud Function worker + idempotent upsert to `external_listings`.
2. **My Listings** screen: filter by platform, badges, sync time, mapping indicator.
3. **Admin integration settings** + **monitoring table** (read from Firestore + Cloud Functions metrics).
4. **Sync history** collection or subcollection on `external_connections`.

### Phase 3 (messages + updates + audit)

1. **Conversations/messages** import pipeline + Message Center UI.
2. **Update listing** actions behind capability checks + optimistic UI only when safe.
3. **Audit log** for all admin actions and sensitive user actions.
4. **Retries**, diagnostics screen for admin (technical), user-friendly copy for consultants.

---

## 10. Alignment with existing codebase

- **Listings today:** `ListingsPage` + `ListingsPortfolioStream` / `external_listings` — evolve toward **user-scoped** `external_listings` filtered by `ownerUserId` + `connectionId` for “Benim İlanlarım”.
- **RBAC:** extend `ARCHITECTURE_RBAC.md` with new routes (consultant vs admin).
- **Market Pulse / ingest:** keep **GitHub Actions / Playwright** as **optional** feed; **connected accounts** are **first-class** product path — document distinction in UI (“Ofis içi senkron” vs “Kişisel hesap bağlantısı”).

---

## 11. Next immediate engineering tasks (ordered)

1. ~~Add `doc/EXTERNAL_LISTING_INTEGRATION_ARCHITECTURE.md` (this file) to backlog cross-link in `BACKLOG.md`.~~
2. ~~Create `lib/features/external_integrations/domain/` with entities + `IntegrationResult` + `PlatformAdapter`.~~ **Phase 1 done**
3. ~~Register placeholder routes in `app_router.dart` behind `featureFlags` key `feature_external_integrations`.~~ Route: `AppRouter.routeConnectedAccounts`
4. Firestore security rules: see `doc/FIRESTORE_EXTERNAL_CONNECTIONS.md`
5. Phase 2: `integration_listings` ingest + «Benim İlanlarım» ekranı

### Phase 1 (implemented)

- Paket: `lib/features/external_integrations/` — domain, application, infrastructure (stub), data (repository), presentation (`ConnectedAccountsPage`).
- Özellik bayrağı: `AppConstants.keyFeatureExternalIntegrations` (ayarlarda switch + giriş).

---

*This document is the single source of truth for the integration initiative until superseded by a versioned RFC.*
