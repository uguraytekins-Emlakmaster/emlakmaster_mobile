/// Bağlantı durumu — UI ve yönlendirme için tek kaynak (string yerine tip güvenli).
enum PlatformConnectionUiState {
  /// Aktif oturum / senkron hazır
  connected,

  /// Hiç bağlanmamış veya kaldırılmış
  disconnected,

  /// Kısmi özellikler (okuma vb.)
  limited,

  /// Yeniden bağlanma veya müdahale gerekir
  needsAttention,
}

extension PlatformConnectionUiStateX on PlatformConnectionUiState {
  String get shortLabel => switch (this) {
        PlatformConnectionUiState.connected => 'Bağlı',
        PlatformConnectionUiState.disconnected => 'Bağlı değil',
        PlatformConnectionUiState.limited => 'Sınırlı',
        PlatformConnectionUiState.needsAttention => 'İnceleme gerekli',
      };
}
