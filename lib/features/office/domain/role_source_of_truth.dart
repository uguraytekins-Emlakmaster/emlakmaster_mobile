library role_source_of_truth;

/// ## Rol kaynağı politikası (Phase 1.3)
///
/// **Ofis bağlamı varken** (`users.officeId` dolu ve geçerli aktif üyelik):
/// - Yetki ve rol gösterimi için **tek doğruluk kaynağı**: `office_memberships.role` → [OfficeRole.toAppRole].
///
/// **`users.role`** alanı:
/// - Ofis öncesi / geçiş dönemi için **yedek** (legacy) okuma.
/// - Ofis + **aktif** üyelik varken istemci bu alanı **yetkilendirme için kullanmamalı**;
///   yine de sunucu tarafı senkron / raporlama için güncellenebilir (ör. davet kabulünde).
///
/// **Çoklu ofis** (ileride): `officeId` ve üyelik seçimi genişletildiğinde bu dosya güncellenmelidir.

abstract final class RoleSourceOfTruthPolicy {
  static const String docMarkdown = '''
| Durum | Yetki kaynağı |
|-------|----------------|
| officeId boş | users.role (legacy) |
| officeId + aktif üyelik | office_memberships.role |
| officeId ama üyelik yok/uyumsuz | Erişim kapalı — recovery |
''';
}
