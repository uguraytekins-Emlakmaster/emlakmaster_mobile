import 'dart:convert';

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kayıtsız numara uyarıları için snöz/yoksay deposu.
///
/// - "Daha sonra" → 4 saat snöz
/// - "Yoksay" → 30 gün bastırma
/// Kalıcı (SharedPreferences); süre dolunca otomatik temizlenir.
class AxionCaptureDismissStore {
  AxionCaptureDismissStore._();
  static final AxionCaptureDismissStore instance = AxionCaptureDismissStore._();

  static const String _prefsKey = 'axion_capture_dismissed_v1';
  static const Duration snoozeDuration = Duration(hours: 4);
  static const Duration dismissDuration = Duration(days: 30);

  Map<String, int>? _cache;

  Future<Map<String, int>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) {
        _cache = {};
        return _cache!;
      }
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _cache = {
        for (final e in decoded.entries)
          if (e.value is int) e.key: e.value as int,
      };
    } catch (e, st) {
      AppLogger.e('AxionCaptureDismissStore load', e, st);
      _cache = {};
    }
    return _cache!;
  }

  Future<void> _persist() async {
    final map = _cache;
    if (map == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(map));
    } catch (e, st) {
      AppLogger.e('AxionCaptureDismissStore persist', e, st);
    }
  }

  /// Bu numara şu anda bastırılmış mı?
  Future<bool> isSuppressed(String normalizedKey, {DateTime? now}) async {
    final map = await _load();
    final until = map[normalizedKey];
    if (until == null) return false;
    final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
    if (at >= until) {
      map.remove(normalizedKey);
      await _persist();
      return false;
    }
    return true;
  }

  Future<void> snooze(String normalizedKey, {DateTime? now}) =>
      _suppress(normalizedKey, snoozeDuration, now: now);

  Future<void> dismiss(String normalizedKey, {DateTime? now}) =>
      _suppress(normalizedKey, dismissDuration, now: now);

  /// Kayıt tamamlandı — bastırma kaydı artık gereksiz.
  Future<void> clear(String normalizedKey) async {
    final map = await _load();
    if (map.remove(normalizedKey) != null) await _persist();
  }

  Future<void> _suppress(
    String normalizedKey,
    Duration duration, {
    DateTime? now,
  }) async {
    final map = await _load();
    // Süresi geçmiş eski kayıtları da fırsattan temizle (sınırsız büyüme yok).
    final at = (now ?? DateTime.now());
    final atMs = at.millisecondsSinceEpoch;
    map.removeWhere((_, until) => atMs >= until);
    map[normalizedKey] = at.add(duration).millisecondsSinceEpoch;
    await _persist();
  }
}
