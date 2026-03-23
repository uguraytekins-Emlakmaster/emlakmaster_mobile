/// Ofis / davet / üyelik işlemleri için yapılandırılmış hata.
class OfficeException implements Exception {
  OfficeException(this.code, this.userMessage, [this.cause]);

  final OfficeErrorCode code;
  final String userMessage;
  final Object? cause;

  @override
  String toString() => 'OfficeException($code): $userMessage';
}

enum OfficeErrorCode {
  invalidInviteCode,
  inviteExpired,
  inviteExhausted,
  inviteInactive,
  alreadyMember,
  permissionDenied,
  network,
  unknown,

  /// Davet rolü atanamaz (hiyerarşi)
  roleNotAllowed,

  /// Üyelik dokümanı yok / tutarsız
  membershipMissing,

  /// officeId / üyelik uyuşmazlığı
  officeStateCorrupted,

  /// Office veya üyelik bulunamadı
  officeNotFound,

  /// Hesap askıda
  membershipSuspended,

  /// Üyelik kaldırılmış
  membershipRemoved,
}
