import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/utils/ekipler_snapshot.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';

/// Ekip listesi filtreleri — yalnızca gerçek roster / yapı sinyalleri.
enum EkiplerTeamFilter {
  all,
  active,
  intervention,
  emptyOrPressure,
  unassigned,
  detailed,
  silent,
}

List<EkiplerTeamViewModel> filterEkiplerTeams({
  required List<EkiplerTeamViewModel> source,
  required String searchQuery,
  required EkiplerTeamFilter filter,
}) {
  if (filter == EkiplerTeamFilter.unassigned) {
    return const [];
  }

  var list = List<EkiplerTeamViewModel>.from(source);

  final q = searchQuery.trim().toLowerCase();
  if (q.isNotEmpty) {
    list = list.where((t) {
      final name = t.team.name.toLowerCase();
      final manager = (t.managerName ?? '').toLowerCase();
      return name.contains(q) || manager.contains(q);
    }).toList();
  }

  switch (filter) {
    case EkiplerTeamFilter.all:
    case EkiplerTeamFilter.detailed:
      break;
    case EkiplerTeamFilter.active:
      list = list.where((t) => t.stats.activeMembers > 0).toList();
    case EkiplerTeamFilter.intervention:
      list = list.where((t) => t.stats.needsIntervention).toList();
    case EkiplerTeamFilter.emptyOrPressure:
      list = list.where((t) => t.stats.hasEmptyOrPressure).toList();
    case EkiplerTeamFilter.silent:
      list = list
          .where((t) => t.stats.isEmpty || t.stats.allMembersInactive)
          .toList();
    case EkiplerTeamFilter.unassigned:
      break;
  }

  list.sort((a, b) {
    final aInt = a.stats.needsIntervention ? 0 : 1;
    final bInt = b.stats.needsIntervention ? 0 : 1;
    if (aInt != bInt) return aInt.compareTo(bInt);
    return a.team.name.toLowerCase().compareTo(b.team.name.toLowerCase());
  });

  return list;
}

List<UserDoc> filterUnassignedConsultants({
  required List<UserDoc> source,
  required String searchQuery,
}) {
  final base = source.where((u) {
    final tid = u.teamId;
    return tid == null || tid.isEmpty;
  }).toList();

  final q = searchQuery.trim().toLowerCase();
  if (q.isEmpty) return base;

  return base.where((u) {
    final name = (u.name ?? '').toLowerCase();
    final email = (u.email ?? '').toLowerCase();
    return name.contains(q) || email.contains(q);
  }).toList();
}
