import '../../domain/auth_failure_kind.dart';
import '../../domain/auth_result.dart';

extension AuthResultLoginUi on AuthResult {
  /// Banner / hata kutusu metni; başarı ve iptal için null.
  String? get loginBannerMessage {
    switch (this) {
      case AuthSuccess():
      case AuthCancelled():
        return null;
      case AuthRequiresAction(:final message):
        return message;
      case AuthFailure(:final kind, :final userMessage):
        if (kind == AuthFailureKind.userCancelled) return null;
        if (userMessage.isEmpty) return null;
        return userMessage;
    }
  }

  /// [LoginAttemptGuard] için gerçek başarısızlık sayılsın mı (iptal sayılmaz).
  bool get shouldRecordLoginFailure {
    switch (this) {
      case AuthSuccess():
      case AuthCancelled():
        return false;
      case AuthFailure(:final kind):
        return kind != AuthFailureKind.userCancelled;
      case AuthRequiresAction():
        return true;
    }
  }
}
