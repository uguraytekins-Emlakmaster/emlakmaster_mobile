import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Giriş/kayıt hatalarını kullanıcı dostu yerelleştirilmiş mesaja çevirir.
String userFriendlyAuthError(AppLocalizations l10n, dynamic e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.t('auth_err_invalid_credentials');
      case 'invalid-email':
        return l10n.t('auth_reset_invalid_email');
      case 'user-disabled':
        return l10n.t('auth_err_user_disabled');
      case 'too-many-requests':
        return l10n.t('auth_too_many_requests');
      case 'network-request-failed':
        return l10n.t('auth_err_no_network');
      case 'operation-not-allowed':
        return l10n.t('auth_err_email_signin_disabled');
      case 'invalid-api-key':
      case 'app-not-authorized':
        return l10n.t('auth_err_config');
      default:
        return l10n.tArgs('auth_err_login_failed_code', [e.code]);
    }
  }
  final s = e.toString().toLowerCase();
  if (s.contains('user-not-found') ||
      s.contains('wrong-password') ||
      s.contains('invalid-credential')) {
    return l10n.t('auth_err_invalid_credentials');
  }
  if (s.contains('invalid-email')) return l10n.t('auth_reset_invalid_email2');
  if (s.contains('too-many-requests')) return l10n.t('auth_too_many_requests');
  if (s.contains('network')) return l10n.t('auth_err_no_network_short');
  return l10n.t('auth_err_login_failed_generic');
}
