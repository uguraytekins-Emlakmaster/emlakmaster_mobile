import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/features/contact_save/data/contact_permission_helper.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../domain/axion_phone_matcher.dart';

/// Cihaz rehberi isim dizini — Axion Agent için.
///
/// Telefon rehberindeki kayıtlı isimleri `normalizedKey → isim` haritası
/// olarak sunar; kayıtsız numara uyarıları ve kayıt formu bu isimlerle
/// önceden doldurulur.
///
/// Kurallar:
/// - İzin İSTEMEZ; yalnızca daha önce verilmiş izinle sessizce okur.
/// - Sonuç bellekte 10 dakika önbelleklenir (tekrarlı tam rehber
///   taraması yok — pil ve hız korunur).
/// - Hata durumunda boş harita döner; akış asla kırılmaz.
class AxionDeviceContactDirectory {
  AxionDeviceContactDirectory._();
  static final AxionDeviceContactDirectory instance =
      AxionDeviceContactDirectory._();

  static const Duration _cacheTtl = Duration(minutes: 10);

  Map<String, String>? _cache;
  DateTime? _cachedAt;

  /// Rehberdeki `normalizedKey → kayıtlı isim` haritası.
  Future<Map<String, String>> namesByPhoneKey() async {
    final cached = _cache;
    final at = _cachedAt;
    if (cached != null &&
        at != null &&
        DateTime.now().difference(at) < _cacheTtl) {
      return cached;
    }

    try {
      final perm = await ContactPermissionHelper.instance
          .getContactPermissionStatus();
      if (perm != ContactPermissionResult.granted) {
        return _cache ?? const {};
      }

      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      final map = <String, String>{};
      for (final c in contacts) {
        final name = (c.displayName ?? '').trim();
        if (name.isEmpty) continue;
        for (final p in c.phones) {
          final key = AxionPhoneMatcher.normalize(p.number);
          if (!AxionPhoneMatcher.isMeaningful(key)) continue;
          map.putIfAbsent(key, () => name);
        }
      }
      _cache = map;
      _cachedAt = DateTime.now();
      return map;
    } catch (e, st) {
      AppLogger.e('AxionDeviceContactDirectory load', e, st);
      return _cache ?? const {};
    }
  }

  /// Önbelleği düşür (ör. rehber izni yeni verildiğinde).
  void invalidate() {
    _cache = null;
    _cachedAt = null;
  }
}
