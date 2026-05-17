/// Sekme geçmişi — Android geri ile önceki ana sekmeye dönüş.
class TabHistoryController {
  TabHistoryController({int initialIndex = 0}) : _currentIndex = initialIndex;

  final List<int> _stack = <int>[];
  int _currentIndex;

  int get currentIndex => _currentIndex;

  bool get canPopTab => _stack.isNotEmpty;

  /// Kullanıcı veya programatik sekme değişimi (aynı sekme yok sayılır).
  void recordVisit(int pageIndex) {
    if (pageIndex == _currentIndex) return;
    _stack.add(_currentIndex);
    _currentIndex = pageIndex;
  }

  /// Programatik atlama — geçmişe yazmadan sekme değiştir (kısayol kuyruğu).
  void jumpWithoutHistory(int pageIndex) {
    _currentIndex = pageIndex;
  }

  /// Önceki sekme indeksi; yoksa null.
  int? popTab() {
    if (_stack.isEmpty) return null;
    _currentIndex = _stack.removeLast();
    return _currentIndex;
  }

  void clear() {
    _stack.clear();
  }
}
