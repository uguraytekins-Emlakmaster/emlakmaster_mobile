import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';

/// Debug: adlandırılmış provider güncellemeleri + yaşam döngüsü + tüm provider hataları.
///
/// Release build'de kullanılmaz ([ProviderScope] içinde yalnızca `kDebugMode` iken eklenir).
final class DebugRiverpodObserver extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    AppLogger.state('[+] ${provider.name ?? provider.runtimeType}');
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    final name = provider.name;
    if (name != null && name.isNotEmpty) {
      AppLogger.state('[←] $name');
    }
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    AppLogger.state('[×] ${provider.name ?? provider.runtimeType}');
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    AppLogger.e(
      '[provider] ${provider.name ?? provider.runtimeType}',
      error,
      stackTrace,
    );
  }
}
