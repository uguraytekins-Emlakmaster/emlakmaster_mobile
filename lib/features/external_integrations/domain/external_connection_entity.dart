import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'integration_capability.dart';
import 'integration_platform_id.dart';

/// `external_connections/{id}` — kullanıcıya bağlı harici hesap.
class ExternalConnectionEntity extends Equatable {
  const ExternalConnectionEntity({
    required this.id,
    required this.userId,
    required this.officeId,
    required this.platform,
    required this.externalAccountId,
    this.accountDisplayName,
    required this.connectionStatus,
    required this.authMethod,
    this.encryptedCredentialRef,
    this.tokenRef,
    required this.capabilitySnapshot,
    this.lastValidatedAt,
    this.lastSyncedAt,
    this.lastError,
    this.lastErrorCode,
    required this.createdAt,
    required this.updatedAt,
    this.disabledByAdmin = false,
  });

  final String id;
  final String userId;
  final String officeId;
  final IntegrationPlatformId platform;
  final String externalAccountId;
  final String? accountDisplayName;

  /// connected | disconnected | needs_reauth | limited | error
  final String connectionStatus;
  final String authMethod;
  final String? encryptedCredentialRef;
  final String? tokenRef;
  final IntegrationCapabilitySet capabilitySnapshot;
  final DateTime? lastValidatedAt;
  final DateTime? lastSyncedAt;
  final String? lastError;
  final String? lastErrorCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool disabledByAdmin;

  static ExternalConnectionEntity fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final platformKey = d['platform'] as String? ?? 'sahibinden';
    final platform = IntegrationPlatformId.tryParse(platformKey) ?? IntegrationPlatformId.sahibinden;
    Timestamp? ts(dynamic x) => x is Timestamp ? x : null;
    return ExternalConnectionEntity(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      officeId: d['officeId'] as String? ?? '',
      platform: platform,
      externalAccountId: d['externalAccountId'] as String? ?? '',
      accountDisplayName: d['accountDisplayName'] as String?,
      connectionStatus: d['connectionStatus'] as String? ?? 'disconnected',
      authMethod: d['authMethod'] as String? ?? 'unknown',
      encryptedCredentialRef: d['encryptedCredentialRef'] as String?,
      tokenRef: d['tokenRef'] as String?,
      capabilitySnapshot: IntegrationCapabilitySet.fromJson(
        (d['capabilitySnapshot'] as Map?)?.cast<String, dynamic>(),
      ),
      lastValidatedAt: ts(d['lastValidatedAt'])?.toDate(),
      lastSyncedAt: ts(d['lastSyncedAt'])?.toDate(),
      lastError: d['lastError'] as String?,
      lastErrorCode: d['lastErrorCode'] as String?,
      createdAt: ts(d['createdAt'])?.toDate() ?? DateTime.now(),
      updatedAt: ts(d['updatedAt'])?.toDate() ?? DateTime.now(),
      disabledByAdmin: d['disabledByAdmin'] == true,
    );
  }

  @override
  List<Object?> get props => [id, userId, officeId, platform, connectionStatus, lastSyncedAt];
}
