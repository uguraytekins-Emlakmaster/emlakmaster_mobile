import 'package:emlakmaster_mobile/features/listing_import/data/listing_import_memory_store.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/listing_import_task_entity.dart';

/// Import görevleri — Phase 1.5 yerel mağaza (tek kaynak).
/// İleride Firestore ile birleştirmek için `watchRemoteTasks` eklenebilir.
class ListingImportRepository {
  ListingImportRepository._();
  static final ListingImportRepository instance = ListingImportRepository._();

  Stream<List<ListingImportTaskEntity>> streamForOwner(String uid) =>
      ListingImportMemoryStore.instance.watchTasks(uid);

  List<ListingImportTaskEntity> getTaskHistory(String uid) =>
      ListingImportMemoryStore.instance.tasksSnapshot(uid);
}
