# Phase 1.2 — Ofis, üyelik, davet (çok kiracılı çekirdek)

## Mimari

- **Office** (`offices/{id}`): ofis adı, `createdBy`, `planType`, `settings`.
- **OfficeMembership** (`office_memberships/{userId}_{officeId}`): `officeId`, `userId`, `role`, `status`, isteğe bağlı `permissions`.
- **OfficeInvite** (`office_invites/{id}`): `code` (benzersiz), `roleToAssign`, `maxUses`, `usedCount`, `expiresAt`, `isActive`.
- **users/{uid}.officeId**: birincil ofis işaretçisi (üyelikle tutarlı tutulmalı).

Yetki: `office_memberships.role` → `OfficeRole.toAppRole()` → mevcut [RolePermissionRegistry] / `FeaturePermission`.

## Akış

1. Onboarding / rol seçimi (mevcut) tamamlandıktan sonra `users.officeId` yoksa → **`/office`** (kapı).
2. **Oluştur**: batch ile ofis + owner üyeliği + `users.role = broker_owner` + `officeId`.
3. **Katıl**: transaction ile davet doğrulama + `usedCount++` + üyelik + `users` güncelleme.

## Yönlendirme

`needsOfficeSetupProvider` + `GoRouter.redirect` — butonlarda `context.go` yok; izin verilen path’ler: `/office`, `/office/create`, `/office/join`.

Davet oluşturma: `/office/invite/create` (ofis hazırken; Cmd+K → «Ofis daveti oluştur»).

## Firestore indeksleri

`firestore.indexes.json`: `office_memberships` (`userId` + `status`), `office_invites` (`code` + `isActive`). Deploy: `firebase deploy --only firestore:indexes`.

## Güvenlik

İstemci doğrulaması yanıltıcı olabilir; **Firestore Security Rules** ile `officeId`, üyelik ve davet yazmalarını sunucuda kilitleyin.

## Testler

`test/features/office/office_domain_test.dart`
