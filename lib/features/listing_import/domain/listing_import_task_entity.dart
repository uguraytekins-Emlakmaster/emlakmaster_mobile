import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'import_source_type.dart';
import 'import_task_status.dart';

/// İçe aktarma görevi — Firestore + yerel motor (Phase 1.5) ortak model.
class ListingImportTaskEntity extends Equatable {
  const ListingImportTaskEntity({
    required this.id,
    required this.ownerUserId,
    required this.officeId,
    required this.platformId,
    required this.sourceType,
    required this.status,
    this.progress = 0,
    this.listingIds = const [],
    this.countsImported = 0,
    this.countsDuplicates = 0,
    this.countsErrors = 0,
    this.errorCode,
    this.errorMessage,
    this.createdAt,
    this.completedAt,
    this.sourceUrl,
    this.sourceStoragePath,
    this.importMode,
  });

  final String id;
  final String ownerUserId;
  final String officeId;
  /// Kaynak platform (sahibinden, hepsiemlak, emlakjet, manual, file, …)
  final String platformId;
  final ImportSourceType sourceType;
  final ImportTaskStatus status;
  /// 0–100
  final int progress;
  final List<String> listingIds;
  final int countsImported;
  final int countsDuplicates;
  final int countsErrors;
  final String? errorCode;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String? sourceUrl;
  final String? sourceStoragePath;
  final String? importMode;

  /// Geriye dönük: `sourceType` string (Firestore)
  String get sourceTypeLabel => sourceType.wireValue;

  /// Geriye dönük: eski UI `platform` alanı
  String? get platform => platformId.isEmpty ? null : platformId;

  /// Geriye dönük: `processedAt` adı
  DateTime? get processedAt => completedAt;

  static int _progressFromDoc(dynamic raw) {
    if (raw is! num) return 0;
    return raw.round().clamp(0, 100);
  }

  static ListingImportTaskEntity fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    Timestamp? ts(dynamic x) => x is Timestamp ? x : null;
    final c = d['counts'];
    int n(dynamic v) => v is int ? v : (v is num ? v.toInt() : 0);
    final listingIdsRaw = d['listingIds'];
    final List<String> listingIds = listingIdsRaw is List
        ? listingIdsRaw.map((e) => e.toString()).toList()
        : const [];

    final legacyPlatform = d['platform'] as String?;
    final platformId =
        (d['platformId'] as String?) ?? legacyPlatform ?? (d['sourceType'] as String? ?? 'unknown');

    return ListingImportTaskEntity(
      id: doc.id,
      ownerUserId: d['ownerUserId'] as String? ?? '',
      officeId: d['officeId'] as String? ?? '',
      platformId: platformId,
      sourceType: importSourceTypeFromWire(d['sourceType'] as String?),
      status: importTaskStatusFromWire(d['status'] as String?),
      progress: _progressFromDoc(d['progress']),
      listingIds: listingIds,
      countsImported: c is Map ? n(c['imported']) : 0,
      countsDuplicates: c is Map ? n(c['duplicates']) : 0,
      countsErrors: c is Map ? n(c['errors']) : 0,
      errorCode: d['errorCode'] as String?,
      errorMessage: d['errorMessage'] as String?,
      createdAt: ts(d['createdAt'])?.toDate(),
      completedAt: ts(d['completedAt'])?.toDate() ?? ts(d['processedAt'])?.toDate(),
      sourceUrl: d['sourceUrl'] as String?,
      sourceStoragePath: d['storagePath'] as String?,
      importMode: d['importMode'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        status,
        sourceType,
        progress,
        listingIds,
        createdAt,
        completedAt,
      ];
}
