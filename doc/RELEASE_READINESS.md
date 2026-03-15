# Release Readiness – QA / Acceptance Sonrası

## Yapılan Düzeltmeler (Bu Tur)

### Yetki (Permission)
- **Command Center:** Sadece `canViewAllCalls` rolleri (yönetici, operasyon) içeri girebiliyor. Diğer roller `UnauthorizedScreen` görüyor.
- **Dashboard:** "Çağrı Merkezi" butonu sadece `canViewAllCalls(role)` true ise gösteriliyor (danışman/demo görmez).
- **UnauthorizedScreen:** Yetkisiz erişimde kullanıcı dostu mesaj + "Ana Sayfaya Dön" butonu.

### Hata ve Kullanıcı Deneyimi
- **Router:** `debugLogDiagnostics` sadece debug modda. Hata ekranında teknik metin yerine kullanıcı dostu mesaj (permission-denied, network, not-found ayrıştırılıyor).
- **Command Center:** Hata durumunda "Tekrar dene" butonu ile StreamBuilder yeniden çalışıyor.
- **CustomerCard:** `fullName` null/boş iken avatar harfi için güvenli `_avatarLetter()` kullanılıyor; çökme riski kaldırıldı.

### Test İskeletleri
- **test/features/auth/permission_test.dart:** `canViewAllCalls`, `canManageSettings`, `canViewCallCenter`, `AppRole.fromId` birim testleri.
- **test/shared/unauthorized_screen_test.dart:** UnauthorizedScreen widget testi.
- **test/widget_test.dart:** Uygulama smoke testi (ProviderScope + EmlakMasterApp).

---

## Mevcut Rol Davranışı

| Rol | Çağrı Merkezi butonu | Command Center erişim |
|-----|----------------------|------------------------|
| agent (mevcut demo) | Görünmez | Yetkisiz ekran |
| officeManager, teamLead, operations, admin tier | Görünür | Tam erişim |
| guest, investorPortal | Görünmez | Yetkisiz ekran |

Gerçek auth sonrası `currentRoleProvider` Firestore `users/{uid}.role` ile beslenmeli.

---

## Kalan Riskler

1. **Auth:** Gerçek login yok; rol sabit (agent). Yayında Firebase Auth + users dokümanından rol okunmalı.
2. **Firestore Rules:** `users/{uid}` içinde `role` alanı yoksa yönetici sayfaları açılmaz; ilk kurulumda admin kullanıcıya `role: 'office_manager'` vb. yazılmalı.
3. **Tasks / Pipeline / Investor:** Bu modüller henüz tam bağlı değil; senaryo F, I, J kısmen placeholder.
4. **Widget smoke test:** Tam uygulama testi Firebase init gerektirir; CI’da mock veya test env gerekebilir.

---

## Release Öncesi Kontrol Listesi

- [x] Yetkisiz roller Command Center’a giremiyor
- [x] Dashboard’da rol bazlı buton gizleme
- [x] Hata ekranlarında teknik stack trace yok
- [x] Router debug log sadece debug modda
- [x] Null/boş müşteri adı güvenli
- [x] Permission + UnauthorizedScreen testleri
- [ ] Gerçek auth ve rol atama (ürün kararı)
- [ ] CI’da testlerin çalıştırılması (flutter test)
