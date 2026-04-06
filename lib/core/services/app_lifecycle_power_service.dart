import 'dart:async';

import 'package:flutter/widgets.dart';

import 'auth_session_coordinator.dart';

/// Uygulama yaşam döngüsü + batarya dostu davranış.
/// Arka plana geçince animasyonlar durur, gereksiz iş azalır; şarj minimum kullanılır.
class AppLifecyclePowerService with WidgetsBindingObserver {
  AppLifecyclePowerService._();

  static final AppLifecyclePowerService instance = AppLifecyclePowerService._();

  /// Ön plana dönüldüğünde (senkron / bağlantı yenileme için sessiz dinleyiciler).
  static final StreamController<void> _resumedCtrl =
      StreamController<void>.broadcast();

  static Stream<void> get onAppResumed => _resumedCtrl.stream;

  /// Arka planda mı (paused / inactive / detached). Dinleyen widget'lar animasyonu durdurabilir.
  static final ValueNotifier<bool> isInBackground = ValueNotifier<bool>(false);

  /// Kullanıcı "Batarya tasarrufu" açtıysa: animasyonları azalt, ağ isteklerini hafiflet.
  static bool powerSaverEnabled = false;

  bool _observed = false;

  void ensureObserved() {
    if (_observed) return;
    _observed = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void removeObserved() {
    if (!_observed) return;
    _observed = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        isInBackground.value = false;
        AuthSessionCoordinator.refreshOnAppResume();
        if (!_resumedCtrl.isClosed) {
          _resumedCtrl.add(null);
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        isInBackground.value = true;
        break;
    }
  }

  /// Arka plandayken veya batarya tasarrufu açıkken "ağır" animasyon yapma.
  static bool get shouldReduceMotion =>
      isInBackground.value || powerSaverEnabled;
}
