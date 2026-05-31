import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/admin_raporlar_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/providers/raporlar_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/raporlar_actions.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_filter.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_types.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/widgets/raporlar_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/widgets/raporlar_row.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/widgets/raporlar_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RaporlarCommandSurface extends ConsumerStatefulWidget {
  const RaporlarCommandSurface({super.key});

  @override
  ConsumerState<RaporlarCommandSurface> createState() =>
      _RaporlarCommandSurfaceState();
}

class _RaporlarCommandSurfaceState
    extends ConsumerState<RaporlarCommandSurface> {
  String _search = '';
  RaporlarFilter _filter = RaporlarFilter.all;

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(raporlarSnapshotProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return snapshotAsync.when(
      loading: () => const CustomScrollView(
        slivers: [SliverToBoxAdapter(child: RaporlarLoadingSkeleton())],
      ),
      error: (_, __) => CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: PremiumRaporlarHeader()),
          SliverFillRemaining(
            hasScrollBody: false,
            child: RaporlarEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Rapor yüzeyleri yüklenemedi',
              message: 'Bağlantınızı kontrol edip tekrar deneyin.',
              onRetry: () => RaporlarActions.refresh(ref),
            ),
          ),
        ],
      ),
      data: (snapshot) {
        if (snapshot.isEmpty) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PremiumRaporlarHeader(
                  coverageNote: snapshot.coverageNote,
                ),
              ),
              const SliverFillRemaining(
                hasScrollBody: false,
                child: RaporlarEmptyState(
                  title: 'Rapor yüzeyi yok',
                  message:
                      'Bu rol için açık bir yönetici rapor yüzeyi bulunmuyor.',
                ),
              ),
            ],
          );
        }

        final searching = _search.trim().isNotEmpty;
        final filtered = filterRaporlarEntries(
          snapshot.entries,
          query: _search,
          filter: _filter,
        );
        final showLanes = _filter == RaporlarFilter.all && !searching;
        final intervention = showLanes
            ? filtered.where((e) => e.needsAction).toList(growable: false)
            : const <RaporEntryViewModel>[];
        final primary = showLanes
            ? filtered.where((e) => !e.needsAction).toList(growable: false)
            : filtered;

        return CustomScrollView(
          cacheExtent: 600,
          slivers: [
            SliverToBoxAdapter(
              child: PremiumRaporlarHeader(coverageNote: snapshot.coverageNote),
            ),
            SliverToBoxAdapter(
              child: RaporlarSummaryStripView(summary: snapshot.summary),
            ),
            SliverToBoxAdapter(
              child: RaporlarCompactSearch(
                hintText: 'Rapor yüzeyi, kapsam veya kategori ara',
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            SliverToBoxAdapter(
              child: RaporlarFilterStrip(
                selected: _filter,
                onSelected: (f) => setState(() => _filter = f),
              ),
            ),

            // ——— Müdahale gereken alanlar (yalnızca gerçek) ———
            if (showLanes && intervention.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: RaporlarSectionHeader(
                  title: 'Müdahale gereken alanlar',
                  note: 'Canlı veride dikkat isteyen yüzeyler önce listelenir.',
                ),
              ),
              SliverList.builder(
                itemCount: intervention.length,
                itemBuilder: (context, index) =>
                    _buildRow(context, intervention[index]),
              ),
            ],

            // ——— Tüm rapor yüzeyleri ———
            SliverToBoxAdapter(
              child: RaporlarSectionHeader(
                title: showLanes ? 'Tüm rapor yüzeyleri' : 'Rapor yüzeyleri',
                count: primary.isEmpty ? null : primary.length,
              ),
            ),
            if (primary.isEmpty)
              SliverToBoxAdapter(
                child: RaporlarInlineEmpty(
                  message: searching || _filter != RaporlarFilter.all
                      ? 'Bu arama/filtre ile eşleşen yüzey yok.'
                      : 'Açık rapor yüzeyi yok.',
                ),
              )
            else
              SliverList.builder(
                itemCount: primary.length,
                itemBuilder: (context, index) =>
                    _buildRow(context, primary[index]),
              ),

            SliverPadding(
              padding: EdgeInsets.only(
                bottom: AdminRaporlarTokens.bottomReserve + bottom,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRow(BuildContext context, RaporEntryViewModel entry) {
    return RaporlarRow(
      entry: entry,
      onTap: () => RaporlarActions.open(context, entry),
      onDetail: () => RaporlarActions.showDetailSheet(context, entry),
    );
  }
}
