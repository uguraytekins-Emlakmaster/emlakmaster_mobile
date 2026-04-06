import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Senkronizasyon yöneticisi: çevrimdışı/çevrimiçi durumu takip eder.
/// Firestore offline persistence ile veri cihazda kalır; internet gelince senkronize edilir.
class SyncManager {
  SyncManager._();

  static final SyncManager _instance = SyncManager._();
  static SyncManager get instance => _instance;

  static Stream<List<ConnectivityResult>> get _connectivityStream =>
      Connectivity().onConnectivityChanged;

  /// Ağ dalgalanmasında tekrarlayan flush/sync işlerini seyreltir.
  static const Duration debounceDuration = Duration(milliseconds: 350);

  /// true = en az bir bağlantı türü (wifi, mobile, ethernet) var.
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  static Stream<bool> get _rawOnlineMapped {
    return _connectivityStream.map((results) {
      return results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);
    }).distinct();
  }

  /// Anlık çevrimiçi değişimleri (UI banner vb.).
  static Stream<bool> get onlineStream => _rawOnlineMapped;

  static StreamController<bool>? _debouncedCtrl;
  static Timer? _debounceTimer;

  /// Debounce'lu çevrimiçi (handoff flush, ağır senkron tetikleri için).
  static Stream<bool> get onlineStreamDebounced {
    _ensureDebouncedPipeline();
    return _debouncedCtrl!.stream;
  }

  static void _ensureDebouncedPipeline() {
    if (_debouncedCtrl != null) return;
    _debouncedCtrl = StreamController<bool>.broadcast();
    _rawOnlineMapped.listen(
      (online) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(debounceDuration, () {
          if (!(_debouncedCtrl?.isClosed ?? true)) {
            _debouncedCtrl!.add(online);
          }
        });
      },
      onError: (Object e, StackTrace st) {
        if (kDebugMode) debugPrint('SyncManager debounced source: $e');
      },
    );
  }

  static void init() {
    Connectivity().checkConnectivity().then((results) {
      _instance._isOnline = results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);
      if (kDebugMode) {
        debugPrint('SyncManager: isOnline=${_instance._isOnline}');
      }
    });
    _rawOnlineMapped.listen((online) {
      _instance._isOnline = online;
      if (kDebugMode) debugPrint('SyncManager: isOnline=$online');
    });
  }
}
