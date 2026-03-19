import 'package:firebase_auth/firebase_auth.dart';

/// Kullanıcı Facebook girişini iptal ettiğinde fırlatılır.
class FacebookSignInUserCanceled implements Exception {
  @override
  String toString() => 'FacebookSignInUserCanceled';
}

/// Facebook ile giriş (şu an devre dışı).
///
/// [AppConstants.showFacebookLogin] false iken UI gösterilmez; native FBSDK da projede
/// yoktur — böylece sahte `FacebookClientToken` ile iOS açılış çökmesi önlenir.
class FacebookAuthService {
  FacebookAuthService._();
  static final FacebookAuthService instance = FacebookAuthService._();

  Future<UserCredential> signInWithFacebookForFirebase() async {
    throw FirebaseAuthException(
      code: 'operation-not-allowed',
      message:
          'Facebook ile giriş bu sürümde kapalıdır. E-posta veya Google ile devam edin.',
    );
  }

  Future<void> signOut() async {
    // Native Facebook SDK yok; ek işlem gerekmez.
  }
}
