import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/providers/super_admin_gate_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Komuta merkezi filtre çubuğu — ekip listesi.
final commandCenterTeamsProvider =
    StreamProvider.autoDispose<List<TeamDoc>>((ref) {
  return FirestoreService.teamsStream();
});

/// Danışman id listesi + görünen adlar (filtre dropdown).
class CommandCenterAgentsFilterData {
  const CommandCenterAgentsFilterData({
    required this.agentIds,
    required this.agentNames,
  });

  final List<String> agentIds;
  final Map<String, String> agentNames;

  static const empty = CommandCenterAgentsFilterData(
    agentIds: [],
    agentNames: {},
  );
}

final commandCenterAgentsFilterProvider =
    StreamProvider.autoDispose<CommandCenterAgentsFilterData>((ref) {
  return FirestoreService.agentsStream().map((snap) {
    if (snap.docs.isEmpty) return CommandCenterAgentsFilterData.empty;
    return CommandCenterAgentsFilterData(
      agentIds: snap.docs.map((d) => d.id).toList(),
      agentNames: {
        for (final d in snap.docs)
          d.id: d.data()['displayName'] as String? ?? d.id,
      },
    );
  });
});

/// Komuta merkezi çağrı akışı kapsamı.
enum CommandCenterCallsScope {
  all,
  pending,
}

final commandCenterAgentNamesProvider =
    StreamProvider.autoDispose<Map<String, String>>((ref) {
  return FirestoreService.agentsStream().map((snap) {
    return {
      for (final d in snap.docs)
        d.id: d.data()['displayName'] as String? ?? d.id,
    };
  });
});

/// Komuta merkezi çağrı görünürlüğü kapsamı.
///
/// [allOffices] yalnızca gerçek super_admin + açık kapı ile true olur; o zaman
/// filtresiz (tüm ofisler) sorgu kullanılır. Aksi halde [officeId]'ye göre
/// kendi ofisi sorgulanır.
class CommandCenterCallsAudience {
  const CommandCenterCallsAudience({
    required this.allOffices,
    required this.officeId,
  });

  final bool allOffices;
  final String officeId;

  /// Ofis görünümü çalışabilir mi? (super admin tüm ofisler ya da geçerli officeId)
  bool get hasContext => allOffices || officeId.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is CommandCenterCallsAudience &&
      other.allOffices == allOffices &&
      other.officeId == officeId;

  @override
  int get hashCode => Object.hash(allOffices, officeId);
}

/// Aktif çağrı görünürlüğü: gerçek super_admin + açık kapı → tüm ofisler;
/// aksi halde kullanıcının `users.officeId`'sine göre kendi ofisi.
final commandCenterCallsAudienceProvider =
    Provider.autoDispose<CommandCenterCallsAudience>((ref) {
  final uid =
      ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid)) ?? '';
  final isSuper = ref.watch(isSuperAdminProvider);
  final gateOpen = ref.watch(superAdminAllOfficesGateProvider);
  final officeId = uid.isEmpty
      ? ''
      : ref.watch(
          userDocStreamProvider(uid)
              .select((a) => (a.valueOrNull?.officeId ?? '').trim()),
        );
  return CommandCenterCallsAudience(
    allOffices: isSuper && gateOpen,
    officeId: officeId,
  );
});

final commandCenterCallsStreamProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, CommandCenterCallsScope>(
        (ref, scope) {
  final audience = ref.watch(commandCenterCallsAudienceProvider);
  if (audience.allOffices) {
    switch (scope) {
      case CommandCenterCallsScope.pending:
        return FirestoreService.callsHandoffPendingStream();
      case CommandCenterCallsScope.all:
        return FirestoreService.callsStream();
    }
  }
  final oid = audience.officeId;
  if (oid.isEmpty) {
    // Ofis bağlamı yok → dürüst boş (sahte global sorgu yapma).
    return const Stream.empty();
  }
  switch (scope) {
    case CommandCenterCallsScope.pending:
      return FirestoreService.callsHandoffPendingByOfficeStream(oid);
    case CommandCenterCallsScope.all:
      return FirestoreService.callsByOfficeStream(oid);
  }
});
