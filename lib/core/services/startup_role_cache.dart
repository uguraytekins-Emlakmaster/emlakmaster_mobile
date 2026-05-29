import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyUid = 'startup_shell_uid_v1';
const _keyRole = 'startup_shell_role_v1';

/// Son bilinen rol — Firestore bootstrap bitene kadar shell'i anında gösterir.
class StartupRoleCache {
  StartupRoleCache._();

  static final StartupRoleCache instance = StartupRoleCache._();

  String? _uid;
  AppRole? _role;
  bool _loaded = false;

  Future<void> warmUp() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _uid = prefs.getString(_keyUid);
    _role = AppRole.fromId(prefs.getString(_keyRole));
    _loaded = true;
  }

  AppRole? roleForUser(String uid) {
    if (!_loaded || _uid != uid || _role == null || _role == AppRole.guest) {
      return null;
    }
    return _role;
  }

  Future<void> persist(String uid, AppRole role) async {
    if (role == AppRole.guest) return;
    _uid = uid;
    _role = role;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, uid);
    await prefs.setString(_keyRole, role.id);
  }

  Future<void> clear() async {
    _uid = null;
    _role = null;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keyRole);
  }
}
