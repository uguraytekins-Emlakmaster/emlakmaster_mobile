import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/office/domain/membership_status.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_invite_entity.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_membership_entity.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_role.dart';
import 'package:emlakmaster_mobile/features/office/presentation/providers/office_admin_providers.dart';
import 'package:emlakmaster_mobile/features/office/presentation/utils/office_error_ui.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/providers/connected_platforms_providers.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/platform_status_chip.dart';
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
    final doc = user != null
        ? ref.watch(userDocStreamProvider(user.uid)).valueOrNull
        : null;
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
        appBar: AppBar(
          title: const Text(ProductLabels.officeDesk),
          backgroundColor: ext.background,
        ),
        body: SafeArea(
          child: EmptyState(
            grouped: true,
            compact: true,
            icon: Icons.apartment_outlined,
            title: 'Ofis bağlantısı gerekiyor',
            subtitle: 'Bu alanı açmak için önce bir ofise bağlanın.',
            actionLabel: 'Ofis alanına git',
            onAction: () => context.push(AppRouter.routeOfficeGate),
          ),
        ),
      );
    }

    if (!canAdmin) {
      return Scaffold(
        backgroundColor: ext.background,
        appBar: AppBar(
          title: const Text(ProductLabels.officeDesk),
          backgroundColor: ext.background,
        ),
        body: const SafeArea(
          child: EmptyState(
            grouped: true,
            compact: true,
            icon: Icons.lock_outline_rounded,
            title: 'Bu alan için yetki gerekiyor',
            subtitle:
                'Yalnızca ofis sahibi, yönetici ya da ekip lideri erişebilir.',
          ),
        ),
      );
    }

    final membersAsync = ref.watch(officeMembersStreamProvider(oid));
    final invitesAsync = ref.watch(officeInvitesStreamProvider(oid));
    final adminPlat = ref.watch(adminPlatformConnectionsProvider);

    return Scaffold(
      backgroundColor: ext.background,
      appBar: AppBar(
        backgroundColor: ext.background,
        title: const Text(ProductLabels.officeDesk),
        actions: [
          IconButton(
            tooltip: 'Davet hazırla',
            onPressed: () => context.push(AppRouter.routeOfficeInviteCreate),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space5,
          vertical: DesignTokens.space3,
        ),
        children: [
          Text(
            'Kadro ve davetler',
            style: AppTypography.cardHeading(context).copyWith(
              color: ext.foreground,
              fontSize: DesignTokens.fontSizeLg,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            'Üyeler, davet akışı ve dış bağlantı görünümü.',
            style: AppTypography.body(context).copyWith(
              fontSize: DesignTokens.fontSizeSm,
              height: 1.4,
            ),
          ),
          const SizedBox(height: DesignTokens.space5),
          Text('Üyeler', style: _sectionStyle(context, ext)),
          const SizedBox(height: DesignTokens.space2),
          membersAsync.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(DesignTokens.space6),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: DesignTokens.space4),
              child: EmptyState(
                compact: true,
                grouped: true,
                icon: Icons.cloud_off_outlined,
                title: 'Üyeler yüklenemedi',
                subtitle: officeErrorUserMessage(e),
                actionLabel: 'Tekrar dene',
                onAction: () =>
                    ref.invalidate(officeMembersStreamProvider(oid)),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  compact: true,
                  grouped: true,
                  icon: Icons.groups_outlined,
                  title: 'Henüz ekip arkadaşı yok',
                  subtitle: 'Davet göndererek ofis kadrosunu büyütün.',
                );
              }
              list.sort((a, b) => a.userId.compareTo(b.userId));
              return Column(
                children: list
                    .map((m) => _MemberTile(
                          m: m,
                          currentUid: user?.uid,
                          officeId: oid,
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: DesignTokens.space6),
          Text('Davetler', style: _sectionStyle(context, ext)),
          const SizedBox(height: DesignTokens.space2),
          invitesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: DesignTokens.space4),
              child: EmptyState(
                compact: true,
                grouped: true,
                icon: Icons.cloud_off_outlined,
                title: 'Davetler yüklenemedi',
                subtitle: officeErrorUserMessage(e),
                actionLabel: 'Tekrar dene',
                onAction: () =>
                    ref.invalidate(officeInvitesStreamProvider(oid)),
              ),
            ),
            data: (invites) {
              if (invites.isEmpty) {
                return const EmptyState(
                  compact: true,
                  grouped: true,
                  icon: Icons.mail_outline_rounded,
                  title: 'Açık davet yok',
                  subtitle: 'Sağ üstten yeni bir davet hazırlayabilirsiniz.',
                );
              }
              invites.sort((a, b) => b.code.compareTo(a.code));
              return Column(
                children: invites
                    .map((i) => _InviteTile(invite: i, officeId: oid))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: DesignTokens.space8),
          Text('Dış bağlantılar', style: _sectionStyle(context, ext)),
          const SizedBox(height: DesignTokens.space2),
          Text(
            'Her ekip üyesi için bağlantı görünümü.',
            style: AppTypography.body(context).copyWith(
              fontSize: DesignTokens.fontSizeXs,
              height: 1.35,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          ...adminPlat.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.space3),
              child: Material(
                color: ext.surfaceElevated,
                borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.space4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.userDisplayName,
                              style: TextStyle(
                                color: ext.foreground,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              row.platform.displayName,
                              style: TextStyle(
                                  color: ext.foregroundSecondary, fontSize: 12),
                            ),
                            if (row.error != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                row.error!.shortMessage,
                                style:
                                    TextStyle(color: ext.danger, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),
                      PlatformStatusChip(truthKind: row.truthKind),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.push(AppRouter.routeConnectedAccounts),
            icon: const Icon(Icons.hub_outlined, size: DesignTokens.iconMd),
            label: const Text('Bağlantıları aç'),
          ),
        ],
      ),
    );
  }
}

TextStyle _sectionStyle(BuildContext context, AppThemeExtension ext) =>
    AppTypography.metricLabel(context).copyWith(
      color: ext.foreground,
      fontSize: DesignTokens.fontSizeSm,
      fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: Material(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
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
                      style: TextStyle(
                          color: ext.foregroundSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: m.status),
              if (auth != null &&
                  m.userId != auth.uid &&
                  m.role != OfficeRole.owner) ...[
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
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: Material(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
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
                      style: TextStyle(
                          color: ext.foregroundSecondary, fontSize: 12),
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
