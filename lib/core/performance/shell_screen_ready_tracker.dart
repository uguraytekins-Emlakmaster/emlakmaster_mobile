import 'package:emlakmaster_mobile/core/performance/shell_screen_timing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shell / ağır ekran — ilk içerik hazır olduğunda tek seferlik analytics.
class ShellScreenReadyTracker {
  ShellScreenReadyTracker(this.screenName);

  final String screenName;
  final Stopwatch _stopwatch = Stopwatch()..start();
  bool _logged = false;

  void onContentReady({int? itemCount}) {
    if (_logged) return;
    _logged = true;
    logShellScreenReady(
      screenName: screenName,
      elapsedMs: _stopwatch.elapsedMilliseconds,
      itemCount: itemCount,
    );
  }
}

/// [initState] içinde çağırın; [provider] ilk `hasValue` olduğunda loglar.
void listenShellScreenReady<T>({
  required WidgetRef ref,
  required ShellScreenReadyTracker tracker,
  required ProviderListenable<AsyncValue<T>> provider,
  int? Function(T value)? itemCount,
}) {
  ref.listenManual(provider, (previous, next) {
    if (!next.hasValue) return;
    tracker.onContentReady(
      itemCount: itemCount?.call(next.requireValue),
    );
  }, fireImmediately: true);
}
