import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/utils/uyelikler_types.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/office/domain/membership_status.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_invite_entity.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_membership_entity.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_role.dart';
import 'package:intl/intl.dart';

final _dateFormatter = DateFormat('d MMM yyyy', 'tr_TR');

String formatUyelikTimestamp(DateTime? at, DateTime now) {
  if (at == null) return 'Zaman bilinmiyor';
  final diff = now.difference(at);
  if (diff.isNegative) {
    // Gelecek (örn. son geçerlilik) — gün cinsinden.
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

UyeliklerPageSnapshot computeUyeliklerSnapshot({
  required List<OfficeInvite> invites,
  required List<OfficeMembership> members,
  required List<UserDoc> directory,
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

  final rows = <UyelikRowViewModel>[];

  for (final m in members) {
    rows.add(_rowFromMember(
      m,
      nameByUid: nameByUid,
      emailByUid: emailByUid,
      currentUid: currentUid,
      actorRole: actorRole,
      now: now,
    ));
  }
  for (final inv in invites) {
    rows.add(_rowFromInvite(inv, nameByUid: nameByUid, now: now));
  }

  // Sıralama: önce müdahale gerekenler, sonra zaman (yeni → eski, null en sonda).
  rows.sort((a, b) {
    if (a.needsAction != b.needsAction) {
      return a.needsAction ? -1 : 1;
    }
    final aAt = a.occurredAt;
    final bAt = b.occurredAt;
    if (aAt == null && bAt == null) return 0;
    if (aAt == null) return 1;
    if (bAt == null) return -1;
    return bAt.compareTo(aAt);
  });

  var pending = 0;
  var accepted = 0;
  var expired = 0;
  var activeMembers = 0;
  var intervention = 0;

  for (final inv in invites) {
    final usable = inv.isActive && !inv.isExpired && !inv.isExhausted;
    if (usable && inv.usedCount == 0) pending++;
    if (inv.usedCount > 0) accepted++;
    if (!inv.isActive || inv.isExpired || inv.isExhausted) expired++;
  }
  for (final m in members) {
    switch (m.status) {
      case MembershipStatus.active:
        activeMembers++;
      case MembershipStatus.suspended:
      case MembershipStatus.removed:
        intervention++;
      case MembershipStatus.invited:
        break;
    }
  }

  final hasInvites = invites.isNotEmpty;
  final hasMembers = members.isNotEmpty;

  return UyeliklerPageSnapshot(
    rows: rows,
    strip: UyeliklerSummaryStrip(
      pendingInvites: pending,
      acceptedInvites: accepted,
      expiredInvites: expired,
      activeMembers: activeMembers,
      interventionCount: intervention,
      totalMembers: members.length,
      totalInvites: invites.length,
    ),
    isEmpty: rows.isEmpty,
    hasInvites: hasInvites,
    hasMembers: hasMembers,
    coverageNote: _coverageNote(hasInvites: hasInvites, hasMembers: hasMembers),
  );
}

String _coverageNote({required bool hasInvites, required bool hasMembers}) {
  if (!hasInvites && !hasMembers) {
    return 'Henüz davet veya üyelik kaydı yok. Davet oluşturdukça ofis kadrosu burada görünecek.';
  }
  const base =
      'Yalnızca gerçek davet ve üyelik kayıtları gösterilir. Onboarding ilerlemesi cihaz-yereldir; sunucuda izlenmediği için burada gösterilmez.';
  if (!hasMembers) {
    return 'Kapsam: yalnızca davet kayıtları. Henüz tamamlanmış üyelik yok. $base';
  }
  if (!hasInvites) {
    return 'Kapsam: yalnızca üyelik kayıtları. Açık davet yok. $base';
  }
  return base;
}

UyelikRowViewModel _rowFromMember(
  OfficeMembership m, {
  required Map<String, String> nameByUid,
  required Map<String, String> emailByUid,
  required String? currentUid,
  required OfficeRole? actorRole,
  required DateTime now,
}) {
  final isSelf = currentUid != null && m.userId == currentUid;
  final resolvedName = nameByUid[m.userId];
  final title = isSelf
      ? 'Siz'
      : (resolvedName ?? _shortenUid(m.userId));
  final hasName = resolvedName != null;

  final (durum, statusLabel, tone, needsAction) = switch (m.status) {
    MembershipStatus.active => (
        UyelikDurum.active,
        'Aktif üye',
        UyelikTone.success,
        false,
      ),
    MembershipStatus.suspended => (
        UyelikDurum.suspended,
        'Askıda',
        UyelikTone.warning,
        true,
      ),
    MembershipStatus.removed => (
        UyelikDurum.removed,
        'Kaldırıldı',
        UyelikTone.danger,
        false,
      ),
    MembershipStatus.invited => (
        UyelikDurum.invited,
        'Davetli',
        UyelikTone.info,
        false,
      ),
  };

  final isOwner = m.role == OfficeRole.owner;
  final canModerateBase = !isSelf && !isOwner && actorRole != null;
  final canSuspend = canModerateBase && m.status == MembershipStatus.active;
  // Manager yalnızca consultant kaldırabilir (OfficeAdminService kuralı).
  final canRemove = canModerateBase &&
      m.status != MembershipStatus.removed &&
      !(actorRole == OfficeRole.manager && m.role != OfficeRole.consultant);

  final email = emailByUid[m.userId];
  final detailLine = !hasName && email != null && email.isNotEmpty
      ? email
      : (email != null && email.isNotEmpty ? email : '');

  final partial = !hasName || m.joinedAt == null;

  final joinLabel = m.joinedAt != null
      ? '${formatUyelikTimestamp(m.joinedAt, now)} katıldı'
      : 'Katılım zamanı bilinmiyor';

  return UyelikRowViewModel(
    id: 'member:${m.id}',
    kind: UyelikKind.member,
    title: title,
    subtitle: '${_officeRoleLabel(m.role)} · Üyelik',
    detailLine: detailLine,
    statusLabel: statusLabel,
    durum: durum,
    tone: tone,
    timestampLabel: joinLabel,
    occurredAt: m.joinedAt,
    needsAction: needsAction,
    hasPartialMetadata: partial,
    memberUserId: m.userId,
    isSelf: isSelf,
    canModerate: canModerateBase,
    canSuspend: canSuspend,
    canRemove: canRemove,
  );
}

UyelikRowViewModel _rowFromInvite(
  OfficeInvite inv, {
  required Map<String, String> nameByUid,
  required DateTime now,
}) {
  final creator = nameByUid[inv.createdBy] ??
      (inv.createdBy.isNotEmpty ? _shortenUid(inv.createdBy) : 'Yönetici');

  final UyelikDurum durum;
  final String statusLabel;
  final UyelikTone tone;
  var needsAction = false;

  if (!inv.isActive) {
    durum = UyelikDurum.closed;
    statusLabel = 'Pasif';
    tone = UyelikTone.neutral;
  } else if (inv.isExpired) {
    durum = UyelikDurum.expired;
    statusLabel = 'Süresi doldu';
    tone = UyelikTone.warning;
    needsAction = true;
  } else if (inv.isExhausted) {
    durum = UyelikDurum.accepted;
    statusLabel = 'Kontenjan doldu';
    tone = UyelikTone.warning;
    needsAction = true;
  } else if (inv.usedCount > 0) {
    durum = UyelikDurum.partiallyUsed;
    statusLabel = 'Kısmi kullanım';
    tone = UyelikTone.success;
  } else {
    durum = UyelikDurum.pending;
    statusLabel = 'Bekliyor';
    tone = UyelikTone.info;
  }

  final detailParts = <String>[
    '${inv.usedCount}/${inv.maxUses} kullanım',
    if (inv.expiresAt != null)
      'Son: ${_dateFormatter.format(inv.expiresAt!)}',
  ];

  final timestampLabel = inv.createdAt != null
      ? '${formatUyelikTimestamp(inv.createdAt, now)} oluşturuldu'
      : (inv.expiresAt != null
          ? formatUyelikTimestamp(inv.expiresAt, now)
          : 'Zaman bilgisi yok');

  return UyelikRowViewModel(
    id: 'invite:${inv.id}',
    kind: UyelikKind.invite,
    title: 'Davet kodu · ${inv.code}',
    subtitle: '${_officeRoleLabel(inv.roleToAssign)} daveti · $creator',
    detailLine: detailParts.join(' · '),
    statusLabel: statusLabel,
    durum: durum,
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
