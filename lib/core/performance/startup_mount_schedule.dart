/// Uygulama açılışında mount gecikmeleri — tek kaynak (dashboard/shell ile uyumlu).
abstract final class StartupMountSchedule {
  /// Kabuk üst şeritleri (senkron, post-call, draft).
  static const Duration shellChrome = Duration(milliseconds: 280);

  /// Dashboard: operasyonel şerit (takım, aksiyon, bölüm başlığı).
  static const Duration dashboardOperational = Duration(milliseconds: 160);

  /// Dashboard: KPI / birincil veri kartları.
  static const Duration dashboardPrimary = Duration(milliseconds: 240);

  /// Dashboard: ikincil kartlar (uyarılar, analitik, bağlantılar).
  static const Duration dashboardSecondary = Duration(milliseconds: 360);

  /// Dashboard: insight / ticker / bento (tam ürün modu).
  static const Duration dashboardInsight = Duration(milliseconds: 320);
}
