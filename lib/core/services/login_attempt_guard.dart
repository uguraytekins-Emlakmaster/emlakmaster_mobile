/// Brute-force yumuşatma: başarısız girişleri pencerede sayar (istemci tarafı; Firebase zaten rate limit uygular).
class LoginAttemptGuard {
  LoginAttemptGuard._();

  static final List<DateTime> _failures = [];
  static const Duration _window = Duration(minutes: 5);
  static const int _maxFailures = 12;

  /// Başarısız denemeden önce çağır; null = devam, metin = kullanıcıya göster.
  static String? assertCanAttempt() {
    final now = DateTime.now();
    _failures.removeWhere((t) => now.difference(t) > _window);
    if (_failures.length >= _maxFailures) {
      final oldest = _failures.isNotEmpty ? _failures.first : now;
      final remaining = _window.inMinutes - now.difference(oldest).inMinutes;
      final mins = remaining.clamp(1, _window.inMinutes);
      return 'Çok fazla başarısız deneme. Güvenlik için yaklaşık $mins dakika bekleyip tekrar deneyin.';
    }
    return null;
  }

  static void recordFailure() {
    _failures.add(DateTime.now());
  }

  static void clear() {
    _failures.clear();
  }
}
