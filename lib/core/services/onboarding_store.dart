import 'package:shared_preferences/shared_preferences.dart';

const String _keyOnboardingCompleted = 'onboarding_completed';
const String _keyWorkspaceSetupCompleted = 'workspace_setup_completed';

/// İlk açılış onboarding ekranının gösterilip gösterilmediğini tutar.
/// Uygulama başında [warmUp] çağrılmalı; redirect'te [completedSync] senkron okunur.
class OnboardingStore {
  OnboardingStore._();

  static final OnboardingStore _instance = OnboardingStore._();
  static OnboardingStore get instance => _instance;

  bool? _completed;
  bool? _workspaceSetupCompleted;

  /// Uygulama başında bir kez çağrın; böylece [completedSync] doğru döner.
  Future<void> warmUp() async {
    final prefs = await SharedPreferences.getInstance();
    _completed ??= prefs.getBool(_keyOnboardingCompleted) ?? false;
    _workspaceSetupCompleted ??= prefs.getBool(_keyWorkspaceSetupCompleted) ?? false;
  }

  /// Senkron değer (warmUp sonrası). Varsayılan false = henüz gösterme tamamlanmadı.
  bool get completedSync => _completed ?? false;

  /// Onboarding tamamlandığında çağrılır; bir daha gösterilmez.
  Future<void> setCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, true);
    _completed = true;
  }

  /// İlk giriş: ofis seçimi + isteğe bağlı platform adımı tamamlandı mı?
  bool get workspaceSetupCompletedSync => _workspaceSetupCompleted ?? false;

  Future<void> setWorkspaceSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWorkspaceSetupCompleted, true);
    _workspaceSetupCompleted = true;
  }
}
