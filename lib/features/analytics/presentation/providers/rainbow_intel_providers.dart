import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/intel_report_history_repository.dart';
import '../../data/rainbow_intel_service.dart';
import '../../domain/models/rainbow_intel_models.dart';

final rainbowIntelServiceProvider = Provider<RainbowIntelService>((ref) {
  return RainbowIntelService();
});

final intelReportHistoryRepositoryProvider =
    Provider<IntelReportHistoryRepository>((ref) {
  return ref.watch(rainbowIntelServiceProvider).history;
});

final intelReportHistoryListProvider =
    FutureProvider<List<RainbowIntelReport>>((ref) async {
  final repo = ref.watch(intelReportHistoryRepositoryProvider);
  return repo.loadAll();
});
