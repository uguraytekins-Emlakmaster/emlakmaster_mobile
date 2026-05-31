import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/utils/baglantilar_types.dart';

/// Önceden hesaplanmış satırlar üzerinde arama + filtre — build() içinde ucuz.
List<BaglantiRowViewModel> filterBaglantilarRows(
  List<BaglantiRowViewModel> source, {
  required String query,
  required BaglantilarFilter filter,
}) {
  final q = query.trim().toLowerCase();
  return source
      .where((r) => _matchesSearch(r, q) && _matchesFilter(r, filter))
      .toList(growable: false);
}

bool _matchesSearch(BaglantiRowViewModel r, String q) {
  if (q.isEmpty) return true;
  return r.searchText.contains(q);
}

bool _matchesFilter(BaglantiRowViewModel r, BaglantilarFilter filter) {
  return switch (filter) {
    BaglantilarFilter.all => true,
    BaglantilarFilter.connected => r.isConnected,
    BaglantilarFilter.ready => r.isReady,
    BaglantilarFilter.setup => r.needsSetup,
    BaglantilarFilter.preview => r.isPreview,
    BaglantilarFilter.admin => r.needsAdmin,
    BaglantilarFilter.sync => r.supportsSync,
    BaglantilarFilter.intervention => r.needsAction,
  };
}
