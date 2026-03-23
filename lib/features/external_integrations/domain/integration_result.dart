import 'integration_error_code.dart';

/// Tüm adapter metotları bunu döner; unsupported asla throw değil.
sealed class IntegrationResult<T> {
  const IntegrationResult._();

  R when<R>({
    required R Function(T value) success,
    required R Function(String operation) unsupported,
    required R Function(IntegrationErrorCode code, String? message) failure,
  }) {
    final self = this;
    return switch (self) {
      IntegrationSuccess<T>(:final value) => success(value),
      IntegrationUnsupported<T>(:final operation) => unsupported(operation),
      IntegrationFailure<T>(:final code, :final message) => failure(code, message),
    };
  }

  bool get isSuccess => this is IntegrationSuccess<T>;
  T? get valueOrNull => switch (this) {
        IntegrationSuccess<T>(:final value) => value,
        _ => null,
      };
}

final class IntegrationSuccess<T> extends IntegrationResult<T> {
  const IntegrationSuccess(this.value) : super._();
  final T value;
}

final class IntegrationUnsupported<T> extends IntegrationResult<T> {
  const IntegrationUnsupported(this.operation) : super._();
  final String operation;
}

final class IntegrationFailure<T> extends IntegrationResult<T> {
  const IntegrationFailure(this.code, [this.message]) : super._();
  final IntegrationErrorCode code;
  final String? message;
}
