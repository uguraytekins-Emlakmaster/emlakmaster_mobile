import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/admin_ofis_masasi_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/ofis_masasi_actions.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/providers/ofis_masasi_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/utils/ofis_masasi_filter.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/utils/ofis_masasi_types.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/widgets/ofis_masasi_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/widgets/ofis_masasi_row.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/widgets/ofis_masasi_skeleton.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/providers/connected_platforms_providers.dart';
import 'package:emlakmaster_mobile/features/office/presentation/providers/office_admin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfisMasasiCommandSurface extends ConsumerStatefulWidget {
  const OfisMasasiCommandSurface({super.key, required this.officeId});

  final String officeId;

  @override
  ConsumerState<OfisMasasiCommandSurface> createState() =>
      _OfisMasasiCommandSurfaceState();
}

class _OfisMasasiCommandSurfaceState
    extends ConsumerState<OfisMasasiCommandSurface> {
  String _search = '';

  void _invalidate() {
    ref.invalidate(officeInvitesStreamProvider(widget.officeId));
    ref.invalidate(officeMembersStreamProvider(widget.officeId));
    ref.invalidate(platformSetupMapProvider(widget.officeId));
    ref.invalidate(ofisMasasiSnapshotProvider(widget.officeId));
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(ofisMasasiSnapshotProvider(widget.officeId));
    final bottom = MediaQuery.paddingOf(context).bottom;

    return snapshotAsync.when(
      loading: () => const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: OfisMasasiLoadingSkeleton()),
        ],
      ),
      error: (_, __) => CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: PremiumOfisMasasiHeader()),
          SliverFillRemaining(
            hasScrollBody: false,
            child: OfisMasasiEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Ofis verisi yüklenemedi',
              message: 'Bağlantınızı kontrol edip tekrar deneyin.',
              onRetry: _invalidate,
            ),
          ),
        ],
      ),
      data: (snapshot) {
        final members =
            filterOfisMasasiRows(source: snapshot.members, query: _search);
        final invites =
            filterOfisMasasiRows(source: snapshot.invites, query: _search);
        final connections =
            filterOfisMasasiRows(source: snapshot.connections, query: _search);
        final searching = _search.trim().isNotEmpty;

        return CustomScrollView(
          cacheExtent: 600,
          slivers: [
            SliverToBoxAdapter(
              child: PremiumOfisMasasiHeader(
                coverageNote: snapshot.coverageNote,
              ),
            ),
            SliverToBoxAdapter(
              child: OfisMasasiSummaryStripView(summary: snapshot.summary),
            ),
            SliverToBoxAdapter(
              child: OfisMasasiQuickRoutes(
                onCreateInvite: () =>
                    OfisMasasiActions.openCreateInvite(context),
                onUyelikler: () => OfisMasasiActions.openUyelikler(context),
                onKadro: () => OfisMasasiActions.openKadro(context),
                onTeams: () => OfisMasasiActions.openTeams(context),
                onConnections: () =>
                    OfisMasasiActions.openConnections(context),
              ),
            ),
            SliverToBoxAdapter(
              child: OfisMasasiCompactSearch(
                hintText: 'Üye, davet veya bağlantı ara',
                onChanged: (v) => setState(() => _search = v),
              ),
            ),

            // ——— Üyeler ———
            SliverToBoxAdapter(
              child: OfisMasasiSectionHeader(
                title: 'Üyeler',
                count: members.isEmpty ? null : members.length,
              ),
            ),
            if (members.isEmpty)
              SliverToBoxAdapter(
                child: OfisMasasiInlineEmpty(
                  message: searching
                      ? 'Aramayla eşleşen üye yok.'
                      : 'Henüz ofis üyesi yok. Davet göndererek kadroyu büyütün.',
                ),
              )
            else
              SliverList.builder(
                itemCount: members.length,
                itemBuilder: (context, index) =>
                    _buildRow(context, members[index]),
              ),

            // ——— Davetler ———
            SliverToBoxAdapter(
              child: OfisMasasiSectionHeader(
                title: 'Davetler',
                count: invites.isEmpty ? null : invites.length,
              ),
            ),
            if (invites.isEmpty)
              SliverToBoxAdapter(
                child: OfisMasasiInlineEmpty(
                  message: searching
                      ? 'Aramayla eşleşen davet yok.'
                      : 'Açık davet yok. Yeni bir davet hazırlayabilirsiniz.',
                ),
              )
            else
              SliverList.builder(
                itemCount: invites.length,
                itemBuilder: (context, index) =>
                    _buildRow(context, invites[index]),
              ),

            // ——— Bağlantılar ———
            SliverToBoxAdapter(
              child: OfisMasasiSectionHeader(
                title: 'Bağlantılar',
                count: connections.isEmpty ? null : connections.length,
                note: snapshot.connectionsNote,
              ),
            ),
            if (!snapshot.connectionsKnown)
              const SliverToBoxAdapter(
                child: OfisMasasiInlineEmpty(
                  message:
                      'Bağlantı kurulum verisi yükleniyor; hazır olduğunda gerçek durum görünecek.',
                ),
              )
            else if (connections.isEmpty)
              SliverToBoxAdapter(
                child: OfisMasasiInlineEmpty(
                  message: searching
                      ? 'Aramayla eşleşen bağlantı yok.'
                      : 'Tanımlı platform bağlantısı yok.',
                ),
              )
            else
              SliverList.builder(
                itemCount: connections.length,
                itemBuilder: (context, index) =>
                    _buildRow(context, connections[index]),
              ),

            SliverPadding(
              padding: EdgeInsets.only(
                bottom: AdminOfisMasasiTokens.bottomReserve + bottom,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRow(BuildContext context, OfisRowViewModel row) {
    switch (row.kind) {
      case OfisRowKind.invite:
        return OfisMasasiRow(
          viewModel: row,
          onTap: () => OfisMasasiActions.showDetailSheet(context, row),
          onDetail: () => OfisMasasiActions.showDetailSheet(context, row),
          onCopyCode: () =>
              OfisMasasiActions.copyInviteCode(context, row.inviteCode),
          onCreateInvite: () => OfisMasasiActions.openCreateInvite(context),
          onDeactivate: row.isActiveInvite && row.inviteId != null
              ? () => OfisMasasiActions.deactivateInvite(
                    context,
                    ref,
                    officeId: widget.officeId,
                    inviteId: row.inviteId!,
                    code: row.inviteCode ?? '',
                  )
              : null,
        );
      case OfisRowKind.member:
        final userId = row.memberUserId;
        return OfisMasasiRow(
          viewModel: row,
          onTap: () => OfisMasasiActions.showDetailSheet(context, row),
          onDetail: () => OfisMasasiActions.showDetailSheet(context, row),
          onKadro: () => OfisMasasiActions.openKadro(context),
          onSuspend: row.canSuspend && userId != null
              ? () => OfisMasasiActions.suspendMember(
                    context,
                    ref,
                    officeId: widget.officeId,
                    targetUserId: userId,
                    displayName: row.title,
                  )
              : null,
          onRemove: row.canRemove && userId != null
              ? () => OfisMasasiActions.removeMember(
                    context,
                    ref,
                    officeId: widget.officeId,
                    targetUserId: userId,
                    displayName: row.title,
                  )
              : null,
        );
      case OfisRowKind.connection:
        return OfisMasasiRow(
          viewModel: row,
          onTap: () => OfisMasasiActions.showDetailSheet(context, row),
          onDetail: () => OfisMasasiActions.showDetailSheet(context, row),
          onOpenConnections: () => OfisMasasiActions.openConnections(context),
        );
    }
  }
}
