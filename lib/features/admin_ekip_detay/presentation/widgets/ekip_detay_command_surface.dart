import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/admin_consultants/presentation/providers/admin_consultants_providers.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/admin_ekip_detay_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/ekip_detay_actions.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/providers/ekip_detay_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/utils/ekip_detay_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/widgets/ekip_detay_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/widgets/ekip_detay_manager_rail.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/widgets/ekip_detay_member_row.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/widgets/ekip_detay_skeleton.dart';
import 'package:emlakmaster_mobile/features/admin_teams/presentation/providers/admin_teams_providers.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef EkipDetayEditHandler = void Function(BuildContext context, UserDoc user);
typedef EkipDetayRemoveHandler = void Function(BuildContext context, UserDoc user);

class EkipDetayCommandSurface extends ConsumerWidget {
  const EkipDetayCommandSurface({
    super.key,
    required this.teamId,
    required this.selectedManagerId,
    required this.onManagerChanged,
    required this.onSaveManager,
    required this.onEditConsultant,
    required this.onAddMember,
    required this.onRemoveMember,
    this.headerActions = const [],
  });

  final String teamId;
  final String selectedManagerId;
  final ValueChanged<String?> onManagerChanged;
  final VoidCallback onSaveManager;
  final EkipDetayEditHandler onEditConsultant;
  final VoidCallback onAddMember;
  final EkipDetayRemoveHandler onRemoveMember;
  final List<Widget> headerActions;

  void _invalidate(WidgetRef ref) {
    ref.invalidate(adminTeamDocProvider(teamId));
    ref.invalidate(adminConsultantsListProvider);
    ref.invalidate(ekipDetaySnapshotProvider(teamId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snapshotAsync = ref.watch(ekipDetaySnapshotProvider(teamId));
    final bottom = MediaQuery.paddingOf(context).bottom;
    final canManage = EkipDetayActions.canManageTeam(ref);
    final canCommand = EkipDetayActions.canOpenCommandCenter(ref);
    final canWarRoom = EkipDetayActions.canOpenWarRoom(ref);

    return snapshotAsync.when(
      loading: () => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: EkipDetayLoadingSkeleton(key: Key('loading-$teamId')),
          ),
        ],
      ),
      error: (e, _) {
        final isNotFound = e == 'team_not_found';
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PremiumEkipDetayHeader(
                teamName: isNotFound ? 'Ekip bulunamadı' : 'Ekip detayı',
                actions: headerActions,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: EkipDetayEmptyState(
                title: isNotFound
                    ? l10n.t('team_not_found')
                    : 'Ekip detayı yüklenemedi',
                message: isNotFound
                    ? 'Bu ekip kaydı artık mevcut olmayabilir.'
                    : 'Bağlantınızı kontrol edip tekrar deneyin.',
                onRetry: isNotFound ? null : () => _invalidate(ref),
                actionLabel: isNotFound ? 'Ekiplere dön' : null,
                onAction: isNotFound
                    ? () => EkipDetayActions.openTeams(context)
                    : null,
              ),
            ),
          ],
        );
      },
      data: (snapshot) => _buildLoaded(
        context,
        ref,
        snapshot: snapshot,
        bottom: bottom,
        canManage: canManage,
        canCommand: canCommand,
        canWarRoom: canWarRoom,
        l10n: l10n,
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    WidgetRef ref, {
    required EkipDetaySnapshot snapshot,
    required double bottom,
    required bool canManage,
    required bool canCommand,
    required bool canWarRoom,
    required AppLocalizations l10n,
  }) {
    final managerLine = snapshot.managerName != null
        ? '${snapshot.managerRoleLabel} · ${snapshot.managerName}'
        : 'Yönetici atanmamış';
    final effectiveManagerId =
        selectedManagerId.isEmpty ? snapshot.team.managerId : selectedManagerId;

    return CustomScrollView(
      cacheExtent: 480,
      slivers: [
        SliverToBoxAdapter(
          child: PremiumEkipDetayHeader(
            teamName: snapshot.team.name,
            managerLine: managerLine,
            actions: headerActions,
          ),
        ),
        SliverToBoxAdapter(
          child: PremiumEkipDetayHealthStrip(strip: snapshot.strip),
        ),
        if (snapshot.strip.hasOfficeSignals)
          const SliverToBoxAdapter(child: EkipDetayOfficeNote()),
        SliverToBoxAdapter(
          child: EkipDetayQuickRouteRow(
            onKadro: () => EkipDetayActions.openKadro(context),
            onTeams: () => EkipDetayActions.openTeams(context),
            onReports: () => EkipDetayActions.openReportsTab(context),
            onAddMember: canManage ? onAddMember : null,
            onCommandCenter: canCommand
                ? () => EkipDetayActions.openCommandCenter(context)
                : null,
            onWarRoom:
                canWarRoom ? () => EkipDetayActions.openWarRoom(context) : null,
          ),
        ),
        SliverToBoxAdapter(
          child: EkipDetayManagerRail(
            snapshot: snapshot,
            selectedManagerId: effectiveManagerId,
            onManagerChanged: onManagerChanged,
            onSaveManager: onSaveManager,
            canManage: canManage,
          ),
        ),
        SliverToBoxAdapter(
          child: EkipDetaySectionHeader(
            title: 'Ekip üyeleri',
            count: snapshot.members.length,
          ),
        ),
        if (snapshot.members.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EkipDetayEmptyState(
              title: l10n.t('empty_team_members'),
              message: canManage
                  ? 'Bu ekibe danışman atayarak kadroyu oluşturabilirsiniz.'
                  : 'Bu ekipte henüz kayıtlı üye yok.',
              actionLabel: canManage ? l10n.t('action_add_member') : null,
              onAction: canManage ? onAddMember : null,
            ),
          )
        else
          SliverList.builder(
            itemCount: snapshot.members.length,
            itemBuilder: (context, index) {
              final user = snapshot.members[index];
              return EkipDetayMemberRow(
                user: user,
                teamManagerId: snapshot.team.managerId,
                canEdit: canManage,
                canRemove: canManage,
                onTap: () => onEditConsultant(context, user),
                onEdit: () => onEditConsultant(context, user),
                onKadro: () => EkipDetayActions.openKadro(context),
                onReports: () => EkipDetayActions.openReportsTab(context),
                onCommandCenter: canCommand
                    ? () => EkipDetayActions.openCommandCenter(context)
                    : null,
                onRemove: canManage
                    ? () => onRemoveMember(context, user)
                    : null,
              );
            },
          ),
        if (snapshot.strip.teamNeedsIntervention &&
            snapshot.members.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AdminEkipDetayTokens.horizontal,
                AdminEkipDetayTokens.sectionGap,
                AdminEkipDetayTokens.horizontal,
                AdminEkipDetayTokens.moduleGap,
              ),
              child: Text(
                'Ekip düzeyi uyarı: yönetici eksikliği veya kadro baskısı tespit edildi. Üye satırlarındaki müdahale rozetleri bireysel sinyallerdir.',
                style: TextStyle(
                  color: AppThemeExtension.of(context).textTertiary,
                  fontSize: AdminEkipDetayTokens.rowChipSize,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ],
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: AdminEkipDetayTokens.bottomReserve + bottom,
          ),
        ),
      ],
    );
  }
}
