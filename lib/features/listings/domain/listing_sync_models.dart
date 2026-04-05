import 'package:cloud_firestore/cloud_firestore.dart';

/// `listing_sources/{id}` — ofis başına connector yapılandırması (salt okuma).
class ListingSourceDoc {
  const ListingSourceDoc({
    required this.id,
    required this.officeId,
    required this.platform,
    this.connectionId,
    this.defaultOwnerUserId,
    this.connectorType = 'official_api',
    this.status = 'active',
    this.updatedAt,
  });

  final String id;
  final String officeId;

  /// sahibinden | emlakjet | hepsiemlak | …
  final String platform;
  final String? connectionId;
  final String? defaultOwnerUserId;

  /// official_api | file_import | internal
  final String connectorType;
  final String status;
  final DateTime? updatedAt;

  static ListingSourceDoc? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null) return null;
    return ListingSourceDoc(
      id: doc.id,
      officeId: d['officeId'] as String? ?? '',
      platform: d['platform'] as String? ?? '',
      connectionId: d['connectionId'] as String?,
      defaultOwnerUserId: d['defaultOwnerUserId'] as String?,
      connectorType: d['connectorType'] as String? ?? 'official_api',
      status: d['status'] as String? ?? 'active',
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// `listing_sync_runs/{id}` — senkron çalıştırma özeti.
class ListingSyncRunDoc {
  const ListingSyncRunDoc({
    required this.id,
    required this.officeId,
    required this.platform,
    this.status,
    this.stats,
    this.message,
    this.startedAt,
    this.finishedAt,
  });

  final String id;
  final String officeId;
  final String platform;
  final String? status;
  final Map<String, dynamic>? stats;
  final String? message;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  static ListingSyncRunDoc? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null) return null;
    final st = d['stats'];
    return ListingSyncRunDoc(
      id: doc.id,
      officeId: d['officeId'] as String? ?? '',
      platform: d['platform'] as String? ?? '',
      status: d['status'] as String?,
      stats: st is Map<String, dynamic> ? st : null,
      message: d['message'] as String?,
      startedAt: (d['startedAt'] as Timestamp?)?.toDate(),
      finishedAt: (d['finishedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// `listing_sync_errors/{id}` — satır bazlı hata.
class ListingSyncErrorDoc {
  const ListingSyncErrorDoc({
    required this.id,
    required this.runId,
    required this.officeId,
    required this.platform,
    required this.code,
    required this.message,
    this.at,
  });

  final String id;
  final String runId;
  final String officeId;
  final String platform;
  final String code;
  final String message;
  final DateTime? at;

  static ListingSyncErrorDoc? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null) return null;
    return ListingSyncErrorDoc(
      id: doc.id,
      runId: d['runId'] as String? ?? '',
      officeId: d['officeId'] as String? ?? '',
      platform: d['platform'] as String? ?? '',
      code: d['code'] as String? ?? '',
      message: d['message'] as String? ?? '',
      at: (d['at'] as Timestamp?)?.toDate(),
    );
  }
}
