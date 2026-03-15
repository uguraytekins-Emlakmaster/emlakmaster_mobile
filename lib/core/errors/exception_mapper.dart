import 'package:firebase_auth/firebase_auth.dart';

import '../errors/app_exception.dart';

/// Teknik hataları kullanıcı dostu mesajlara çevirir. Log'da ham mesaj, UI'da bu çıktı kullanılır.
abstract final class ExceptionMapper {
  /// [e] herhangi bir Exception veya AppException olabilir.
  /// Dönen metin kullanıcıya gösterilebilir (ham teknik metin değil).
  static String toUserMessage(Object e) {
    if (e is AppException) {
      return _appExceptionToMessage(e);
    }
    if (e is FirebaseAuthException) {
      return _firebaseAuthToMessage(e);
    }
    if (e is FirebaseException) {
      return 'Veritabanı işlemi geçici olarak başarısız. Lütfen tekrar deneyin.';
    }
    return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
  }

  static String _appExceptionToMessage(AppException e) {
    switch (e.code) {
      case 'NETWORK_ERROR':
        return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
      case 'AUTH_ERROR':
        return e.message ?? 'Giriş işlemi başarısız. Bilgilerinizi kontrol edin.';
      case 'DATA_ERROR':
        return e.message ?? 'Veri işlenirken bir hata oluştu. Lütfen tekrar deneyin.';
      case 'PERMISSION_ERROR':
        return 'Bu işlem için yetkiniz bulunmuyor.';
      case 'VALIDATION_ERROR':
        return e.message ?? 'Girdiğiniz bilgileri kontrol edin.';
      case 'TIMEOUT':
        return 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';
      default:
        return e.message ?? 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  static String _firebaseAuthToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'invalid-email':
        return 'Geçerli bir e-posta adresi girin.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakıldı.';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen daha sonra tekrar deneyin.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      default:
        return 'Giriş yapılamadı. Lütfen tekrar deneyin.';
    }
  }
}
