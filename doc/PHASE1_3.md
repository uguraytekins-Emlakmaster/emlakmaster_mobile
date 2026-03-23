# Phase 1.3 — Ofis güvenliği, üyelik bütünlüğü, migrasyon, yönetim

## 1. Domain model

| Koleksiyon | Amaç |
|------------|------|
| `offices/{id}` | Ofis kaydı |
| `office_memberships/{uid}_{officeId}` | Birincil üyelik (durum + rol) |
| `office_invites/{id}` | Kısa kodlu davet |
| `users/{uid}` | `officeId` işaretçisi + **legacy** `role` |

**Not:** `officeId` içinde `_` kullanılmamalı; birincil doküman kimliği `uid + '_' + officeId` ile üretilir.

## 2. Rol kaynağı (source of truth)

- **Ofis bağlamı + aktif üyelik:** `office_memberships.role` → `OfficeRole.toAppRole()` → `AppRole`.
- **`users.role`:** Ofis öncesi veya geçiş için **legacy**; ofis + aktif üyelik varken **yetkilendirme için kullanılmamalı**.
- Politika metni: `lib/features/office/domain/role_source_of_truth.dart`.

## 3. Üyelik yaşam döngüsü

`MembershipStatus`: `invited` → `active` | `suspended` | `removed`.

- **Tam uygulama erişimi:** yalnızca `active` (`allowsFullOfficeAccess`).
- **Routing:** `OfficeAccessState` (`office_access_state.dart`) — `deriveOfficeAccessState`.

## 4. Bütünlük ve migrasyon

- `OfficeIntegrityService`: işaretçi ↔ üyelik eşleşmesi.
- `OfficeMigrationService.clearOfficePointerIfMembershipMissing`: üyelik yoksa `officeId` temizliği (kurallar: `userClearsInvalidOfficePointer`).
- Kurtarma UI: `/office/recovery`.

## 5. Davet güvenliği

- İstemci: `OfficeSetupService` (owner daveti yok, manager hiyerarşisi, süre / limit / aktiflik).
- Sunucu: `firestore.rules` — `office_invites` oluşturma (rol ≠ owner), `usedCount` artışı tutarlılığı, `office_memberships` güncelleme.

## 6. Güvenlik matrisi (özet)

| Eylem | Kim | Koruma |
|-------|-----|--------|
| Ofis oluşturma | Giriş yapmış kullanıcı | `offices` create + batch |
| Üyelik oluşturma (katıl) | Kendi uid | `office_memberships` create |
| `users` officeId + role (katılma) | Kendi doc | `userOfficeJoinAllowed` |
| Davet oluşturma | owner/admin/manager | `canManageOfficeMembers` |
| Davet kullanımı | Herhangi üye | `officeInviteIncrementConsistent` |
| Üye askı / kaldır | owner/admin/manager | membership update + `managerClearedRemovedMemberOfficePointer` |
| Ofis adı | owner/admin | `offices` update |

**İleride:** Cloud Functions ile kritik yazımların tamamen sunucuya taşınması önerilir.

## 7. Yönetim UI

- `/office/admin` — üye listesi, durum chip’leri, davet listesi, pasifleştirme, askı / kaldır.
- Cmd+K: **Ofis yönetimi** komutu.

## 8. Çoklu ofis (gelecek)

Şu an tek birincil `officeId`/`users` varsayımı; çoklu ofis seçildiğinde `primaryMembershipProvider` ve `deriveOfficeAccessState` genişletilmelidir.

## 9. Testler

`test/features/office/office_domain_test.dart` — `deriveOfficeAccessState`.
