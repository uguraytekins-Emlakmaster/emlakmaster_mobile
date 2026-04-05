import 'dart:developer' as developer;

import 'package:cloud_functions/cloud_functions.dart';
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

void _logGenericError(String context, Object error) {
  developer.log(
    error.toString(),
    name: 'AppError:$context',
    error: error is Exception ? error : Exception(error.toString()),
    stackTrace: StackTrace.current,
  );
}

/// Tüm yakalanan hatalar için tek giriş: Firebase / Functions / diğer.
String userFacingErrorMessage(Object error, {String context = 'generic'}) {
  if (error is FirebaseException) {
    return userFacingFirebaseMessage(error);
  }
  if (error is StateError) {
    _logGenericError(context, error);
    final m = error.message;
    if (m.isNotEmpty) return m;
    return 'İşlem tamamlanamadı. Lütfen tekrar deneyin.';
  }
  if (error is FirebaseFunctionsException) {
    _logGenericError(context, error);
    final c = error.code;
    if (c == 'permission-denied' || c == 'unauthenticated') {
      return 'Bu işlem için yetkiniz bulunmuyor veya oturum süreniz dolmuş olabilir.';
    }
    if (c == 'unavailable' || c == 'deadline-exceeded' || c == 'resource-exhausted') {
      return 'Sunucu şu anda yanıt vermiyor. Lütfen biraz sonra tekrar deneyin.';
    }
    return 'İşlem tamamlanamadı. Lütfen tekrar deneyin.';
  }
  _logGenericError(context, error);
  return 'İşlem tamamlanamadı. Lütfen tekrar deneyin.';
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
