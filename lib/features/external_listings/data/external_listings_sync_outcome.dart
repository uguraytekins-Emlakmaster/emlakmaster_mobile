/// [ClientExternalListingsSyncService.syncNow] sonucu.
class ExternalListingsSyncOutcome {
  const ExternalListingsSyncOutcome({
    required this.written,
    required this.liveWritten,
    required this.demoWritten,
    required this.usedDemoFallback,
  });

  /// Firestore’a yazılan toplam kayıt (canlı + örnek).
  final int written;

  /// HTTP ile çekilen canlı ilan sayısı.
  final int liveWritten;

  /// Otomatik veya manuel yüklenen örnek ilan sayısı.
  final int demoWritten;

  /// Canlı çekim boş kaldığında örnek liste ile dolduruldu mu?
  final bool usedDemoFallback;

  bool get isEmpty => written == 0;
}
