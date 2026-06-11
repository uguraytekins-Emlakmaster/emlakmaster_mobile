import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/onboarding/tour_target.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/ai_agent/presentation/widgets/axion_agent_daily_section.dart';
import 'package:emlakmaster_mobile/features/ai_agent/presentation/widgets/axion_uncaptured_numbers_strip.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/consultant_daily_actions.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/consultant_daily_tokens.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/providers/consultant_daily_provider.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_filter.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_types.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/widgets/consultant_daily_chrome.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/widgets/consultant_daily_row.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/widgets/consultant_daily_skeleton.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_quick_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Benim Günüm komuta yüzeyi (Screen 21) — premium, dürüst, hızlı.
class ConsultantDailySurface extends ConsumerStatefulWidget {
  const ConsultantDailySurface({super.key});

  @override
  ConsumerState<ConsultantDailySurface> createState() =>
      _ConsultantDailySurfaceState();
}

class _ConsultantDailySurfaceState
    extends ConsumerState<ConsultantDailySurface> {
  ConsultantDailyFilter _filter = ConsultantDailyFilter.all;
  String _search = '';
  late final DebouncedSearchController _debouncedSearch;

  @override
  void initState() {
    super.initState();
    _debouncedSearch = DebouncedSearchController(
      onQueryChanged: (q) {
        if (_search == q) return;
        setState(() => _search = q);
      },
    );
  }

  @override
  void dispose() {
    _debouncedSearch.dispose();
    super.dispose();
  }

  double _dockReserve(BuildContext context) {
    final ts = MediaQuery.textScalerOf(context);
    final ratio =
        ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
    return ConsultantDailyTokens.bottomReserve * ratio.clamp(1.0, 1.38);
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(consultantDailySnapshotProvider);
    final reserve = _dockReserve(context);

    return snapshotAsync.when(
      loading: () => const CustomScrollView(
        slivers: [SliverToBoxAdapter(child: ConsultantDailySkeleton())],
      ),
      error: (_, __) => CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: PremiumConsultantDailyHeader(
              subtitle: 'Görev, takip ve müşteri baskısı',
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: ConsultantDailyEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Günlük durum yüklenemedi',
              message: 'Bağlantınızı kontrol edip tekrar deneyin.',
              onRetry: () => ConsultantDailyActions.refresh(ref),
            ),
          ),
        ],
      ),
      data: (snapshot) => _buildData(context, snapshot, reserve),
    );
  }

  ConsultantDailyRow _row(ConsultantDailyEntry e) {
    final hasPhone = (e.phone ?? '').trim().isNotEmpty;
    final canCall = OutboundPhoneDial.isLikelyCallablePhone(e.phone ?? '');
    return ConsultantDailyRow(
      entry: e,
      onTap: () => ConsultantDailyActions.open(ref, context, e),
      onDetail: () => ConsultantDailyActions.showDetailSheet(context, ref, e),
      onCall: canCall ? () => ConsultantDailyActions.call(context, e) : null,
      onMessage:
          hasPhone ? () => ConsultantDailyActions.message(context, e) : null,
    );
  }

  Widget _buildData(
    BuildContext context,
    ConsultantDailySnapshot snapshot,
    double reserve,
  ) {
    final subtitle = snapshot.greetingName.isNotEmpty
        ? '${snapshot.greetingName} · görev, takip ve müşteri baskısı'
        : 'Görev, takip ve müşteri baskısı';
    final searching = _search.trim().isNotEmpty;
    final showLanes = _filter == ConsultantDailyFilter.all && !searching;

    final filtered = filterConsultantDailyEntries(
      snapshot.entries,
      query: _search,
      filter: _filter,
    );
    final priority =
        snapshot.entries.where((e) => e.needsAttention).toList(growable: false);
    final rest = snapshot.entries
        .where((e) => !e.needsAttention)
        .toList(growable: false);

    return CustomScrollView(
      cacheExtent: 380,
      slivers: [
        SliverToBoxAdapter(
          child: TourTarget(
            id: TourTargetId.gunumCommandDeck,
            child: ConsultantDailyCommandDeck(
              subtitle: subtitle,
              coverageNote: snapshot.coverageNote,
              summary: snapshot.summary,
              urgentSignals: priority.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ConsultantDailyControlsPanel(
            searchController: _debouncedSearch.controller,
            searchHint: 'Görev, müşteri veya durum ara',
            selectedFilter: _filter,
            onFilterSelected: (f) {
              AppFeedback.selectionClick();
              setState(() => _filter = f);
            },
          ),
        ),

        // ——— Kayıtsız numaralar (numara kaçırmama önceliği) ———
        if (showLanes)
          const SliverToBoxAdapter(child: AxionUncapturedNumbersStrip()),

        if (showLanes) ...[
          // ——— Öncelikli (gerçek baskı) ———
          SliverToBoxAdapter(
            child: ConsultantDailySectionHeader(
              title: 'Öncelikli',
              count: priority.isEmpty ? null : priority.length,
              note: 'Geciken görev, geciken takip ve sıcak müşteri',
            ),
          ),
          if (priority.isEmpty)
            const SliverToBoxAdapter(
              child: ConsultantDailyInlineNote(
                icon: Icons.check_circle_outline_rounded,
                message:
                    'Şu an acil bir baskı yok — geciken görev/takip veya sıcak '
                    'müşteri bulunmuyor.',
              ),
            )
          else
            SliverList.builder(
              itemCount: priority.length,
              itemBuilder: (context, i) => _row(priority[i]),
            ),

          // ——— Günün akışı (kalanlar) ———
          SliverToBoxAdapter(
            child: ConsultantDailySectionHeader(
              title: 'Günün akışı',
              count: rest.isEmpty ? null : rest.length,
            ),
          ),
          if (rest.isEmpty)
            const SliverToBoxAdapter(
              child: ConsultantDailyInlineNote(
                message:
                    'Bekleyen başka görev veya müşteri kaydı yok. Düşük sinyalli '
                    'güncel müşteriler baskı oluşturmadığı için listelenmez.',
              ),
            )
          else
            SliverList.builder(
              itemCount: rest.length,
              itemBuilder: (context, i) => _row(rest[i]),
            ),
        ] else ...[
          // ——— Filtre / arama sonucu ———
          SliverToBoxAdapter(
            child: ConsultantDailySectionHeader(
              title: 'Sonuçlar',
              count: filtered.isEmpty ? null : filtered.length,
            ),
          ),
          if (filtered.isEmpty)
            const SliverToBoxAdapter(
              child: ConsultantDailyInlineNote(
                icon: Icons.filter_alt_off_rounded,
                message:
                    'Bu arama/filtre ile eşleşen kayıt yok. Bu kategori için '
                    'sunucuda tutulan veri bulunmuyor.',
              ),
            )
          else
            SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) => _row(filtered[i]),
            ),
        ],

        // ——— Axion Agent önerileri (kural tabanlı, onay gerektirir) ———
        if (showLanes)
          const SliverToBoxAdapter(child: AxionAgentDailySection()),

        // ——— Hızlı erişim (dürüst navigasyon kısayolları) ———
        if (showLanes) ...[
          const SliverToBoxAdapter(
            child: ConsultantDailySectionHeader(
              title: 'Hızlı erişim',
              note: 'Tek dokunuşla müşteri, görev, ilan ve mesaj akışına geç',
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                ConsultantDailyTokens.horizontal,
                0,
                ConsultantDailyTokens.horizontal,
                ConsultantDailyTokens.moduleGap,
              ),
              child: TourTarget(
                id: TourTargetId.gunumQuickAccess,
                child: ConsultantDashboardQuickNavGrid(),
              ),
            ),
          ),
        ],

        // ——— Dürüst kapsam notu ———
        if (showLanes && snapshot.entries.isNotEmpty)
          const SliverToBoxAdapter(
            child: ConsultantDailyInlineNote(
              icon: Icons.shield_outlined,
              message:
                  'Performans skoru, verimlilik trendi ve kaçırılan çağrı (iOS) '
                  'sunucuda tutulmadığı için gösterilmez. Müşteri sıcaklığı '
                  'kural tabanlı hesaplanır, AI değildir.',
            ),
          ),

        SliverToBoxAdapter(child: SizedBox(height: reserve)),
      ],
    );
  }
}
