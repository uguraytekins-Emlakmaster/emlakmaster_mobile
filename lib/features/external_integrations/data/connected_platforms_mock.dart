import '../domain/integration_capability.dart';
import '../domain/integration_platform.dart';
import '../domain/integration_platform_id.dart';
import '../domain/platform_connection_ui_state.dart';
import '../domain/platform_error_ui.dart';
import '../domain/platform_ui_capabilities.dart';
import '../domain/admin_platform_connection_row.dart';

/// Phase 1.4 — gerçek API yok; tutarlı mock senaryoları.
abstract final class ConnectedPlatformsMock {
  static final DateTime _t1 = DateTime(2026, 3, 18, 14, 32);
  static final DateTime _t2 = DateTime(2026, 3, 17, 9, 15);
  static final DateTime _t3 = DateTime(2026, 3, 16, 18, 40);

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
        connectionState: PlatformConnectionUiState.connected,
        lastSyncAt: _t1,
        connectedAccountLabel: 'kurumsal@rainbowgayrimenkul.com',
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
        connectionState: PlatformConnectionUiState.limited,
        lastSyncAt: _t2,
        connectedAccountLabel: 'Rainbow Gayrimenkul',
        errorState: const PlatformErrorUi(
          shortMessage: 'Bazı özellikler platform politikası nedeniyle kapalı.',
          hint: 'Mesajlar için tarayıcı uzantısı planlanıyor.',
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
        lastSyncAt: _t3,
        errorState: const PlatformErrorUi(
          shortMessage: 'Oturum süresi dolmuş olabilir.',
          hint: 'Yeniden bağlanarak devam edin.',
        ),
      ),
    ];
  }

  /// Ofis yöneticisi paneli — örnek çok kullanıcı görünümü (ileride officeId sorgusu).
  static List<AdminPlatformConnectionRow> officeOverview() {
    return [
      AdminPlatformConnectionRow(
        userId: 'u_demo_1',
        userDisplayName: 'Ayşe Yılmaz',
        platform: IntegrationPlatformId.sahibinden,
        connectionState: PlatformConnectionUiState.connected,
        lastSyncAt: _t1,
      ),
      AdminPlatformConnectionRow(
        userId: 'u_demo_2',
        userDisplayName: 'Mehmet Kaya',
        platform: IntegrationPlatformId.hepsiemlak,
        connectionState: PlatformConnectionUiState.limited,
        lastSyncAt: _t2,
        error: const PlatformErrorUi(shortMessage: 'Kısmi senkron'),
      ),
      const AdminPlatformConnectionRow(
        userId: 'u_demo_3',
        userDisplayName: 'Zeynep Demir',
        platform: IntegrationPlatformId.emlakjet,
        connectionState: PlatformConnectionUiState.needsAttention,
        error: PlatformErrorUi(shortMessage: 'Kimlik doğrulama gerekli'),
      ),
    ];
  }
}
