import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/utils/islem_kayitlari_types.dart';

List<IslemKayitlariRowViewModel> filterIslemKayitlariRows({
  required List<IslemKayitlariRowViewModel> source,
  required String searchQuery,
  required IslemKayitlariFilter filter,
  required DateTime now,
}) {
  var list = List<IslemKayitlariRowViewModel>.from(source);

  final q = searchQuery.trim().toLowerCase();
  if (q.isNotEmpty) {
    list = list.where((row) {
      final haystack = [
        row.title,
        row.actorLine,
        row.targetLine,
        row.detailLine,
        row.categoryLabel,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  switch (filter) {
    case IslemKayitlariFilter.all:
      break;
    case IslemKayitlariFilter.consultant:
      list = list
          .where((r) => r.category == IslemKayitlariCategory.consultant)
          .toList();
    case IslemKayitlariFilter.team:
      list =
          list.where((r) => r.category == IslemKayitlariCategory.team).toList();
    case IslemKayitlariFilter.invite:
      list = list
          .where((r) => r.category == IslemKayitlariCategory.invite)
          .toList();
    case IslemKayitlariFilter.role:
      list =
          list.where((r) => r.category == IslemKayitlariCategory.role).toList();
    case IslemKayitlariFilter.assignment:
      list = list
          .where((r) => r.category == IslemKayitlariCategory.assignment)
          .toList();
    case IslemKayitlariFilter.warning:
      list = list
          .where(
            (r) =>
                r.severity == IslemKayitlariSeverity.warning ||
                r.severity == IslemKayitlariSeverity.critical,
          )
          .toList();
    case IslemKayitlariFilter.last24h:
      final cutoff = now.subtract(const Duration(hours: 24));
      list = list
          .where((r) => r.occurredAt != null && r.occurredAt!.isAfter(cutoff))
          .toList();
    case IslemKayitlariFilter.critical:
      list = list
          .where((r) => r.severity == IslemKayitlariSeverity.critical)
          .toList();
  }

  return list;
}
