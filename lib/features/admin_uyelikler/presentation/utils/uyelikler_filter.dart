import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/utils/uyelikler_types.dart';

List<UyelikRowViewModel> filterUyeliklerRows({
  required List<UyelikRowViewModel> source,
  required String searchQuery,
  required UyeliklerFilter filter,
  required DateTime now,
}) {
  var list = List<UyelikRowViewModel>.from(source);

  final q = searchQuery.trim().toLowerCase();
  if (q.isNotEmpty) {
    list = list.where((row) {
      final haystack = [
        row.title,
        row.subtitle,
        row.detailLine,
        row.statusLabel,
        row.inviteCode ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  switch (filter) {
    case UyeliklerFilter.all:
      break;
    case UyeliklerFilter.pending:
      list = list.where((r) => r.durum == UyelikDurum.pending).toList();
    case UyeliklerFilter.accepted:
      list = list
          .where((r) =>
              r.durum == UyelikDurum.accepted ||
              r.durum == UyelikDurum.partiallyUsed)
          .toList();
    case UyeliklerFilter.expired:
      list = list
          .where((r) =>
              r.durum == UyelikDurum.expired || r.durum == UyelikDurum.closed)
          .toList();
    case UyeliklerFilter.intervention:
      list = list.where((r) => r.needsAction).toList();
    case UyeliklerFilter.members:
      list = list.where((r) => r.kind == UyelikKind.member).toList();
    case UyeliklerFilter.invite:
      list = list.where((r) => r.kind == UyelikKind.invite).toList();
    case UyeliklerFilter.last7d:
      final cutoff = now.subtract(const Duration(days: 7));
      list = list
          .where((r) => r.occurredAt != null && r.occurredAt!.isAfter(cutoff))
          .toList();
  }

  return list;
}
