import 'package:emlakmaster_mobile/features/listing_import/data/listing_import_repository.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/listing_import_task_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

final listingImportTasksProvider = StreamProvider<List<ListingImportTaskEntity>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream.value(const []);
  }
  return ListingImportRepository.instance.streamForOwner(uid);
});
