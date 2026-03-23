import 'package:equatable/equatable.dart';

import 'integration_capability.dart';
import 'integration_platform_id.dart';
import 'platform_connection_ui_state.dart';
import 'platform_error_ui.dart';
import 'platform_ui_capabilities.dart';

/// Bağlı platformlar ekranı — tanım + anlık durum (mock veya API’den üretilir).
class IntegrationPlatform extends Equatable {
  const IntegrationPlatform({
    required this.id,
    required this.name,
    required this.logoLabel,
    required this.supportLevel,
    required this.capabilities,
    required this.connectionState,
    this.lastSyncAt,
    this.errorState,
    this.connectedAccountLabel,
  });

  final IntegrationPlatformId id;
  final String name;

  /// Logo yerine premium avatar harfi / kısa etiket (ileride asset).
  final String logoLabel;
  final IntegrationSupportLevel supportLevel;
  final PlatformUiCapabilities capabilities;
  final PlatformConnectionUiState connectionState;
  final DateTime? lastSyncAt;
  final PlatformErrorUi? errorState;

  /// Bağlı hesap adı özeti (mock).
  final String? connectedAccountLabel;

  @override
  List<Object?> get props => [
        id,
        name,
        logoLabel,
        supportLevel,
        capabilities,
        connectionState,
        lastSyncAt,
        errorState,
        connectedAccountLabel,
      ];
}
