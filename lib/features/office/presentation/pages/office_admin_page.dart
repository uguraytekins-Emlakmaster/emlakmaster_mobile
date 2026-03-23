import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/office/domain/membership_status.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_invite_entity.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_membership_entity.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_role.dart';
import 'package:emlakmaster_mobile/features/office/presentation/providers/office_admin_providers.dart';
import 'package:emlakmaster_mobile/features/office/presentation/utils/office_error_ui.dart';
import 'package:emlakmaster_mobile/features/office/services/office_admin_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Ofis yönetimi — üyeler, davetler, temel kontroller (Phase 1.3).
class OfficeAdminPage extends ConsumerWidget {
  const OfficeAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final doc = user != null ? ref.watch(userDocStreamProvider(user.uid)).valueOrNull : null;
    final oid = doc?.officeId;
    final mem = ref.watch(primaryMembershipProvider).valueOrNull;
    final canAdmin = mem != null &&
        mem.status == MembershipStatus.active &&
        (mem.role == OfficeRole.owner ||
            mem.role == OfficeRole.admin ||
            mem.role == OfficeRole.manager);

    if (oid == null || oid.isEmpty) {
      return Scaffold(
        backgroundColor: ext.background,
        appBar: AppBar(title: const Text('Ofis yönetimi'), backgroundColor: ext.background),
        body: Center(
          child: Text('Önce bir ofise bağlanın.', style: TextStyle(color: ext.foregroundSecondary)),
        ),
      );
    }

    if (!canAdmin) {
      return Scaffold(
        backgroundColor: ext.background,
        appBar: AppBar(title: const Text('Ofis yönetimi'), backgroundColor: ext.background),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Bu sayfa yalnızca ofis sahibi, yönetici veya ekip lideri içindir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ext.foregroundSecondary, fontSize: 15),
            ),
          ),
        ),
      );
    }

    final membersAsync = ref.watch(officeMembersStreamProvider(oid));
    final invitesAsync = ref.watch(officeInvitesStreamProvider(oid));

    return Scaffold(
      backgroundColor: ext.background,
      appBar: AppBar(
        backgroundColor: ext.background,
        title: const Text('Ofis yönetimi'),
        actions: [
          IconButton(
            tooltip: 'Davet oluştur',
            onPressed: () => context.push(AppRouter.routeOfficeInviteCreate),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          Text(
            'Ekip ve davetler',
            style: TextStyle(
              color: ext.foreground,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Üyelerin rollerini ve durumlarını buradan izleyin; davetleri yönetin.',
            style: TextStyle(color: ext.foregroundSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text('Üyeler', style: _sectionStyle(ext)),
          const SizedBox(height: 8),
          membersAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Text(officeErrorUserMessage(e), style: TextStyle(color: ext.foregroundSecondary)),
            data: (list) {
              if (list.isEmpty) {
                return _EmptyCard(
                  ext: ext,
                  message: 'Henüz üye listesi boş veya yüklenemedi.',
                );
              }
              list.sort((a, b) => a.userId.compareTo(b.userId));
              return Column(
                children: list.map((m) => _MemberTile(
                  m: m,
                  currentUid: user?.uid,
                  officeId: oid,
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Davetler', style: _sectionStyle(ext)),
          const SizedBox(height: 8),
          invitesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text(officeErrorUserMessage(e)),
            data: (invites) {
              if (invites.isEmpty) {
                return _EmptyCard(ext: ext, message: 'Aktif davet yok. Yeni davet oluşturun.');
              }
              invites.sort((a, b) => b.code.compareTo(a.code));
              return Column(
                children: invites.map((i) => _InviteTile(invite: i, officeId: oid)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

TextStyle _sectionStyle(AppThemeExtension ext) => TextStyle(
      color: ext.foreground,
      fontWeight: FontWeight.w700,
      fontSize: 15,
    );

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.m,
    required this.currentUid,
    required this.officeId,
  });

  final OfficeMembership m;
  final String? currentUid;
  final String officeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final auth = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.userId == currentUid ? 'Siz' : m.userId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.foreground,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.role.name,
                      style: TextStyle(color: ext.foregroundSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: m.status),
              if (auth != null && m.userId != auth.uid && m.role != OfficeRole.owner) ...[
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    try {
                      if (v == 's') {
                        await OfficeAdminService.suspendMember(
                          user: auth,
                          officeId: officeId,
                          targetUserId: m.userId,
                        );
                      } else if (v == 'r') {
                        await OfficeAdminService.removeMember(
                          user: auth,
                          officeId: officeId,
                          targetUserId: m.userId,
                        );
                      }
                      if (context.mounted) {
                        ref.invalidate(officeMembersStreamProvider(officeId));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(officeErrorUserMessage(e))),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 's', child: Text('Askıya al')),
                    PopupMenuItem(value: 'r', child: Text('Kaldır')),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final MembershipStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MembershipStatus.active => ('Aktif', Colors.green.shade700),
      MembershipStatus.invited => ('Davetli', Colors.amber.shade800),
      MembershipStatus.suspended => ('Askıda', Colors.orange.shade900),
      MembershipStatus.removed => ('Kaldırıldı', Colors.red.shade800),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InviteTile extends ConsumerWidget {
  const _InviteTile({required this.invite, required this.officeId});

  final OfficeInvite invite;
  final String officeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final auth = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.code,
                      style: TextStyle(
                        color: ext.foreground,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${invite.roleToAssign.name} · ${invite.usedCount}/${invite.maxUses} · '
                      '${invite.isActive ? "Aktif" : "Kapalı"}',
                      style: TextStyle(color: ext.foregroundSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (invite.isActive && auth != null)
                TextButton(
                  onPressed: () async {
                    try {
                      await OfficeAdminService.deactivateInvite(
                        user: auth,
                        officeId: officeId,
                        inviteId: invite.id,
                      );
                      if (context.mounted) {
                        ref.invalidate(officeInvitesStreamProvider(officeId));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(officeErrorUserMessage(e))),
                        );
                      }
                    }
                  },
                  child: const Text('Pasifleştir'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.ext, required this.message});

  final AppThemeExtension ext;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: ext.foregroundSecondary.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: TextStyle(color: ext.foregroundSecondary, fontSize: 13),
      ),
    );
  }
}
