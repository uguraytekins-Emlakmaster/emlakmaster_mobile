import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/data/audit_log_repository.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/admin_islem_kayitlari_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/islem_kayitlari_actions.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/providers/islem_kayitlari_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/utils/islem_kayitlari_filter.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/utils/islem_kayitlari_types.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/widgets/islem_kayitlari_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/widgets/islem_kayitlari_row.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/widgets/islem_kayitlari_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IslemKayitlariCommandSurface extends ConsumerStatefulWidget {
  const IslemKayitlariCommandSurface({super.key, this.headerActions = const []});

  final List<Widget> headerActions;

  @override
  ConsumerState<IslemKayitlariCommandSurface> createState() =>
      _IslemKayitlariCommandSurfaceState();
}

class _IslemKayitlariCommandSurfaceState
    extends ConsumerState<IslemKayitlariCommandSurface> {
  String _search = '';
  IslemKayitlariFilter _filter = IslemKayitlariFilter.all;

  void _invalidate() {
    ref.invalidate(auditLogsStreamProvider);
    ref.invalidate(adminInvitesStreamProvider);
    ref.invalidate(islemKayitlariSnapshotProvider);
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(islemKayitlariSnapshotProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final now = DateTime.now();

    return snapshotAsync.when(
      loading: () => const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: IslemKayitlariLoadingSkeleton()),
        ],
      ),
      error: (_, __) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PremiumIslemKayitlariHeader(actions: widget.headerActions),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: IslemKayitlariEmptyState(
              title: 'Kayıtlar yüklenemedi',
              message: 'Bağlantınızı kontrol edip tekrar deneyin.',
              onRetry: _invalidate,
            ),
          ),
        ],
      ),
      data: (snapshot) {
        final filtered = filterIslemKayitlariRows(
          source: snapshot.rows,
          searchQuery: _search,
          filter: _filter,
          now: now,
        );

        final showCriticalSection =
            _filter == IslemKayitlariFilter.all &&
            filtered.any(
              (r) => r.severity == IslemKayitlariSeverity.critical,
            );

        return CustomScrollView(
          cacheExtent: 480,
          slivers: [
            SliverToBoxAdapter(
              child: PremiumIslemKayitlariHeader(
                actions: widget.headerActions,
                coverageNote: snapshot.coverageNote,
              ),
            ),
            SliverToBoxAdapter(
              child: PremiumIslemKayitlariHealthStrip(strip: snapshot.strip),
            ),
            SliverToBoxAdapter(
              child: IslemKayitlariQuickRouteRow(
                onKadro: () => IslemKayitlariActions.openKadro(context),
                onReports: () => IslemKayitlariActions.openReportsTab(context),
                onCommandCenter: IslemKayitlariActions.canOpenCommandCenter(ref)
                    ? () => IslemKayitlariActions.openCommandCenter(context)
                    : null,
              ),
            ),
            SliverToBoxAdapter(
              child: IslemKayitlariCompactSearch(
                hintText: 'İşlem ara (aktör, hedef, detay)',
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            SliverToBoxAdapter(
              child: IslemKayitlariFilterChips(
                selected: _filter,
                onSelected: (f) => setState(() => _filter = f),
              ),
            ),
            if (snapshot.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: IslemKayitlariEmptyState(
                  title: 'Henüz işlem kaydı yok',
                  message: snapshot.coverageNote,
                  actionLabel: 'Kadroya git',
                  onAction: () => IslemKayitlariActions.openKadro(context),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: IslemKayitlariEmptyState(
                  title: 'Eşleşen kayıt yok',
                  message: _search.isNotEmpty
                      ? 'Arama ve filtre kriterlerinize uygun kayıt bulunamadı.'
                      : 'Seçili filtre için kayıt yok. Farklı bir filtre deneyin.',
                  actionLabel: 'Filtreyi sıfırla',
                  onAction: () => setState(() {
                    _filter = IslemKayitlariFilter.all;
                    _search = '';
                  }),
                ),
              )
            else ...[
              if (showCriticalSection)
                SliverToBoxAdapter(
                  child: IslemKayitlariSectionHeader(
                    title: 'Kritik değişiklikler',
                    count: filtered
                        .where(
                          (r) => r.severity == IslemKayitlariSeverity.critical,
                        )
                        .length,
                  ),
                ),
              SliverToBoxAdapter(
                child: IslemKayitlariSectionHeader(
                  title: showCriticalSection ? 'Tüm kayıtlar' : 'Operasyon geçmişi',
                  count: filtered.length,
                ),
              ),
              SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) =>
                    _buildRow(context, filtered[index]),
              ),
            ],
            SliverPadding(
              padding: EdgeInsets.only(
                bottom: AdminIslemKayitlariTokens.bottomReserve + bottom,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRow(BuildContext context, IslemKayitlariRowViewModel row) {
    final teamId = row.teamId;
    final consultantId = row.consultantId;

    return IslemKayitlariRow(
      viewModel: row,
      onTap: () => IslemKayitlariActions.showDetailSheet(context, row),
      onDetail: () => IslemKayitlariActions.showDetailSheet(context, row),
      onConsultant: consultantId != null && consultantId.isNotEmpty
          ? () => IslemKayitlariActions.openKadro(context)
          : null,
      onTeam: teamId != null && teamId.isNotEmpty
          ? () => IslemKayitlariActions.openTeam(context, teamId)
          : null,
      onReports: () => IslemKayitlariActions.openReportsTab(context),
      onApplyFilter: () => setState(
        () => _filter = row.suggestedFilter,
      ),
    );
  }
}
