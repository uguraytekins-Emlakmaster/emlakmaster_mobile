import 'package:emlakmaster_mobile/features/auth/domain/login_entry_persona.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyLoginEntryPersona = 'login_entry_persona_v1';

/// Giriş ekranında seçilen yönetici / danışman yolu (oturumlar arası hatırlanır).
class LoginEntryStore {
  LoginEntryStore._();

  static final LoginEntryStore instance = LoginEntryStore._();

  LoginEntryPersona? _persona;
  bool _loaded = false;

  LoginEntryPersona? get personaSync => _persona;

  Future<void> warmUp() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _persona = LoginEntryPersona.fromId(prefs.getString(_keyLoginEntryPersona));
    _loaded = true;
  }

  Future<LoginEntryPersona?> loadPersona() async {
    await warmUp();
    return _persona;
  }

  Future<void> setPersona(LoginEntryPersona persona) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLoginEntryPersona, persona.id);
    _persona = persona;
    _loaded = true;
  }

  Future<void> clearPersona() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoginEntryPersona);
    _persona = null;
    _loaded = true;
  }
}
