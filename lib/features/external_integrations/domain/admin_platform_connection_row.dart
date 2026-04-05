import 'package:equatable/equatable.dart';

import 'integration_platform_id.dart';
import 'platform_connection_truth_kind.dart';
import 'platform_connection_ui_state.dart';
import 'platform_error_ui.dart';

/// Ofis yöneticisi görünümü: hangi kullanıcı hangi platformda, durum nedir (ileride Firestore).
class AdminPlatformConnectionRow extends Equatable {
  const AdminPlatformConnectionRow({
    required this.userId,
    required this.userDisplayName,
    required this.platform,
    required this.connectionState,
    required this.truthKind,
    this.lastSyncAt,
    this.error,
  });

  final String userId;
  final String userDisplayName;
  final IntegrationPlatformId platform;
  final PlatformConnectionUiState connectionState;
  final PlatformConnectionTruthKind truthKind;
  final DateTime? lastSyncAt;
  final PlatformErrorUi? error;

  @override
  List<Object?> get props =>
      [userId, userDisplayName, platform, connectionState, truthKind, lastSyncAt, error];
}
