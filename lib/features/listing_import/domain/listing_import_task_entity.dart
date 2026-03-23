import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// `listing_import_tasks` — içe aktarma geçmişi ve durum.
class ListingImportTaskEntity extends Equatable {
  const ListingImportTaskEntity({
    required this.id,
    required this.ownerUserId,
    required this.officeId,
    required this.sourceType,
    required this.status,
    this.platform,
    this.sourceUrl,
    this.sourceStoragePath,
    this.importMode,
    this.countsImported = 0,
    this.countsDuplicates = 0,
    this.countsErrors = 0,
    this.errorCode,
    this.errorMessage,
    this.createdAt,
    this.processedAt,
  });

  final String id;
  final String ownerUserId;
  final String officeId;
  final String sourceType; // url | file | extension
  final String status;
  final String? platform;
  final String? sourceUrl;
  final String? sourceStoragePath;
  final String? importMode;
  final int countsImported;
  final int countsDuplicates;
  final int countsErrors;
  final String? errorCode;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? processedAt;

  static ListingImportTaskEntity fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    Timestamp? ts(dynamic x) => x is Timestamp ? x : null;
    final c = d['counts'];
    int n(dynamic v) => v is int ? v : (v is num ? v.toInt() : 0);
    return ListingImportTaskEntity(
      id: doc.id,
      ownerUserId: d['ownerUserId'] as String? ?? '',
      officeId: d['officeId'] as String? ?? '',
      sourceType: d['sourceType'] as String? ?? '',
      status: d['status'] as String? ?? '',
      platform: d['platform'] as String?,
      sourceUrl: d['sourceUrl'] as String?,
      sourceStoragePath: d['storagePath'] as String?,
      importMode: d['importMode'] as String?,
      countsImported: c is Map ? n(c['imported']) : 0,
      countsDuplicates: c is Map ? n(c['duplicates']) : 0,
      countsErrors: c is Map ? n(c['errors']) : 0,
      errorCode: d['errorCode'] as String?,
      errorMessage: d['errorMessage'] as String?,
      createdAt: ts(d['createdAt'])?.toDate(),
      processedAt: ts(d['processedAt'])?.toDate(),
    );
  }

  @override
  List<Object?> get props => [id, status, sourceType, createdAt];
}
