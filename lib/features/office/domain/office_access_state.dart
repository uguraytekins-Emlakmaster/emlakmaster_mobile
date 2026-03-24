import 'package:emlakmaster_mobile/core/config/dev_mode_config.dart';

import '../../auth/data/user_repository.dart';
import 'membership_status.dart';
import 'office_membership_entity.dart';

/// Oturum + `users` + birincil üyelikten türetilen ofis erişim durumu (yönlendirme tek kaynak).
enum OfficeAccessState {
  /// `officeId` yok — ofis kapısı
  noOfficeContext,

  /// Firestore kullanıcı doc veya üyelik yükleniyor
  loading,

  /// `officeId` var, üyelik dokümanı yok / tutarsız
  membershipMissing,

  /// `users.officeId` ile üyelik `officeId` eşleşmiyor
  inconsistentPointer,

  /// Davet kabulü bekleniyor (tam erişim yok)
  invitedOnly,

  /// Askıda — operasyon engelli
  suspended,

  /// Üyelik kaldırılmış
  removed,

  /// Aktif üyelik — ana uygulama
  officeReady,
}

/// [UserDoc] + birincil [OfficeMembership] ile durum (üyelik yoksa null).
OfficeAccessState deriveOfficeAccessState({
  required UserDoc? userDoc,
  required OfficeMembership? primaryMembership,
  required bool userDocLoading,
  required bool membershipLoading,
  bool devOfficeFallback = false,
}) {
  if (userDocLoading || (userDoc != null &&
      (devOfficeFallback ||
          (userDoc.officeId != null && userDoc.officeId!.isNotEmpty)) &&
      membershipLoading)) {
    return OfficeAccessState.loading;
  }
  if (userDoc == null) return OfficeAccessState.loading;

  /// Geliştirme: Firestore yazılamadı; sentetik üyelik ile ana uygulamaya izin ver.
  if (isDevMode &&
      devOfficeFallback &&
      primaryMembership != null &&
      primaryMembership.officeId == kLocalDevOfficeId) {
    return OfficeAccessState.officeReady;
  }

  final oid = userDoc.officeId;
  if (oid == null || oid.isEmpty) return OfficeAccessState.noOfficeContext;

  if (primaryMembership == null) {
    return OfficeAccessState.membershipMissing;
  }
  if (primaryMembership.officeId != oid) {
    return OfficeAccessState.inconsistentPointer;
  }
  switch (primaryMembership.status) {
    case MembershipStatus.active:
      return OfficeAccessState.officeReady;
    case MembershipStatus.invited:
      return OfficeAccessState.invitedOnly;
    case MembershipStatus.suspended:
      return OfficeAccessState.suspended;
    case MembershipStatus.removed:
      return OfficeAccessState.removed;
  }
}
