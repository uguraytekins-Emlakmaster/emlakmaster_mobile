import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:emlakmaster_mobile/features/listing_import/data/listing_import_memory_store.dart';
import 'package:emlakmaster_mobile/features/listing_import/data/listing_import_xlsx.dart';
import 'package:emlakmaster_mobile/features/listing_import/data/listings_repository.dart';
import 'package:emlakmaster_mobile/features/listing_import/data/mock_listing_import_engine.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/import_source_type.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/import_task_status.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/listing_entity.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/listing_import_task_entity.dart';
import 'package:uuid/uuid.dart';

/// İş kuralları burada — UI sadece çağırır.
class ListingImportService {
  ListingImportService._();
  static final ListingImportService instance = ListingImportService._();

  final _uuid = const Uuid();
  final _store = ListingImportMemoryStore.instance;
  final _engine = MockListingImportEngine.instance;
  final _listings = ListingsRepository.instance;

  int _duplicateHits(String uid, ListingEntity listing) {
    final others = _listings.snapshot(uid);
    var n = 0;
    for (final o in others) {
      if (o.id == listing.id) continue;
      if (o.duplicateGroupId != null &&
          listing.duplicateGroupId != null &&
          o.duplicateGroupId == listing.duplicateGroupId) {
        n++;
      }
    }
    return n;
  }

  Future<String> createTask({
    required String ownerUserId,
    String officeId = '',
    required ImportSourceType sourceType,
    required String platformId,
    String? sourceUrl,
    String? importMode,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final task = ListingImportTaskEntity(
      id: id,
      ownerUserId: ownerUserId,
      officeId: officeId,
      platformId: platformId,
      sourceType: sourceType,
      status: ImportTaskStatus.pending,
      createdAt: now,
      sourceUrl: sourceUrl,
      importMode: importMode,
    );
    _store.upsertTask(ownerUserId, task);
    return id;
  }

  Future<void> updateTaskStatus(
    String uid,
    String taskId, {
    required ImportTaskStatus status,
    int progress = 0,
    String? errorMessage,
    String? errorCode,
    List<String>? listingIds,
    DateTime? completedAt,
  }) async {
    final tasks = _store.tasksSnapshot(uid);
    final i = tasks.indexWhere((t) => t.id == taskId);
    if (i < 0) return;
    final t = tasks[i];
    _store.upsertTask(
      uid,
      ListingImportTaskEntity(
        id: t.id,
        ownerUserId: t.ownerUserId,
        officeId: t.officeId,
        platformId: t.platformId,
        sourceType: t.sourceType,
        status: status,
        progress: progress.clamp(0, 100),
        listingIds: listingIds ?? t.listingIds,
        countsImported: listingIds?.length ?? t.countsImported,
        countsDuplicates: t.countsDuplicates,
        countsErrors: t.countsErrors,
        errorCode: errorCode ?? t.errorCode,
        errorMessage: errorMessage ?? t.errorMessage,
        createdAt: t.createdAt,
        completedAt: completedAt ?? t.completedAt,
        sourceUrl: t.sourceUrl,
        sourceStoragePath: t.sourceStoragePath,
        importMode: t.importMode,
      ),
    );
  }

  Future<void> attachListingsToTask(String uid, String taskId, List<ListingEntity> listings) async {
    final tasks = _store.tasksSnapshot(uid);
    final i = tasks.indexWhere((t) => t.id == taskId);
    if (i < 0) return;
    final t = tasks[i];
    final ids = [...t.listingIds];
    var dup = t.countsDuplicates;
    for (final l in listings) {
      if (_duplicateHits(uid, l) > 0) dup++;
      _listings.upsert(uid, l);
      if (!ids.contains(l.id)) ids.add(l.id);
    }
    _store.upsertTask(
      uid,
      ListingImportTaskEntity(
        id: t.id,
        ownerUserId: t.ownerUserId,
        officeId: t.officeId,
        platformId: t.platformId,
        sourceType: t.sourceType,
        status: t.status,
        progress: t.progress,
        listingIds: ids,
        countsImported: ids.length,
        countsDuplicates: dup,
        countsErrors: t.countsErrors,
        errorCode: t.errorCode,
        errorMessage: t.errorMessage,
        createdAt: t.createdAt,
        completedAt: t.completedAt,
        sourceUrl: t.sourceUrl,
        sourceStoragePath: t.sourceStoragePath,
        importMode: t.importMode,
      ),
    );
  }

  /// URL — mock motor.
  Future<void> runUrlImport({
    required String uid,
    required String officeId,
    required String url,
    String importMode = 'skip_duplicates',
  }) async {
    final taskId = await createTask(
      ownerUserId: uid,
      officeId: officeId,
      sourceType: ImportSourceType.url,
      platformId: _engine.detectPlatformId(url),
      sourceUrl: url,
      importMode: importMode,
    );

    try {
      await updateTaskStatus(uid, taskId, status: ImportTaskStatus.processing, progress: 12);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await updateTaskStatus(uid, taskId, status: ImportTaskStatus.processing, progress: 38);

      final listing = await _engine.parseUrlMock(ownerUserId: uid, url: url, taskId: taskId);

      await updateTaskStatus(uid, taskId, status: ImportTaskStatus.processing, progress: 72);
      await attachListingsToTask(uid, taskId, [listing]);

      await updateTaskStatus(
        uid,
        taskId,
        status: ImportTaskStatus.success,
        progress: 100,
        listingIds: [listing.id],
        completedAt: DateTime.now(),
      );
    } catch (e, _) {
      await updateTaskStatus(
        uid,
        taskId,
        status: ImportTaskStatus.failed,
        progress: 100,
        errorMessage: e.toString(),
        completedAt: DateTime.now(),
      );
    }
  }

  /// Dosya (CSV / JSON / XLSX) — mağaza dışa aktarımı için toplu yol (canlı OAuth gerekmez).
  Future<void> runFileImport({
    required String uid,
    required String officeId,
    required String filePath,
    required String extension,
    required Map<String, String> mapping,
    String importMode = 'skip_duplicates',
    String? storeSourcePlatform,
  }) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final ext = extension.toLowerCase();

    final String importChannel;
    switch (ext) {
      case 'csv':
      case 'txt':
        importChannel = 'import_csv';
        break;
      case 'json':
        importChannel = 'import_json';
        break;
      case 'xlsx':
      case 'xls':
        importChannel = 'import_xlsx';
        break;
      default:
        importChannel = 'import_file';
    }
    final taskPlatform = storeSourcePlatform ?? importChannel;

    final taskId = await createTask(
      ownerUserId: uid,
      officeId: officeId,
      sourceType: ImportSourceType.file,
      platformId: taskPlatform,
      sourceUrl: filePath,
      importMode: importMode,
    );

    try {
      await updateTaskStatus(uid, taskId, status: ImportTaskStatus.processing, progress: 15);

      List<ListingEntity> listings;
      if (ext == 'json') {
        listings = await _engine.parseJsonBytesMock(
          ownerUserId: uid,
          mapping: mapping,
          bytes: bytes,
          taskId: taskId,
          storeSourcePlatform: storeSourcePlatform,
          importChannel: importChannel,
        );
      } else if (ext == 'xlsx' || ext == 'xls') {
        final rows = decodeXlsxBytesToRows(bytes);
        if (rows.isEmpty) {
          throw StateError('Excel dosyasında satır bulunamadı.');
        }
        listings = await _engine.parseFileMock(
          ownerUserId: uid,
          fileName: filePath,
          mapping: mapping,
          rows: rows,
          taskId: taskId,
          storeSourcePlatform: storeSourcePlatform,
          importChannel: importChannel,
        );
      } else {
        final text = utf8.decode(bytes, allowMalformed: true);
        final rows = const CsvToListConverter(eol: '\n').convert(text);
        listings = await _engine.parseFileMock(
          ownerUserId: uid,
          fileName: filePath,
          mapping: mapping,
          rows: rows,
          taskId: taskId,
          storeSourcePlatform: storeSourcePlatform,
          importChannel: importChannel,
        );
      }

      await updateTaskStatus(uid, taskId, status: ImportTaskStatus.processing, progress: 60);
      await attachListingsToTask(uid, taskId, listings);

      await updateTaskStatus(
        uid,
        taskId,
        status: ImportTaskStatus.success,
        progress: 100,
        listingIds: listings.map((e) => e.id).toList(),
        completedAt: DateTime.now(),
      );
    } catch (e, _) {
      await updateTaskStatus(
        uid,
        taskId,
        status: ImportTaskStatus.failed,
        progress: 100,
        errorMessage: e.toString(),
        completedAt: DateTime.now(),
      );
    }
  }

  Future<void> runManualImport({
    required String uid,
    required String officeId,
    required String title,
    required double price,
    required String location,
    required String description,
    List<String>? images,
  }) async {
    final taskId = await createTask(
      ownerUserId: uid,
      officeId: officeId,
      sourceType: ImportSourceType.manual,
      platformId: 'manual',
      importMode: 'manual',
    );

    try {
      await updateTaskStatus(uid, taskId, status: ImportTaskStatus.processing, progress: 40);
      await Future<void>.delayed(const Duration(milliseconds: 400));

      final listing = _engine.manualListing(
        ownerUserId: uid,
        title: title,
        price: price,
        location: location,
        description: description,
        images: images,
        taskId: taskId,
      );

      await attachListingsToTask(uid, taskId, [listing]);
      await updateTaskStatus(
        uid,
        taskId,
        status: ImportTaskStatus.success,
        progress: 100,
        listingIds: [listing.id],
        completedAt: DateTime.now(),
      );
    } catch (e, _) {
      await updateTaskStatus(
        uid,
        taskId,
        status: ImportTaskStatus.failed,
        progress: 100,
        errorMessage: e.toString(),
        completedAt: DateTime.now(),
      );
    }
  }

  /// Bonus: aynı URL ile tekrar dene.
  Future<void> reimportUrl({
    required String uid,
    required String officeId,
    required String url,
    String importMode = 'skip_duplicates',
  }) {
    return runUrlImport(uid: uid, officeId: officeId, url: url, importMode: importMode);
  }
}
