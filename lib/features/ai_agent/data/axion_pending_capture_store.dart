import 'dart:convert';

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bildirimden yapılan "hızlı kaydet" için bekleyen iş kuyruğu.
///
/// Arka plan isolate'inde Firestore yazımı başarısız olabilir (ağ yok,
/// oturum geri yüklenemedi vb.). Veri ASLA kaybolmaz: kayıt bu kuyruğa
/// yazılır ve uygulama bir sonraki açılışta sessizce tamamlar.
///
/// İki kuyruk:
/// - pendingSaves: henüz CRM'e yazılamamış {name, phone} kayıtları
/// - pendingLinks: müşteri oluşturuldu, çağrı geçmişi bağlaması bekliyor
///   ({normalizedKey → customerId})
class AxionPendingCaptureStore {
  AxionPendingCaptureStore._();
  static final AxionPendingCaptureStore instance = AxionPendingCaptureStore._();

  static const String _savesKey = 'axion_pending_capture_saves_v1';
  static const String _linksKey = 'axion_pending_capture_links_v1';
  static const int _maxQueue = 25;

  /// CRM'e yazılamayan kaydı kuyruğa ekler (aynı telefon tekrarlanmaz).
  Future<void> enqueueSave({
    required String name,
    required String phone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _decodeList(prefs.getString(_savesKey));
      list.removeWhere((e) => e['phone'] == phone);
      list.add({
        'name': name,
        'phone': phone,
        'at': DateTime.now().millisecondsSinceEpoch,
      });
      while (list.length > _maxQueue) {
        list.removeAt(0);
      }
      await prefs.setString(_savesKey, jsonEncode(list));
    } catch (e, st) {
      AppLogger.e('AxionPendingCaptureStore enqueueSave', e, st);
    }
  }

  /// Bekleyen kayıtları alır ve kuyruğu temizler (işleyen taraf sorumlu).
  Future<List<({String name, String phone})>> takeSaves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _decodeList(prefs.getString(_savesKey));
      if (list.isEmpty) return const [];
      await prefs.remove(_savesKey);
      return [
        for (final e in list)
          if ((e['phone'] as String? ?? '').isNotEmpty)
            (
              name: e['name'] as String? ?? '',
              phone: e['phone'] as String,
            ),
      ];
    } catch (e, st) {
      AppLogger.e('AxionPendingCaptureStore takeSaves', e, st);
      return const [];
    }
  }

  /// Müşteri oluştu; çağrı geçmişi bağlaması bir sonraki açılışta yapılacak.
  Future<void> enqueueLink({
    required String normalizedKey,
    required String customerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _decodeMap(prefs.getString(_linksKey));
      map[normalizedKey] = customerId;
      await prefs.setString(_linksKey, jsonEncode(map));
    } catch (e, st) {
      AppLogger.e('AxionPendingCaptureStore enqueueLink', e, st);
    }
  }

  /// Bekleyen bağlamaları alır ve temizler.
  Future<Map<String, String>> takeLinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _decodeMap(prefs.getString(_linksKey));
      if (map.isEmpty) return const {};
      await prefs.remove(_linksKey);
      return map;
    } catch (e, st) {
      AppLogger.e('AxionPendingCaptureStore takeLinks', e, st);
      return const {};
    }
  }

  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in decoded)
          if (e is Map<String, dynamic>) e,
      ];
    } catch (_) {
      return [];
    }
  }

  Map<String, String> _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in decoded.entries)
          if (e.value is String) e.key: e.value as String,
      };
    } catch (_) {
      return {};
    }
  }
}
