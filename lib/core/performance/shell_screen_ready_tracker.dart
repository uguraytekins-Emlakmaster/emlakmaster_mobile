import 'package:emlakmaster_mobile/core/performance/shell_screen_timing.dart';
import 'package:flutter/material.dart';
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

/// Alt ağaç sarmalayıcı — shell sekmelerinde tek satır analytics bağlantısı.
class ShellScreenReadyListener extends ConsumerStatefulWidget {
  const ShellScreenReadyListener({
    super.key,
    required this.screenName,
    required this.provider,
    required this.child,
    this.itemCount,
  });

  final String screenName;
  final ProviderListenable<AsyncValue<dynamic>> provider;
  final int? Function(dynamic value)? itemCount;
  final Widget child;

  @override
  ConsumerState<ShellScreenReadyListener> createState() =>
      _ShellScreenReadyListenerState();
}

class _ShellScreenReadyListenerState
    extends ConsumerState<ShellScreenReadyListener> {
  late final ShellScreenReadyTracker _tracker;
  ProviderSubscription<AsyncValue<dynamic>>? _providerSub;

  @override
  void initState() {
    super.initState();
    _tracker = ShellScreenReadyTracker(widget.screenName);
    _providerSub = ref.listenManual(widget.provider, (previous, next) {
      if (!next.hasValue) return;
      _tracker.onContentReady(
        itemCount: widget.itemCount?.call(next.requireValue),
      );
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _providerSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
