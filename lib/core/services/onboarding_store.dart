import 'package:shared_preferences/shared_preferences.dart';

const String _keyOnboardingCompleted = 'onboarding_completed';
const String _keyWorkspaceSetupCompleted = 'workspace_setup_completed';
const String _keyConsultantTourCompleted = 'consultant_tour_completed';
const String _keyManagerTourCompleted = 'manager_tour_completed';

/// İlk açılış onboarding ekranının gösterilip gösterilmediğini tutar.
/// Uygulama başında [warmUp] çağrılmalı; redirect'te [completedSync] senkron okunur.
class OnboardingStore {
  OnboardingStore._();

  static final OnboardingStore _instance = OnboardingStore._();
  static OnboardingStore get instance => _instance;

  bool? _completed;
  bool? _workspaceSetupCompleted;
  bool? _consultantTourCompleted;
  bool? _managerTourCompleted;
  bool _prefsLoaded = false;

  /// Uygulama başında bir kez çağrın; böylece [completedSync] doğru döner.
  /// Tekrar çağrıda SharedPreferences tekrar açılmaz (ilk kare / runApp yolu hızlanır).
  Future<void> warmUp() async {
    if (_prefsLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _completed ??= prefs.getBool(_keyOnboardingCompleted) ?? false;
    _workspaceSetupCompleted ??=
        prefs.getBool(_keyWorkspaceSetupCompleted) ?? false;
    _consultantTourCompleted ??=
        prefs.getBool(_keyConsultantTourCompleted) ?? false;
    _managerTourCompleted ??=
        prefs.getBool(_keyManagerTourCompleted) ?? false;
    _prefsLoaded = true;
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

  /// İlk giriş sonrası danışman "Benim Günüm" eğitim turu gösterildi mi?
  /// Tur yalnızca bir kez (bayrak false iken) otomatik tetiklenir.
  bool get consultantTourCompletedSync => _consultantTourCompleted ?? false;

  Future<void> setConsultantTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyConsultantTourCompleted, true);
    _consultantTourCompleted = true;
  }

  /// Turu tekrar göstermek için bayrağı sıfırlar (Ayarlar → "Turu tekrar göster").
  Future<void> resetConsultantTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyConsultantTourCompleted, false);
    _consultantTourCompleted = false;
    _prefsLoaded = true;
  }

  /// İlk yönetici girişinde "Yönetici Paneli" eğitim turu gösterildi mi?
  /// Tur yalnızca bir kez (bayrak false iken) otomatik tetiklenir.
  bool get managerTourCompletedSync => _managerTourCompleted ?? false;

  Future<void> setManagerTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyManagerTourCompleted, true);
    _managerTourCompleted = true;
  }

  /// Yönetici turunu tekrar göstermek için bayrağı sıfırlar
  /// (Ayarlar → "Turu tekrar göster").
  Future<void> resetManagerTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyManagerTourCompleted, false);
    _managerTourCompleted = false;
    _prefsLoaded = true;
  }

  /// Yalnızca geliştirme: tanıtımı tekrar göstermek için bayrağı sıfırlar.
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, false);
    _completed = false;
    _prefsLoaded = true;
  }
}
