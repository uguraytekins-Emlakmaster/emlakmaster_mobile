import 'package:equatable/equatable.dart';

import '../errors/app_exception.dart';

/// Başarı veya hata taşıyan tip; UI ve repository katmanında kullanılır.
sealed class Result<T> with EquatableMixin {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
  @override
  List<Object?> get props => [data];
}

final class Failure<T> extends Result<T> {
  const Failure(this.exception);
  final AppException exception;
  @override
  List<Object?> get props => [exception];
}

extension ResultX<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
  T? get dataOrNull => switch (this) {
        Success(:final data) => data,
        Failure() => null,
      };
  AppException? get exceptionOrNull => switch (this) {
        Success() => null,
        Failure(:final exception) => exception,
      };
}
