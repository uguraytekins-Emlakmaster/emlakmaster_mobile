import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_failure_kind.dart';

/// Tüm giriş yolları için ortak sonuç modeli.
sealed class AuthResult extends Equatable {
  const AuthResult();

  @override
  List<Object?> get props => [];
}

/// Başarılı oturum açma — yönlendirme `GoRouter` + `userDocStreamProvider` ile yapılır.
class AuthSuccess extends AuthResult {
  const AuthSuccess(this.credential);

  final UserCredential credential;

  @override
  List<Object?> get props => [credential.user?.uid];
}

/// Kullanıcı akışı iptal etti (Google hesap seçici / Apple iptal).
class AuthCancelled extends AuthResult {
  const AuthCancelled();
}

/// Hesap birleştirme vb. (ileride genişletilir).
class AuthRequiresAction extends AuthResult {
  const AuthRequiresAction({this.message});

  final String? message;

  @override
  List<Object?> get props => [message];
}

/// Başarısız giriş — [kind] ile sınıflandırılmış.
class AuthFailure extends AuthResult {
  const AuthFailure({
    required this.kind,
    required this.userMessage,
    this.debugDetail,
    this.cause,
  });

  final AuthFailureKind kind;
  final String userMessage;
  final String? debugDetail;
  final Object? cause;

  bool get isCancellation => kind == AuthFailureKind.userCancelled;

  @override
  List<Object?> get props => [kind, userMessage, debugDetail];
}
