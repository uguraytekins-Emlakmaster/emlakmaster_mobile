import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/utils/ofis_masasi_types.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/external_integrations/application/platform_setup_lifecycle_logic.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_setup_lifecycle.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_setup_record.dart';
import 'package:emlakmaster_mobile/features/office/domain/membership_status.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_invite_entity.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_membership_entity.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_role.dart';
import 'package:intl/intl.dart';

final _dateFormatter = DateFormat('d MMM yyyy', 'tr_TR');

String formatOfisTimestamp(DateTime? at, DateTime now) {
  if (at == null) return 'Zaman bilinmiyor';
  final diff = now.difference(at);
  if (diff.isNegative) {
    final days = at.difference(now).inDays;
    if (days <= 0) return 'Bugün doluyor';
    return '$days gün kaldı';
  }
  if (diff.inMinutes < 1) return 'Az önce';
  if (diff.inHours < 24) {
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return '${h > 0 ? '$h sa ' : ''}$m dk önce';
  }
  if (diff.inDays < 7) return '${diff.inDays} gün önce';
  return _dateFormatter.format(at);
}

/// Tek türetilmiş anlık görüntü. [setups] null ise platform kurulum verisi
/// henüz bilinmiyor (yükleniyor/hata) — bağlantı metrikleri dürüstçe gizlenir.
OfisMasasiSnapshot computeOfisMasasiSnapshot({
  required List<OfficeInvite> invites,
  required List<OfficeMembership> members,
  required List<UserDoc> directory,
  required Map<IntegrationPlatformId, PlatformSetupRecord>? setups,
  required String? currentUid,
  required OfficeRole? actorRole,
  required DateTime now,
}) {
  final nameByUid = <String, String>{};
  final emailByUid = <String, String>{};
  for (final u in directory) {
    final label = u.name?.trim();
    if (label != null && label.isNotEmpty) {
      nameByUid[u.uid] = label;
    } else if (u.email != null && u.email!.isNotEmpty) {
      nameByUid[u.uid] = u.email!;
    }
    if (u.email != null && u.email!.isNotEmpty) {
      emailByUid[u.uid] = u.email!;
    }
  }

  // ——— Üyeler ———
  final memberRows = <OfisRowViewModel>[];
  var activeMembers = 0;
  var suspendedMembers = 0;
  var memberIntervention = 0;
  for (final m in members) {
    memberRows.add(_rowFromMember(
      m,
      nameByUid: nameByUid,
      emailByUid: emailByUid,
      currentUid: currentUid,
      actorRole: actorRole,
      now: now,
    ));
    switch (m.status) {
      case MembershipStatus.active:
        activeMembers++;
      case MembershipStatus.suspended:
        suspendedMembers++;
        memberIntervention++;
      case MembershipStatus.removed:
      case MembershipStatus.invited:
        break;
    }
  }
  memberRows.sort(_byInterventionThenRecency);

  // ——— Davetler ———
  final inviteRows = <OfisRowViewModel>[];
  var pendingInvites = 0;
  var inviteIntervention = 0;
  for (final inv in invites) {
    inviteRows.add(_rowFromInvite(inv, nameByUid: nameByUid, now: now));
    final usable = inv.isActive && !inv.isExpired && !inv.isExhausted;
    if (usable && inv.usedCount == 0) pendingInvites++;
    if (inv.isActive && (inv.isExpired || inv.isExhausted)) inviteIntervention++;
  }
  inviteRows.sort(_byInterventionThenRecency);

  // ——— Bağlantılar (gerçek kurulum kaydı: offices/{id}/platform_setups) ———
  final connectionRows = <OfisRowViewModel>[];
  var connectionsReady = 0;
  var connectionsNeedingSetup = 0;
  var connectionIntervention = 0;
  final connectionsKnown = setups != null;
  if (connectionsKnown) {
    for (final pid in IntegrationPlatformId.values) {
      final record = setups[pid];
      final lifecycle = record != null
          ? deriveLifecycleState(record)
          : PlatformSetupLifecycleState.notStarted;
      final ready = lifecycle == PlatformSetupLifecycleState.readyForImport ||
          lifecycle == PlatformSetupLifecycleState.liveEnabled;
      if (ready) {
        connectionsReady++;
      } else {
        connectionsNeedingSetup++;
      }
      final attention = lifecycle.countsAsAttentionForDashboard ||
          lifecycle == PlatformSetupLifecycleState.blocked;
      if (attention) connectionIntervention++;
      connectionRows.add(_rowFromConnection(
        pid: pid,
        record: record,
        lifecycle: lifecycle,
        now: now,
      ));
    }
    connectionRows.sort(_byInterventionThenRecency);
  }

  final hasInvites = invites.isNotEmpty;
  final hasMembers = members.isNotEmpty;
  final intervention =
      memberIntervention + inviteIntervention + connectionIntervention;

  return OfisMasasiSnapshot(
    members: memberRows,
    invites: inviteRows,
    connections: connectionRows,
    summary: OfisMasasiSummary(
      activeMembers: activeMembers,
      pendingInvites: pendingInvites,
      suspendedMembers: suspendedMembers,
      connectionsReady: connectionsReady,
      connectionsNeedingSetup: connectionsNeedingSetup,
      interventionCount: intervention,
      totalMembers: members.length,
      totalInvites: invites.length,
      totalConnections: connectionsKnown ? connectionRows.length : 0,
      connectionsKnown: connectionsKnown,
    ),
    coverageNote: _coverageNote(hasInvites: hasInvites, hasMembers: hasMembers),
    connectionsNote: connectionsKnown
        ? 'Canlı OAuth/otomatik senkron devrede değil; yalnızca ofis kurulum durumu gösterilir.'
        : 'Bağlantı kurulum verisi yükleniyor; hazır olduğunda gerçek durum görünecek.',
    connectionsKnown: connectionsKnown,
    isEmpty: !hasMembers && !hasInvites,
  );
}

int _byInterventionThenRecency(OfisRowViewModel a, OfisRowViewModel b) {
  if (a.needsAction != b.needsAction) {
    return a.needsAction ? -1 : 1;
  }
  final aAt = a.occurredAt;
  final bAt = b.occurredAt;
  if (aAt == null && bAt == null) return 0;
  if (aAt == null) return 1;
  if (bAt == null) return -1;
  return bAt.compareTo(aAt);
}

String _coverageNote({required bool hasInvites, required bool hasMembers}) {
  const base =
      'Yalnızca gerçek ofis verisi gösterilir: üyeler, davetler ve platform kurulum kayıtları. '
      'Canlı senkron ve onboarding ilerlemesi sunucuda izlenmediği için iddia edilmez.';
  if (!hasInvites && !hasMembers) {
    return 'Henüz üye veya davet kaydı yok. Davet oluşturdukça ofis kadrosu burada görünecek. $base';
  }
  if (!hasMembers) {
    return 'Kapsam: davet kayıtları var, henüz tamamlanmış üyelik yok. $base';
  }
  if (!hasInvites) {
    return 'Kapsam: üyelik kayıtları var, açık davet yok. $base';
  }
  return base;
}

OfisRowViewModel _rowFromMember(
  OfficeMembership m, {
  required Map<String, String> nameByUid,
  required Map<String, String> emailByUid,
  required String? currentUid,
  required OfficeRole? actorRole,
  required DateTime now,
}) {
  final isSelf = currentUid != null && m.userId == currentUid;
  final resolvedName = nameByUid[m.userId];
  final title = isSelf ? 'Siz' : (resolvedName ?? _shortenUid(m.userId));
  final hasName = resolvedName != null;

  final (statusLabel, tone, needsAction) = switch (m.status) {
    MembershipStatus.active => ('Aktif üye', OfisTone.success, false),
    MembershipStatus.suspended => ('Askıda', OfisTone.warning, true),
    MembershipStatus.removed => ('Kaldırıldı', OfisTone.danger, false),
    MembershipStatus.invited => ('Davetli', OfisTone.info, false),
  };

  final isOwner = m.role == OfficeRole.owner;
  final canModerateBase = !isSelf && !isOwner && actorRole != null;
  final canSuspend = canModerateBase && m.status == MembershipStatus.active;
  final canRemove = canModerateBase &&
      m.status != MembershipStatus.removed &&
      !(actorRole == OfficeRole.manager && m.role != OfficeRole.consultant);

  final email = emailByUid[m.userId];
  final detailLine = email ?? '';
  final partial = !hasName || m.joinedAt == null;
  final joinLabel = m.joinedAt != null
      ? '${formatOfisTimestamp(m.joinedAt, now)} katıldı'
      : 'Katılım zamanı bilinmiyor';

  return OfisRowViewModel(
    id: 'member:${m.id}',
    kind: OfisRowKind.member,
    title: title,
    subtitle: '${_officeRoleLabel(m.role)} · Üyelik',
    detailLine: detailLine,
    statusLabel: statusLabel,
    tone: tone,
    timestampLabel: joinLabel,
    occurredAt: m.joinedAt,
    needsAction: needsAction,
    hasPartialMetadata: partial,
    memberUserId: m.userId,
    isSelf: isSelf,
    canSuspend: canSuspend,
    canRemove: canRemove,
  );
}

OfisRowViewModel _rowFromInvite(
  OfficeInvite inv, {
  required Map<String, String> nameByUid,
  required DateTime now,
}) {
  final creator = nameByUid[inv.createdBy] ??
      (inv.createdBy.isNotEmpty ? _shortenUid(inv.createdBy) : 'Yönetici');

  final String statusLabel;
  final OfisTone tone;
  var needsAction = false;

  if (!inv.isActive) {
    statusLabel = 'Pasif';
    tone = OfisTone.neutral;
  } else if (inv.isExpired) {
    statusLabel = 'Süresi doldu';
    tone = OfisTone.warning;
    needsAction = true;
  } else if (inv.isExhausted) {
    statusLabel = 'Kontenjan doldu';
    tone = OfisTone.warning;
    needsAction = true;
  } else if (inv.usedCount > 0) {
    statusLabel = 'Kısmi kullanım';
    tone = OfisTone.success;
  } else {
    statusLabel = 'Bekliyor';
    tone = OfisTone.info;
  }

  final detailParts = <String>[
    '${inv.usedCount}/${inv.maxUses} kullanım',
    if (inv.expiresAt != null) 'Son: ${_dateFormatter.format(inv.expiresAt!)}',
  ];

  final timestampLabel = inv.createdAt != null
      ? '${formatOfisTimestamp(inv.createdAt, now)} oluşturuldu'
      : (inv.expiresAt != null
          ? formatOfisTimestamp(inv.expiresAt, now)
          : 'Zaman bilgisi yok');

  return OfisRowViewModel(
    id: 'invite:${inv.id}',
    kind: OfisRowKind.invite,
    title: 'Davet kodu · ${inv.code}',
    subtitle: '${_officeRoleLabel(inv.roleToAssign)} daveti · $creator',
    detailLine: detailParts.join(' · '),
    statusLabel: statusLabel,
    tone: tone,
    timestampLabel: timestampLabel,
    occurredAt: inv.createdAt ?? inv.expiresAt,
    needsAction: needsAction,
    hasPartialMetadata: inv.createdAt == null,
    inviteId: inv.id,
    inviteCode: inv.code,
    isActiveInvite: inv.isActive,
  );
}

OfisRowViewModel _rowFromConnection({
  required IntegrationPlatformId pid,
  required PlatformSetupRecord? record,
  required PlatformSetupLifecycleState lifecycle,
  required DateTime now,
}) {
  final tone = switch (lifecycle) {
    PlatformSetupLifecycleState.liveEnabled => OfisTone.success,
    PlatformSetupLifecycleState.readyForImport => OfisTone.success,
    PlatformSetupLifecycleState.draft => OfisTone.info,
    PlatformSetupLifecycleState.notStarted => OfisTone.neutral,
    PlatformSetupLifecycleState.incomplete => OfisTone.warning,
    PlatformSetupLifecycleState.awaitingVerification => OfisTone.warning,
    PlatformSetupLifecycleState.officialPartnerPending => OfisTone.warning,
    PlatformSetupLifecycleState.blocked => OfisTone.danger,
    PlatformSetupLifecycleState.error => OfisTone.danger,
  };
  final needsAction = lifecycle.countsAsAttentionForDashboard ||
      lifecycle == PlatformSetupLifecycleState.blocked;

  final storeName = record?.storeName?.trim();
  final subtitleParts = <String>[
    lifecycle.cardSubtitleTr,
    if (storeName != null && storeName.isNotEmpty) storeName,
  ];

  final updatedAt = record?.updatedAt;
  final timestampLabel = record == null
      ? 'Kurulum kaydı yok'
      : '${formatOfisTimestamp(updatedAt, now)} güncellendi';

  return OfisRowViewModel(
    id: 'connection:${pid.storageKey}',
    kind: OfisRowKind.connection,
    title: pid.displayName,
    subtitle: subtitleParts.join(' · '),
    detailLine: '',
    statusLabel: lifecycle.chipLabelTr,
    tone: tone,
    timestampLabel: timestampLabel,
    occurredAt: updatedAt,
    needsAction: needsAction,
    hasPartialMetadata: record == null,
    connectionPlatformKey: pid.storageKey,
    connectionConfigured: record != null,
  );
}

String _officeRoleLabel(OfficeRole role) {
  return switch (role) {
    OfficeRole.owner => 'Ofis sahibi',
    OfficeRole.admin => 'Yönetici',
    OfficeRole.manager => 'Müdür',
    OfficeRole.consultant => 'Danışman',
  };
}

String _shortenUid(String uid) {
  if (uid.isEmpty) return 'Bilinmeyen';
  if (uid.length <= 10) return uid;
  return '${uid.substring(0, 6)}…${uid.substring(uid.length - 4)}';
}
