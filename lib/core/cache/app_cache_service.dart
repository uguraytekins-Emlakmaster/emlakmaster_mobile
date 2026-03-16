import 'dart:convert';

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hafif yerel önbellek — UI thread'i bloke etmemek için ilk kullanımda init (No-Lag Rule).
/// Hive: hızlı NoSQL, liste/listing önizleme verisi vb. için kullanılabilir.
class AppCacheService {
  AppCacheService._();
  static final AppCacheService instance = AppCacheService._();

  static const String _boxName = 'emlakmaster_cache';
  Box<String>? _box;
  bool _initDone = false;

  Future<void> ensureInit() async {
    if (_initDone) return;
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox<String>(_boxName);
      _initDone = true;
    } catch (e, st) {
      AppLogger.e('AppCacheService init', e, st);
    }
  }

  Box<String>? get _b => _box;

  /// TTL yok; sadece key-value. Süresi dolan veri için key'i silip yeniden yaz.
  Future<void> put(String key, String value) async {
    await ensureInit();
    await _b?.put(key, value);
  }

  String? get(String key) {
    return _b?.get(key);
  }

  Future<void> putJson(String key, Object value) async {
    await put(key, jsonEncode(value));
  }

  T? getJson<T>(String key, T Function(Object? json) fromJson) {
    final raw = get(key);
    if (raw == null) return null;
    try {
      return fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) async {
    await ensureInit();
    await _b?.delete(key);
  }

  Future<void> clear() async {
    await ensureInit();
    await _b?.clear();
  }
}
