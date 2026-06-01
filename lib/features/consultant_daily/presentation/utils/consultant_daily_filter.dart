import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_types.dart';

/// Saf istemci tarafı filtre — arama (önceden hesaplanmış searchText) + kategori.
List<ConsultantDailyEntry> filterConsultantDailyEntries(
  List<ConsultantDailyEntry> entries, {
  required String query,
  required ConsultantDailyFilter filter,
}) {
  final q = query.trim().toLowerCase();

  bool matchesCategory(ConsultantDailyEntry e) {
    switch (filter) {
      case ConsultantDailyFilter.all:
        return true;
      case ConsultantDailyFilter.task:
        return e.kind == DailyKind.task;
      case ConsultantDailyFilter.followUp:
        return e.kind == DailyKind.followUp;
      case ConsultantDailyFilter.customer:
        return e.kind == DailyKind.customer;
      case ConsultantDailyFilter.today:
        return e.isToday;
      case ConsultantDailyFilter.overdue:
        return e.isOverdue ||
            (e.kind == DailyKind.followUp && e.needsAttention);
      case ConsultantDailyFilter.priority:
        return e.isPriority;
      case ConsultantDailyFilter.partial:
        return e.isPartial;
    }
  }

  return entries
      .where((e) => matchesCategory(e) && (q.isEmpty || e.searchText.contains(q)))
      .toList(growable: false);
}
