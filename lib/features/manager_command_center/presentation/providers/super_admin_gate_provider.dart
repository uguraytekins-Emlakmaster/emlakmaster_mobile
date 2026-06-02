import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Süper admin "Tüm ofisler" kapısı — yalnızca oturum boyu (kalıcı değil).
///
/// true olduğunda komuta merkezi, filtresiz (tüm ofisler) çağrı sorgusuna geçer.
/// GERÇEK yetki Firestore kurallarındaki `users.role == 'super_admin'` iledir;
/// bu bayrak sadece UX kapısıdır. super_admin değilse filtresiz sorgu kurallarca
/// reddedilir ve kullanıcı yalnızca kendi ofisini görür (dürüst hata).
final superAdminAllOfficesGateProvider = StateProvider<bool>((ref) => false);

/// Süper admin kapı kodu doğrulama/saklama. Kod asla hardcode edilmez; SHA-256
/// hash'i `app_config/superAdminGate` dokümanında tutulur (yalnızca super_admin
/// okuyup yazabilir — kurallarla korunur).
abstract final class SuperAdminGateService {
  SuperAdminGateService._();

  static String hashOf(String code) =>
      sha256.convert(utf8.encode(code.trim())).toString();

  /// Kod hash'i ayarlanmış mı? (super_admin değilse okuma reddedilir → false.)
  static Future<bool> hasCode() async {
    try {
      final stored = await FirestoreService.fetchSuperAdminGateHash();
      return stored != null && stored.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// İlk kurulum: kod hash'ini yazar (yalnızca super_admin — kurallar korur).
  static Future<void> setCode(String code) =>
      FirestoreService.setSuperAdminGateHash(hashOf(code));

  /// Girilen kod saklanan hash ile eşleşiyor mu? Okuma reddedilirse false.
  static Future<bool> verify(String code) async {
    try {
      final stored = await FirestoreService.fetchSuperAdminGateHash();
      if (stored == null || stored.isEmpty) return false;
      return hashOf(code) == stored;
    } catch (_) {
      return false;
    }
  }
}
