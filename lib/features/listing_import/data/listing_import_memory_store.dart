import 'dart:async';

import 'package:emlakmaster_mobile/features/listing_import/domain/listing_entity.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/listing_import_task_entity.dart';

/// Yerel tek kaynak (Phase 1.5); ileride Firestore ile senkronlanabilir.
final class ListingImportMemoryStore {
  ListingImportMemoryStore._();
  static final ListingImportMemoryStore instance = ListingImportMemoryStore._();

  final Map<String, List<ListingImportTaskEntity>> _tasksByUser = {};
  final Map<String, List<ListingEntity>> _listingsByUser = {};
  final Map<String, StreamController<List<ListingImportTaskEntity>>> _taskStreams = {};
  final Map<String, StreamController<List<ListingEntity>>> _listingStreams = {};

  List<ListingImportTaskEntity> tasksSnapshot(String uid) =>
      List<ListingImportTaskEntity>.from(_tasksByUser[uid] ?? const []);

  List<ListingEntity> listingsSnapshot(String uid) =>
      List<ListingEntity>.from(_listingsByUser[uid] ?? const []);

  Stream<List<ListingImportTaskEntity>> watchTasks(String uid) {
    _tasksByUser.putIfAbsent(uid, () => []);
    final c = _taskStreams.putIfAbsent(uid, () {
      final ctrl = StreamController<List<ListingImportTaskEntity>>.broadcast();
      scheduleMicrotask(() => ctrl.add(tasksSnapshot(uid)));
      return ctrl;
    });
    scheduleMicrotask(() => c.add(tasksSnapshot(uid)));
    return c.stream;
  }

  Stream<List<ListingEntity>> watchListings(String uid) {
    _listingsByUser.putIfAbsent(uid, () => []);
    _listingStreams.putIfAbsent(uid, () {
      final ctrl = StreamController<List<ListingEntity>>.broadcast();
      scheduleMicrotask(() => ctrl.add(listingsSnapshot(uid)));
      return ctrl;
    });
    scheduleMicrotask(() => _listingStreams[uid]!.add(listingsSnapshot(uid)));
    return _listingStreams[uid]!.stream;
  }

  void _emitTasks(String uid) {
    _taskStreams[uid]?.add(tasksSnapshot(uid));
  }

  void _emitListings(String uid) {
    _listingStreams[uid]?.add(listingsSnapshot(uid));
  }

  void upsertTask(String uid, ListingImportTaskEntity task) {
    final list = _tasksByUser.putIfAbsent(uid, () => []);
    final i = list.indexWhere((t) => t.id == task.id);
    if (i >= 0) {
      list[i] = task;
    } else {
      list.insert(0, task);
    }
    _emitTasks(uid);
  }

  void upsertListing(String uid, ListingEntity listing) {
    final list = _listingsByUser.putIfAbsent(uid, () => []);
    final i = list.indexWhere((l) => l.id == listing.id);
    if (i >= 0) {
      list[i] = listing;
    } else {
      list.insert(0, listing);
    }
    _emitListings(uid);
  }

  void removeListing(String uid, String listingId) {
    final list = _listingsByUser[uid];
    if (list == null) return;
    list.removeWhere((l) => l.id == listingId);
    _emitListings(uid);
  }
}
