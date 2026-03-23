import '../../auth/data/user_repository.dart';
import '../domain/membership_status.dart';
import '../domain/office_membership_entity.dart';

/// Ofis işaretçisi ↔ üyelik tutarlılığı (istemci tarafı; kurallar + backend ile güçlendirilir).
abstract final class OfficeIntegrityService {
  /// `users.officeId` ile birincil üyelik aynı ofisi göstermeli.
  static bool pointerMatchesMembership(UserDoc userDoc, OfficeMembership? m) {
    final oid = userDoc.officeId;
    if (oid == null || oid.isEmpty) return m == null;
    if (m == null) return false;
    return m.officeId == oid && m.userId == userDoc.uid;
  }

  /// Üyelik varsa ve kullanıcı ofis işaretçisi yoksa veya farklıysa tutarsız.
  static bool isCorruptedState(UserDoc userDoc, OfficeMembership? primaryForPointer) {
    final oid = userDoc.officeId;
    if (oid == null || oid.isEmpty) return false;
    if (primaryForPointer == null) return true;
    return !pointerMatchesMembership(userDoc, primaryForPointer);
  }

  /// Normal uygulama için üyelik aktif mi?
  static bool hasOperationalMembership(OfficeMembership? m) {
    return m != null && m.status == MembershipStatus.active;
  }
}
