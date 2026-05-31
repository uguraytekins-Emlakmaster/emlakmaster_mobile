import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/admin_uyelikler_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/providers/uyelikler_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/utils/uyelikler_filter.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/utils/uyelikler_types.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/uyelikler_actions.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/widgets/uyelikler_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/widgets/uyelikler_row.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/widgets/uyelikler_skeleton.dart';
import 'package:emlakmaster_mobile/features/office/presentation/providers/office_admin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UyeliklerCommandSurface extends ConsumerStatefulWidget {
  const UyeliklerCommandSurface({super.key, required this.officeId});

  final String officeId;

  @override
  ConsumerState<UyeliklerCommandSurface> createState() =>
      _UyeliklerCommandSurfaceState();
}

class _UyeliklerCommandSurfaceState
    extends ConsumerState<UyeliklerCommandSurface> {
  String _search = '';
  UyeliklerFilter _filter = UyeliklerFilter.all;

  void _invalidate() {
    ref.invalidate(officeInvitesStreamProvider(widget.officeId));
    ref.invalidate(officeMembersStreamProvider(widget.officeId));
    ref.invalidate(uyeliklerSnapshotProvider(widget.officeId));
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(uyeliklerSnapshotProvider(widget.officeId));
    final bottom = MediaQuery.paddingOf(context).bottom;
    final now = DateTime.now();

    return snapshotAsync.when(
      loading: () => const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: UyeliklerLoadingSkeleton()),
        ],
      ),
      error: (_, __) => CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: PremiumUyeliklerHeader()),
          SliverFillRemaining(
            hasScrollBody: false,
            child: UyeliklerEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Kayıtlar yüklenemedi',
              message: 'Bağlantınızı kontrol edip tekrar deneyin.',
              onRetry: _invalidate,
            ),
          ),
        ],
      ),
      data: (snapshot) {
        final filtered = filterUyeliklerRows(
          source: snapshot.rows,
          searchQuery: _search,
          filter: _filter,
          now: now,
        );

        final interventionRows =
            filtered.where((r) => r.needsAction).toList(growable: false);
        final showInterventionLane =
            _filter == UyeliklerFilter.all && interventionRows.isNotEmpty;
        final mainRows = showInterventionLane
            ? filtered.where((r) => !r.needsAction).toList(growable: false)
            : filtered;

        return CustomScrollView(
          cacheExtent: 480,
          slivers: [
            SliverToBoxAdapter(
              child: PremiumUyeliklerHeader(coverageNote: snapshot.coverageNote),
            ),
            SliverToBoxAdapter(
              child: PremiumUyeliklerSummaryStrip(strip: snapshot.strip),
            ),
            SliverToBoxAdapter(
              child: UyeliklerQuickRouteRow(
                onCreateInvite: () =>
                    UyeliklerActions.openCreateInvite(context),
                onOfficeAdmin: () => UyeliklerActions.openOfficeAdmin(context),
                onKadro: () => UyeliklerActions.openKadro(context),
              ),
            ),
            SliverToBoxAdapter(
              child: UyeliklerCompactSearch(
                hintText: 'Üye veya davet ara (isim, kod, rol)',
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            SliverToBoxAdapter(
              child: UyeliklerFilterChips(
                selected: _filter,
                onSelected: (f) => setState(() => _filter = f),
              ),
            ),
            if (snapshot.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: UyeliklerEmptyState(
                  title: 'Henüz davet veya üyelik yok',
                  message: snapshot.coverageNote,
                  actionLabel: 'Yeni davet oluştur',
                  onAction: () => UyeliklerActions.openCreateInvite(context),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: UyeliklerEmptyState(
                  icon: Icons.filter_alt_off_rounded,
                  title: 'Eşleşen kayıt yok',
                  message: _search.isNotEmpty
                      ? 'Arama ve filtre kriterlerinize uygun kayıt bulunamadı.'
                      : 'Seçili filtre için kayıt yok. Farklı bir filtre deneyin.',
                  actionLabel: 'Filtreyi sıfırla',
                  onAction: () => setState(() {
                    _filter = UyeliklerFilter.all;
                    _search = '';
                  }),
                ),
              )
            else ...[
              if (showInterventionLane) ...[
                SliverToBoxAdapter(
                  child: UyeliklerSectionHeader(
                    title: 'Müdahale gereken',
                    count: interventionRows.length,
                  ),
                ),
                SliverList.builder(
                  itemCount: interventionRows.length,
                  itemBuilder: (context, index) =>
                      _buildRow(context, interventionRows[index]),
                ),
              ],
              if (mainRows.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: UyeliklerSectionHeader(
                    title: showInterventionLane
                        ? 'Tüm kayıtlar'
                        : 'Üyelik ve davetler',
                    count: mainRows.length,
                  ),
                ),
                SliverList.builder(
                  itemCount: mainRows.length,
                  itemBuilder: (context, index) =>
                      _buildRow(context, mainRows[index]),
                ),
              ],
            ],
            SliverPadding(
              padding: EdgeInsets.only(
                bottom: AdminUyeliklerTokens.bottomReserve + bottom,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRow(BuildContext context, UyelikRowViewModel row) {
    if (row.kind == UyelikKind.invite) {
      return UyelikRow(
        viewModel: row,
        onTap: () => UyeliklerActions.showDetailSheet(context, row),
        onDetail: () => UyeliklerActions.showDetailSheet(context, row),
        onCopyCode: () =>
            UyeliklerActions.copyInviteCode(context, row.inviteCode),
        onCreateInvite: () => UyeliklerActions.openCreateInvite(context),
        onDeactivate: row.isActiveInvite && row.inviteId != null
            ? () => UyeliklerActions.deactivateInvite(
                  context,
                  ref,
                  officeId: widget.officeId,
                  inviteId: row.inviteId!,
                  code: row.inviteCode ?? '',
                )
            : null,
      );
    }

    final userId = row.memberUserId;
    return UyelikRow(
      viewModel: row,
      onTap: () => UyeliklerActions.showDetailSheet(context, row),
      onDetail: () => UyeliklerActions.showDetailSheet(context, row),
      onKadro: () => UyeliklerActions.openKadro(context),
      onSuspend: row.canSuspend && userId != null
          ? () => UyeliklerActions.suspendMember(
                context,
                ref,
                officeId: widget.officeId,
                targetUserId: userId,
                displayName: row.title,
              )
          : null,
      onRemove: row.canRemove && userId != null
          ? () => UyeliklerActions.removeMember(
                context,
                ref,
                officeId: widget.officeId,
                targetUserId: userId,
                displayName: row.title,
              )
          : null,
    );
  }
}
