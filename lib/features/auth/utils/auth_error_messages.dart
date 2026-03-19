import 'package:firebase_auth/firebase_auth.dart';

/// Giriş/kayıt hatalarını kullanıcı dostu Türkçe mesaja çevirir. Test edilebilir.
String userFriendlyAuthError(dynamic e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı. Şifrede başta/sonda boşluk yoksa Firebase Console\'da bu e-postanın kayıtlı olduğundan emin olun.';
      case 'invalid-email':
        return 'Geçerli bir e-posta adresi girin.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakıldı. Yöneticinizle iletişime geçin.';
      case 'too-many-requests':
        return 'Çok fazla deneme. Biraz bekleyip tekrar deneyin.';
      case 'network-request-failed':
        return 'İnternet bağlantısı yok. Bağlantınızı kontrol edin.';
      case 'operation-not-allowed':
        return 'Firebase Console\'da E-posta/Şifre girişi kapalı. Authentication → Sign-in method → E-posta/Şifre\'yi açıp kaydedin.';
      case 'invalid-api-key':
      case 'app-not-authorized':
        return 'Firebase yapılandırması hatalı. Proje ayarlarını kontrol edin.';
      default:
        return 'Giriş yapılamadı (${e.code}). Bilgiler doğruysa Firebase Console → Authentication → E-posta/Şifre açık mı kontrol edin.';
    }
  }
  final s = e.toString().toLowerCase();
  if (s.contains('user-not-found') || s.contains('wrong-password') || s.contains('invalid-credential')) {
    return 'E-posta veya şifre hatalı. Şifrede başta/sonda boşluk yoksa Firebase\'de bu e-postanın kayıtlı olduğundan emin olun.';
  }
  if (s.contains('invalid-email')) return 'Geçersiz e-posta adresi.';
  if (s.contains('too-many-requests')) return 'Çok fazla deneme. Biraz bekleyip tekrar deneyin.';
  if (s.contains('network')) return 'İnternet bağlantısı yok.';
  return 'Giriş yapılamadı. E-posta/şifre doğruysa Firebase Console → Authentication → E-posta/Şifre etkin mi kontrol edin.';
}
