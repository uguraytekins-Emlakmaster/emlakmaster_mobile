import '../domain/models/rainbow_intel_models.dart';

/// Endeksa / Sahibinden vb. için arayüz; şimdilik null döner (fail-safe: önbellek).
abstract final class ExternalMarketApiPlaceholder {
  ExternalMarketApiPlaceholder._();

  static Future<ExternalMarketSnapshot> fetchDistrictSnapshot(
    String district,
  ) async {
    // Gelecek: HTTP + API key; şimdilik boş.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return ExternalMarketSnapshot(
      sourceLabel: district.isEmpty ? null : district,
    );
  }
}
