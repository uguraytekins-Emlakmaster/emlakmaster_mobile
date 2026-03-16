import 'package:shared_preferences/shared_preferences.dart';

const String _keyOnboardingCompleted = 'onboarding_completed';

/// İlk açılış onboarding ekranının gösterilip gösterilmediğini tutar.
/// Uygulama başında [warmUp] çağrılmalı; redirect'te [completedSync] senkron okunur.
class OnboardingStore {
  OnboardingStore._();

  static final OnboardingStore _instance = OnboardingStore._();
  static OnboardingStore get instance => _instance;

  bool? _completed;

  /// Uygulama başında bir kez çağrın; böylece [completedSync] doğru döner.
  Future<void> warmUp() async {
    if (_completed != null) return;
    final prefs = await SharedPreferences.getInstance();
    _completed = prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  /// Senkron değer (warmUp sonrası). Varsayılan false = henüz gösterme tamamlanmadı.
  bool get completedSync => _completed ?? false;

  /// Onboarding tamamlandığında çağrılır; bir daha gösterilmez.
  Future<void> setCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, true);
    _completed = true;
  }
}
