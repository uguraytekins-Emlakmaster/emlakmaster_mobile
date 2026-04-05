import 'package:equatable/equatable.dart';

import 'integration_connection_mode.dart';
import 'integration_platform_id.dart';
import 'integration_setup_status.dart';

/// Ofis bazlı platform kurulum kaydı — Firestore’a taşınmaya uygun alanlar.
class PlatformSetupRecord extends Equatable {
  const PlatformSetupRecord({
    required this.platform,
    required this.officeId,
    required this.ownerUserId,
    required this.connectionMode,
    required this.setupStatus,
    this.storeName,
    this.contactEmail,
    this.companyInfo,
    this.transferKey,
    this.integrationReference,
    this.applicationStatus,
    this.notes,
    this.setupCompleted = false,
    this.awaitingVerification = false,
    this.oauthVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastVerifiedAt,
    this.lastSyncAt,
  });

  final IntegrationPlatformId platform;
  final String officeId;
  final String ownerUserId;
  final IntegrationConnectionMode connectionMode;
  final IntegrationSetupStatus setupStatus;

  final String? storeName;
  final String? contactEmail;
  final String? companyInfo;
  final String? transferKey;
  final String? integrationReference;
  final String? applicationStatus;
  final String? notes;

  final bool setupCompleted;
  final bool awaitingVerification;

  /// Yalnızca gerçek OAuth/API doğrulandığında true — varsayılan false.
  final bool oauthVerified;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastVerifiedAt;
  final DateTime? lastSyncAt;

  PlatformSetupRecord copyWith({
    IntegrationPlatformId? platform,
    String? officeId,
    String? ownerUserId,
    IntegrationConnectionMode? connectionMode,
    IntegrationSetupStatus? setupStatus,
    String? storeName,
    String? contactEmail,
    String? companyInfo,
    String? transferKey,
    String? integrationReference,
    String? applicationStatus,
    String? notes,
    bool? setupCompleted,
    bool? awaitingVerification,
    bool? oauthVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastVerifiedAt,
    DateTime? lastSyncAt,
  }) {
    return PlatformSetupRecord(
      platform: platform ?? this.platform,
      officeId: officeId ?? this.officeId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      connectionMode: connectionMode ?? this.connectionMode,
      setupStatus: setupStatus ?? this.setupStatus,
      storeName: storeName ?? this.storeName,
      contactEmail: contactEmail ?? this.contactEmail,
      companyInfo: companyInfo ?? this.companyInfo,
      transferKey: transferKey ?? this.transferKey,
      integrationReference: integrationReference ?? this.integrationReference,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      notes: notes ?? this.notes,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      awaitingVerification: awaitingVerification ?? this.awaitingVerification,
      oauthVerified: oauthVerified ?? this.oauthVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  List<Object?> get props => [
        platform,
        officeId,
        ownerUserId,
        connectionMode,
        setupStatus,
        storeName,
        updatedAt,
      ];
}
