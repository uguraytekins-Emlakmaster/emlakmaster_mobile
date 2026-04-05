import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';

/// Teknik [FirebaseException] içeriğini loglar; UI’da yalnızca dönen metni kullanın.
void logFirebaseException(String context, FirebaseException e) {
  developer.log(
    '${e.code}: ${e.message}',
    name: 'Firebase:$context',
    error: e,
    stackTrace: StackTrace.current,
  );
}

/// Ham İngilizce backend mesajlarını kullanıcıya göstermeyin; bu eşlemeyi kullanın.
String userFacingFirebaseMessage(FirebaseException e) {
  logFirebaseException('userFacing', e);
  switch (e.code) {
    case 'permission-denied':
      return 'Bu işlem için yetkiniz bulunmuyor.';
    case 'unauthenticated':
      return 'Oturum süreniz dolmuş olabilir. Lütfen tekrar giriş yapın.';
    case 'unavailable':
    case 'deadline-exceeded':
    case 'resource-exhausted':
      return 'Sunucu şu anda yanıt vermiyor. Lütfen biraz sonra tekrar deneyin.';
    case 'failed-precondition':
      return 'Sunucu yetki doğrulaması başarısız oldu. Lütfen tekrar deneyin veya yönetici yetkisini kontrol edin.';
    case 'aborted':
    case 'cancelled':
      return 'İşlem iptal edildi veya yarıda kaldı. Lütfen tekrar deneyin.';
    default:
      return 'Kurulum kaydı şu anda tamamlanamadı. Lütfen tekrar deneyin.';
  }
}
