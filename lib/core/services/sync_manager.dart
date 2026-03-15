import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Senkronizasyon yöneticisi: çevrimdışı/çevrimiçi durumu takip eder.
/// Firestore zaten offline persistence ile veriyi cihazda tutar; internet gelince otomatik senkronize eder.
/// Bu sınıf UI için "çevrimdışı" banner veya "senkronize ediliyor" göstergesi sağlar.
class SyncManager {
  SyncManager._();

  static final SyncManager _instance = SyncManager._();
  static SyncManager get instance => _instance;

  static Stream<List<ConnectivityResult>> get _connectivityStream =>
      Connectivity().onConnectivityChanged;

  /// true = en az bir bağlantı türü (wifi, mobile, ethernet) var.
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Çevrimdışıyken veri girişi yapıldığında internet gelince Firestore otomatik senkronize eder.
  /// Bu stream dinlenerek "Çevrimdışı - veriler kaydedildi, bağlantı gelince senkronize edilecek" gibi UI gösterilebilir.
  static Stream<bool> get onlineStream {
    return _connectivityStream.map((results) {
      return results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);
    }).distinct();
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
    onlineStream.listen((online) {
      _instance._isOnline = online;
      if (kDebugMode) debugPrint('SyncManager: isOnline=$online');
    });
  }
}
