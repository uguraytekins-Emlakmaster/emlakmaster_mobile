import '../domain/integration_capability.dart';
import '../domain/integration_platform_id.dart';

/// Platform varsayılan yetenekleri — gerçek API durumuna göre güncellenir (TBD = güvenli varsayılan).
abstract final class IntegrationCapabilityRegistry {
  IntegrationCapabilityRegistry._();

  /// URL içe aktarma bayrakları deneysel kanalı açar; canlı OAuth ayrıca gerekir.
  static const IntegrationCapabilitySet _phase1Default = IntegrationCapabilitySet(
    canImportListings: true,
    requiresReauth: true,
    supportsFeedImport: true,
    canUseUrlImport: true,
    canUseFileImport: true,
    canUseBrowserExtension: true,
  );

  static IntegrationCapabilitySet forPlatform(IntegrationPlatformId id) {
    switch (id) {
      case IntegrationPlatformId.sahibinden:
      case IntegrationPlatformId.hepsiemlak:
      case IntegrationPlatformId.emlakjet:
        return _phase1Default;
    }
  }

  static List<IntegrationPlatformId> get supportedPlatforms =>
      IntegrationPlatformId.values;
}
