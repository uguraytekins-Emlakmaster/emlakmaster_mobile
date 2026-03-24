import 'package:emlakmaster_mobile/core/config/dev_mode_config.dart';
import 'package:emlakmaster_mobile/features/office/domain/membership_status.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_membership_entity.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_role.dart';

/// Firestore ofis oluşturma başarısız olduğunda (ör. ağ / kurallar) uygulamanın
/// ana ekrana geçmesini sağlayan yerel oturum bayrağı.
///
/// [activate] sonrası [primaryMembershipProvider] vb. yeniden abone edilmelidir (`ref.invalidate`).
final class DevOfficeFallback {
  DevOfficeFallback._();

  static bool _active = false;
  static String _officeName = 'Rainbow';
  static bool _usedFallbackOnLastCreate = false;

  static bool get isActive => isDevMode && _active;

  static String get officeName => _officeName;

  /// Son [OfficeSetupService.createOfficeAsOwner] çağrısı yerel moda düştü mü?
  static bool get usedFallbackOnLastCreate => _usedFallbackOnLastCreate;

  static void resetLastCreateFlag() {
    _usedFallbackOnLastCreate = false;
  }

  static void markUsedFallback() {
    _usedFallbackOnLastCreate = true;
  }

  /// Yerel mod: sentetik owner üyeliği (Firestore yok).
  static OfficeMembership syntheticMembership(String uid) {
    return OfficeMembership(
      id: OfficeMembership.compositeId(uid, kLocalDevOfficeId),
      officeId: kLocalDevOfficeId,
      userId: uid,
      role: OfficeRole.owner,
      status: MembershipStatus.active,
    );
  }

  static void activate({required String officeName}) {
    if (!isDevMode) return;
    _active = true;
    _officeName = officeName.trim().isNotEmpty ? officeName.trim() : 'Rainbow';
  }

  /// Test / çıkış sonrası temizlik için.
  static void deactivate() {
    _active = false;
    _officeName = 'Rainbow';
  }
}
