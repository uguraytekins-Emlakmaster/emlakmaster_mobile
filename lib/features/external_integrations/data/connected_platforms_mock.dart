import '../domain/integration_capability.dart';
import '../domain/integration_platform.dart';
import '../domain/integration_platform_id.dart';
import '../domain/platform_connection_truth_kind.dart';
import '../domain/platform_connection_ui_state.dart';
import '../domain/platform_error_ui.dart';
import '../domain/platform_ui_capabilities.dart';
import '../domain/admin_platform_connection_row.dart';

/// Demo veri — canlı OAuth yok; [truthKind] ile durum dürüst gösterilir.
abstract final class ConnectedPlatformsMock {
  static List<IntegrationPlatform> userPlatforms() {
    return [
      IntegrationPlatform(
        id: IntegrationPlatformId.sahibinden,
        name: IntegrationPlatformId.sahibinden.displayName,
        logoLabel: 'S',
        supportLevel: IntegrationSupportLevel.tier1Official,
        capabilities: const PlatformUiCapabilities(
          canImportListings: true,
          canUpdatePrice: true,
          canManageMessages: true,
          canSync: true,
        ),
        connectionState: PlatformConnectionUiState.disconnected,
        truthKind: PlatformConnectionTruthKind.mockDemo,
        connectedAccountLabel: 'Örnek (canlı hesap bağlı değil)',
        errorState: const PlatformErrorUi(
          shortMessage: 'Resmi OAuth / API bağlantısı henüz devrede değil.',
          hint: 'Bu kart yalnızca arayüz örneğidir; senkron ve mesajlar aktif değildir.',
        ),
      ),
      IntegrationPlatform(
        id: IntegrationPlatformId.hepsiemlak,
        name: IntegrationPlatformId.hepsiemlak.displayName,
        logoLabel: 'H',
        supportLevel: IntegrationSupportLevel.tier2UserControlled,
        capabilities: const PlatformUiCapabilities(
          canImportListings: true,
          canUpdatePrice: false,
          canManageMessages: false,
          canSync: true,
        ),
        connectionState: PlatformConnectionUiState.disconnected,
        truthKind: PlatformConnectionTruthKind.experimentalNotLive,
        errorState: const PlatformErrorUi(
          shortMessage: 'Kullanıcı kontrollü senkron hedefi — canlı bağlantı kapalı.',
          hint: 'Deneysel URL içe aktarma ile karıştırmayın; CSV/JSON daha güvenilirdir.',
        ),
      ),
      IntegrationPlatform(
        id: IntegrationPlatformId.emlakjet,
        name: IntegrationPlatformId.emlakjet.displayName,
        logoLabel: 'E',
        supportLevel: IntegrationSupportLevel.tier3Experimental,
        capabilities: const PlatformUiCapabilities(
          canImportListings: true,
          canUpdatePrice: false,
          canManageMessages: false,
          canSync: false,
        ),
        connectionState: PlatformConnectionUiState.needsAttention,
        truthKind: PlatformConnectionTruthKind.setupIncomplete,
        errorState: const PlatformErrorUi(
          shortMessage: 'Kurulum tamamlanmadı — canlı entegrasyon aktif değil.',
          hint: 'Yeniden bağlan seçeneği şimdilik yalnızca arayüz; OAuth açıldığında etkin olacak.',
        ),
      ),
    ];
  }

  /// Ofis yöneticisi paneli — örnek çok kullanıcı görünümü (ileride officeId sorgusu).
  static List<AdminPlatformConnectionRow> officeOverview() {
    return [
      const AdminPlatformConnectionRow(
        userId: 'u_demo_1',
        userDisplayName: 'Ayşe Yılmaz',
        platform: IntegrationPlatformId.sahibinden,
        connectionState: PlatformConnectionUiState.disconnected,
        truthKind: PlatformConnectionTruthKind.mockDemo,
      ),
      const AdminPlatformConnectionRow(
        userId: 'u_demo_2',
        userDisplayName: 'Mehmet Kaya',
        platform: IntegrationPlatformId.hepsiemlak,
        connectionState: PlatformConnectionUiState.disconnected,
        truthKind: PlatformConnectionTruthKind.preparing,
        error: PlatformErrorUi(shortMessage: 'Canlı senkron henüz yok (demo).'),
      ),
      const AdminPlatformConnectionRow(
        userId: 'u_demo_3',
        userDisplayName: 'Zeynep Demir',
        platform: IntegrationPlatformId.emlakjet,
        connectionState: PlatformConnectionUiState.needsAttention,
        truthKind: PlatformConnectionTruthKind.setupIncomplete,
        error: PlatformErrorUi(shortMessage: 'Kurulum tamamlanmadı'),
      ),
    ];
  }
}
