import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/utils/ofis_masasi_types.dart';

/// Hafif istemci-içi arama: isim, kod, rol, durum ve platform üzerinde eşleşir.
/// Boş sorguda kaynak liste aynen döner (kopya gerekmez).
List<OfisRowViewModel> filterOfisMasasiRows({
  required List<OfisRowViewModel> source,
  required String query,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return source;
  return source.where((r) {
    return r.title.toLowerCase().contains(q) ||
        r.subtitle.toLowerCase().contains(q) ||
        r.detailLine.toLowerCase().contains(q) ||
        r.statusLabel.toLowerCase().contains(q) ||
        (r.inviteCode?.toLowerCase().contains(q) ?? false);
  }).toList(growable: false);
}
