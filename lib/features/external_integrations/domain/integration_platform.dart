import 'package:equatable/equatable.dart';

import 'integration_capability.dart';
import 'integration_platform_id.dart';
import 'platform_connection_truth_kind.dart';
import 'platform_connection_ui_state.dart';
import 'platform_error_ui.dart';
import 'platform_setup_lifecycle.dart';
import 'platform_setup_record.dart';
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
    required this.truthKind,
    this.lastSyncAt,
    this.errorState,
    this.connectedAccountLabel,
    this.setupRecord,
    this.setupLifecycle,
  });

  final IntegrationPlatformId id;
  final String name;

  /// Logo yerine premium avatar harfi / kısa etiket (ileride asset).
  final String logoLabel;
  final IntegrationSupportLevel supportLevel;
  final PlatformUiCapabilities capabilities;
  final PlatformConnectionUiState connectionState;
  /// Gerçek OAuth/canlı API durumu — [connectionState] yalnızca eski görünüm için tutulur.
  final PlatformConnectionTruthKind truthKind;
  final DateTime? lastSyncAt;
  final PlatformErrorUi? errorState;

  /// Bağlı hesap adı özeti (mock).
  final String? connectedAccountLabel;

  /// Ofis kurulum sihirbazı kaydı (varsa kart gerçek ilerlemeyi gösterir).
  final PlatformSetupRecord? setupRecord;

  /// Türetilmiş yaşam döngüsü (ham [setupRecord.setupStatus] yerine gösterim için).
  final PlatformSetupLifecycleState? setupLifecycle;

  @override
  List<Object?> get props => [
        id,
        name,
        logoLabel,
        supportLevel,
        capabilities,
        connectionState,
        truthKind,
        lastSyncAt,
        errorState,
        connectedAccountLabel,
        setupRecord,
        setupLifecycle,
      ];
}
