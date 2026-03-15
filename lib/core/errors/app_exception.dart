import 'package:equatable/equatable.dart';

/// Uygulama genelinde kullanılan tip güvenli hata sınıfları.
/// Ham teknik mesaj kullanıcıya gösterilmez; ExceptionMapper ile kullanıcı mesajına çevrilir.
base class AppException with EquatableMixin implements Exception {
  const AppException({
    required this.code,
    this.message,
    this.cause,
  });

  final String code;
  final String? message;
  final Object? cause;

  @override
  List<Object?> get props => [code, message, cause];

  @override
  String toString() => 'AppException($code: $message)';
}

/// Ağ / bağlantı hataları
final class NetworkException extends AppException {
  const NetworkException({super.message, super.cause})
      : super(code: 'NETWORK_ERROR');
}

/// Firebase / Auth hataları
final class AuthException extends AppException {
  const AuthException({super.message, super.cause})
      : super(code: 'AUTH_ERROR');
}

/// Firestore / veri hataları
final class DataException extends AppException {
  const DataException({super.message, super.cause})
      : super(code: 'DATA_ERROR');
}

/// Yetki / izin hataları
final class PermissionException extends AppException {
  const PermissionException({super.message, super.cause})
      : super(code: 'PERMISSION_ERROR');
}

/// Validasyon hataları
final class ValidationException extends AppException {
  const ValidationException({super.message, super.cause})
      : super(code: 'VALIDATION_ERROR');
}

/// Zaman aşımı
final class TimeoutException extends AppException {
  const TimeoutException({super.message, super.cause})
      : super(code: 'TIMEOUT');
}

/// Bilinmeyen / beklenmeyen hata
final class UnknownException extends AppException {
  const UnknownException({super.message, super.cause})
      : super(code: 'UNKNOWN');
}
