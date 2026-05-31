import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_types.dart';

/// Önceden hesaplanmış yüzeyler üzerinde arama + filtre (build() içinde ucuz).
List<RaporEntryViewModel> filterRaporlarEntries(
  List<RaporEntryViewModel> source, {
  required String query,
  required RaporlarFilter filter,
}) {
  final q = query.trim().toLowerCase();
  return source
      .where((e) => _matchesSearch(e, q) && _matchesFilter(e, filter))
      .toList(growable: false);
}

bool _matchesSearch(RaporEntryViewModel e, String q) {
  if (q.isEmpty) return true;
  return e.searchText.contains(q);
}

bool _matchesFilter(RaporEntryViewModel e, RaporlarFilter filter) {
  return switch (filter) {
    RaporlarFilter.all => true,
    RaporlarFilter.kadro => e.kategori == RaporKategori.kadro,
    RaporlarFilter.ekip => e.kategori == RaporKategori.ekip,
    RaporlarFilter.audit => e.kategori == RaporKategori.audit,
    RaporlarFilter.uyelik => e.kategori == RaporKategori.uyelik,
    RaporlarFilter.ofis => e.kategori == RaporKategori.ofis,
    RaporlarFilter.baglanti => e.kategori == RaporKategori.baglanti,
    RaporlarFilter.intervention => e.needsAction,
    RaporlarFilter.ready => !e.needsAction,
  };
}
