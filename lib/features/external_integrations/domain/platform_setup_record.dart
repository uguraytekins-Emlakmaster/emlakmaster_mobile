import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// `offices/{officeId}/platform_setups/{platform.storageKey}`
  Map<String, dynamic> toFirestore() {
    return {
      'platform': platform.storageKey,
      'officeId': officeId,
      'ownerUserId': ownerUserId,
      'connectionMode': connectionMode.name,
      'setupStatus': setupStatus.name,
      'storeName': storeName,
      'contactEmail': contactEmail,
      'companyInfo': companyInfo,
      'transferKey': transferKey,
      'integrationReference': integrationReference,
      'applicationStatus': applicationStatus,
      'notes': notes,
      'setupCompleted': setupCompleted,
      'awaitingVerification': awaitingVerification,
      'oauthVerified': oauthVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastVerifiedAt': lastVerifiedAt != null ? Timestamp.fromDate(lastVerifiedAt!) : null,
      'lastSyncAt': lastSyncAt != null ? Timestamp.fromDate(lastSyncAt!) : null,
    };
  }

  static PlatformSetupRecord? fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null) return null;
    final platformKey = d['platform'] as String?;
    final pid = IntegrationPlatformId.tryParse(platformKey);
    if (pid == null) return null;

    DateTime? ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return PlatformSetupRecord(
      platform: pid,
      officeId: d['officeId'] as String? ?? '',
      ownerUserId: d['ownerUserId'] as String? ?? '',
      connectionMode: _parseConnectionMode(d['connectionMode'] as String?),
      setupStatus: _parseSetupStatus(d['setupStatus'] as String?),
      storeName: d['storeName'] as String?,
      contactEmail: d['contactEmail'] as String?,
      companyInfo: d['companyInfo'] as String?,
      transferKey: d['transferKey'] as String?,
      integrationReference: d['integrationReference'] as String?,
      applicationStatus: d['applicationStatus'] as String?,
      notes: d['notes'] as String?,
      setupCompleted: d['setupCompleted'] as bool? ?? false,
      awaitingVerification: d['awaitingVerification'] as bool? ?? false,
      oauthVerified: d['oauthVerified'] as bool? ?? false,
      createdAt: ts(d['createdAt']) ?? DateTime.now(),
      updatedAt: ts(d['updatedAt']) ?? DateTime.now(),
      lastVerifiedAt: ts(d['lastVerifiedAt']),
      lastSyncAt: ts(d['lastSyncAt']),
    );
  }

  static IntegrationConnectionMode _parseConnectionMode(String? s) {
    if (s == null) return IntegrationConnectionMode.officialSetup;
    for (final v in IntegrationConnectionMode.values) {
      if (v.name == s) return v;
    }
    return IntegrationConnectionMode.officialSetup;
  }

  static IntegrationSetupStatus _parseSetupStatus(String? s) {
    if (s == null) return IntegrationSetupStatus.notStarted;
    for (final v in IntegrationSetupStatus.values) {
      if (v.name == s) return v;
    }
    return IntegrationSetupStatus.inProgress;
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
