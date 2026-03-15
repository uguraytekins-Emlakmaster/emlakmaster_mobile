# Gerçek Kullanıcı ve Rol Yönetimi

## 1. Firebase Auth

- **Giriş:** Email + şifre (`AuthService.signInWithEmailAndPassword`).
- **Çıkış:** `AuthService.signOut()` (Ayarlar sayfasında "Çıkış yap").
- **Session:** `authStateChanges` stream ile otomatik; sayfa yenilense bile giriş korunur.

Firebase Console’da **Authentication → Sign-in method** içinde **Email/Password** etkin olmalı.

---

## 2. Firestore `users` koleksiyonu

Her giriş yapan kullanıcı için doküman: `users/{uid}`

| Alan       | Açıklama                          |
|-----------|------------------------------------|
| uid       | Firebase Auth UID                  |
| name      | İsim (opsiyonel)                   |
| email     | E-posta                            |
| role      | Aşağıdaki değerlerden biri         |
| isActive  | boolean, varsayılan true           |
| createdAt | timestamp                          |
| updatedAt | timestamp                          |

**role değerleri:** `super_admin`, `broker`, `office_manager`, `team_lead`, `agent`, `operations`, `investor`

Uygulama içinde `AppRole` enum’u ile eşlenir (örn. `broker` → `brokerOwner`, `investor` → `investorPortal`).

---

## 3. Rol akışı (Role Provider)

1. `currentUserProvider`: Firebase Auth `authStateChanges` stream.
2. `userDocStreamProvider(uid)`: Firestore `users/{uid}` snapshot stream.
3. **İlk kullanıcı:** Koleksiyonda hiç doküman yoksa, giriş yapan kullanıcı için `users/{uid}` oluşturulur ve `role: super_admin` atanır (ilk admin).
4. **Sonraki kullanıcılar:** `users/{uid}` yoksa `role: agent` ile doküman oluşturulur; yönetici sonradan rolü değiştirebilir.
5. `currentRoleProvider`: AsyncValue&lt;AppRole&gt; (loading / data / error).
6. `displayRoleProvider`: Test için geçici rol override (Ayarlar’daki “Rol değiştir”) varsa onu, yoksa Firestore’daki rolü döner.

---

## 4. Auth guard

- **Kullanıcı yok** → Login sayfası.
- **Kullanıcı var, rol yükleniyor** → Loading ekranı.
- **Rol yüklendi** → Ana uygulama (router).

`AuthGuard` tüm uygulamayı sarmalıyor; giriş yoksa router yerine `LoginPage` gösterilir.

---

## 5. Yetki entegrasyonu

- **Command Center:** Sadece `canViewAllCalls(role)` (yönetici / operasyon) erişir; diğerleri `UnauthorizedScreen`.
- **Dashboard “Çağrı Merkezi” butonu:** Sadece `canViewAllCalls(displayRole)` ise görünür.
- **Rol değiştirici (test):** Ayarlar’da, sadece **debug modda** ve rol `superAdmin` veya `brokerOwner` ise “Rol değiştir” çıkar; geçici rol `overrideRoleProvider` ile saklanır.

---

## 6. Ek özellikler

- **Hoş geldin Patron:** İlk kez `super_admin` olarak girişte (session’da bir kez) “Sistemin temelleri atıldı” karşılama diyaloğu.
- **Command palette:** Cmd+K (Mac) / Ctrl+K (Windows) ile hızlı komut paneli (Dashboard, Çağrı Merkezi, Ayarlar).
- **Audit log:** `AuditLogService.logAdminAction(...)` ile kritik admin aksiyonları `audit_logs` koleksiyonuna yazılabilir (yetki değişikliği vb.).

---

## 7. Test

- `test/features/auth/permission_test.dart`: `canViewAllCalls`, `canManageSettings`, `AppRole.fromId`, `AppRole.fromFirestoreRole` (broker→brokerOwner, investor→investorPortal) testleri.
