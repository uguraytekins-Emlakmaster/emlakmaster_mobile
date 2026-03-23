import 'package:shared_preferences/shared_preferences.dart';

/// Oturum yokken kaydedilen rota; girişten sonra bir kez `consume` ile uygulanır.
abstract final class PendingDeepLinkStore {
  static const _key = 'pending_deep_link_path_v1';

  static Future<void> save(String path) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, path);
  }

  /// Varsa döndürür ve siler.
  static Future<String?> consume() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_key);
    if (v != null && v.isNotEmpty) {
      await p.remove(_key);
      return v;
    }
    return null;
  }
}
