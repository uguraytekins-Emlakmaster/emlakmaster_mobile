import 'package:shared_preferences/shared_preferences.dart';

/// Aynı müşteri + taşıma kodu için kısa süreli bastırma (görüntü gürültüsü).
class EscalationDedupeStore {
  static const String _prefix = 'mgr_esc_v1_';
  static const Duration defaultTtl = Duration(hours: 24);

  String _key(String userId, String dedupeKey) => '$_prefix$userId|$dedupeKey';

  Future<bool> isSuppressed(String userId, String dedupeKey) async {
    if (userId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_key(userId, dedupeKey));
    if (ms == null) return false;
    final saved = DateTime.fromMillisecondsSinceEpoch(ms);
    if (DateTime.now().difference(saved) > defaultTtl) {
      await prefs.remove(_key(userId, dedupeKey));
      return false;
    }
    return true;
  }

  Future<void> suppress(String userId, String dedupeKey) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _key(userId, dedupeKey),
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
