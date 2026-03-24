# Phase 1 — Foundation (Rainbow Gayrimenkul)

**Kapsam:** Auth, boot, onboarding, ofis/rol temeli, bağlı platform kabuğu, güvenlik, duplicate-ready model, admin hazırlığı.  
**Dışında:** Ağır scraping, tarayıcı uzantısı, AI skorlama, tam otomasyon (sonraki fazlar).

---

## 1. Technical scope summary

| Alan | Phase 1 teslimi |
|------|------------------|
| Auth | E-posta, Google; Apple altyapısı (paket + servis iskelesi); deterministik yönlendirme |
| Boot | Firebase init + `OnboardingStore.warmUp`; kullanıcı dokümanı yüklenene kadar shell’de yükleme |
| Onboarding | SharedPreferences ile tek sefer; workspace setup bayrağı |
| Rol / izin | `AppRole` + `FeaturePermission` + yeni `PermissionId` / `RolePermissionRegistry` |
| Bağlı platformlar | `IntegrationCapabilitySet` genişletildi; UI dürüst placeholder |
| Veri modeli | `integration_listings` için `canonicalListingId`, `duplicateGroupId`, `syncStatus`, `rawPayload` |
| Güvenlik | Mevcut Firestore kuralları + istemci yükseltme engeli; audit temeli `audit_logs` |
| Test | Kritik bootstrap / izin testleri |

---

## 2. Current risk list (mitigated)

| Risk | Önlem |
|------|--------|
| users doc yüklenirken `guest` ile yanlış shell | `RoleBasedShellSelector` artık `userDocStreamProvider` ile bekliyor |
| Beyaz ekran | Mevcut `ColoredBox` + shell loading; doc yokken yükleme |
| Route loop | `needsRole` + doc stream tutarlılığı |
| Şifre sıfırlama | Sheet içinde `_sent` durumu (mevcut) |
| Dağınık OAuth | `GoogleOAuthConstants` merkezi (mevcut) |

---

## 3. Proposed architecture (mevcudu genişlet)

```
lib/core/startup/          # Boot fazları (isteğe bağlı genişletme)
lib/core/navigation/       # navigation_gate (isteğe bağlı)
lib/core/permissions/      # PermissionId + RolePermissionRegistry
lib/features/auth/         # Mevcut Riverpod + UserRepository
lib/features/external_integrations/
```

---

## 4. Boot flow design

1. `main` → Firebase init (timeout korumalı) → `OnboardingStore.warmUp` → `runApp`  
2. `currentUserProvider` auth stream  
3. `userDocStreamProvider(uid)` Firestore stream  
4. Router redirect: kullanıcı var + rol gerekiyorsa workspace / role  
5. **Shell:** `userDocStreamProvider` **loading** veya **doc==null** → `_ShellLoading` (yanlış panel yok)

---

## 5. Auth flow design

- Giriş: `AuthService` + `LoginAttemptGuard`  
- Sosyal: `GoogleAuthService`; Apple: `AppleAuthService` (yapılandırma sonrası)  
- Hata: `userFriendlyAuthError` + Firebase kodları  

---

## 6. Office / team / role model

- **Şu an:** `users/{uid}` içinde `role`, `teamId`, `managerId`  
- **Hedef (Faz 2+):** `offices/{id}`, `office_memberships` — Phase 1’de domain taslakları dokümante; tam Firestore şeması sonraki sprint  

---

## 7. Connected platform foundation

- `IntegrationPlatformId`, `IntegrationCapabilitySet`, `IntegrationCapabilityRegistry`  
- Bağlantı: `ExternalConnectionEntity` + stub adapter  

---

## 8. Duplicate-ready data model

- `IntegrationSyncedListingEntity`: `canonicalListingId`, `duplicateGroupId`, `syncStatus`, `rawPayload`, `updatedAt`  
- Sunucu: `integrationListingsAdmin.js` ile uyumlu opsiyonel alanlar  

---

## 9. Files created / updated (implementation)

- `doc/PHASE1_FOUNDATION.md` — bu dosya  
- `lib/core/permissions/permission_id.dart`  
- `lib/core/permissions/role_permission_registry.dart`  
- `lib/features/external_integrations/domain/integration_capability.dart` — genişletilmiş bayraklar  
- `lib/features/external_integrations/application/integration_capability_registry.dart`  
- `lib/features/external_integrations/domain/integration_synced_listing_entity.dart`  
- `functions/integrationListingsAdmin.js` — opsiyonel alanlar  
- `lib/screens/role_based_shell.dart` — user doc gate  
- `lib/features/auth/presentation/providers/auth_provider.dart` — `userDocBootstrapPendingProvider`  
- `test/phase1/user_doc_bootstrap_test.dart`  

---

## 10. Implementation order (tamamlandı / sıra)

1. ✅ Shell + auth provider bootstrap bayrağı  
2. ✅ Capability + entity + server payload  
3. ✅ Permission registry  
4. ✅ Tests  
5. ⏭ Apple tam OAuth: Firebase Console + `sign_in_with_apple` + `AppleAuthService` gövdesi (opsiyonel hemen)  

---

## Tek kaynak

Ürün özeti ve release ile birlikte: `RAINBOW_PRODUCTION_SOURCE_OF_TRUTH.md`.
