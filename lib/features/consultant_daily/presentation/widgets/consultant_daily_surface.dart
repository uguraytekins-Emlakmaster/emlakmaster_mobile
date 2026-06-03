import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/services/onboarding_store.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/consultant_daily_actions.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/consultant_daily_tokens.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/providers/consultant_daily_provider.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_filter.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_types.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/widgets/consultant_daily_chrome.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/widgets/consultant_daily_row.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/widgets/consultant_daily_skeleton.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/tour/coach_mark_tour.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/tour/consultant_tour_providers.dart';
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

  // İlk giriş eğitim turu hedefleri (gerçek widget'lara GlobalKey ile bağlı).
  final GlobalKey _tourDeckKey = GlobalKey();
  final GlobalKey _tourControlsKey = GlobalKey();
  final GlobalKey _tourQuickNavKey = GlobalKey();
  bool _tourAutoChecked = false;

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
    CoachMarkTour.dismiss();
    _debouncedSearch.dispose();
    super.dispose();
  }

  /// Tur adımları — yalnızca güvenilir biçimde ekranda bulunan öğeler.
  List<CoachMarkStep> _tourSteps() {
    return [
      CoachMarkStep(
        targetKey: _tourDeckKey,
        icon: Icons.dashboard_rounded,
        title: 'Günün komuta merkezi',
        body: 'Günlük özet, aciliyet sinyali ve müşteri baskısını tek bakışta '
            'buradan görürsün.',
      ),
      CoachMarkStep(
        targetKey: _tourControlsKey,
        icon: Icons.tune_rounded,
        title: 'Akıllı arama & filtre',
        body: 'Görev, müşteri veya durumu hızlıca ara; öncelik ve geciken gibi '
            'filtrelerle listeyi daralt.',
      ),
      CoachMarkStep(
        targetKey: _tourQuickNavKey,
        icon: Icons.grid_view_rounded,
        title: 'Hızlı erişim',
        body: 'Müşteri, görev, ilan ve mesaj akışına tek dokunuşla geç.',
      ),
    ];
  }

  void _startTour({required bool markCompletedOnClose}) {
    if (CoachMarkTour.isShowing) return;
    CoachMarkTour.show(
      context,
      steps: _tourSteps(),
      onCompleted: () {
        if (markCompletedOnClose) {
          OnboardingStore.instance.setConsultantTourCompleted();
        }
      },
    );
  }

  void _maybeAutoStartTour() {
    if (_tourAutoChecked) return;
    _tourAutoChecked = true;
    if (OnboardingStore.instance.consultantTourCompletedSync) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (OnboardingStore.instance.consultantTourCompletedSync) return;
      _startTour(markCompletedOnClose: true);
    });
  }

  double _dockReserve(BuildContext context) {
    final ts = MediaQuery.textScalerOf(context);
    final ratio = ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
    return ConsultantDailyTokens.bottomReserve * ratio.clamp(1.0, 1.38);
  }

  @override
  Widget build(BuildContext context) {
    // Ayarlar'dan "Turu tekrar göster" istendiğinde turu yeniden başlat.
    ref.listen<int>(consultantTourReplayProvider, (prev, next) {
      if (prev == null || next == prev) return;
      if (!mounted) return;
      _startTour(markCompletedOnClose: true);
    });

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
    // Veri hazır + ilk frame sonrası: eğitim turunu bir kez tetikle.
    _maybeAutoStartTour();
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
          child: KeyedSubtree(
            key: _tourDeckKey,
            child: ConsultantDailyCommandDeck(
              subtitle: subtitle,
              coverageNote: snapshot.coverageNote,
              summary: snapshot.summary,
              urgentSignals: priority.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: KeyedSubtree(
            key: _tourControlsKey,
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
        ),

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

        // ——— Hızlı erişim (dürüst navigasyon kısayolları) ———
        if (showLanes) ...[
          const SliverToBoxAdapter(
            child: ConsultantDailySectionHeader(
              title: 'Hızlı erişim',
              note: 'Tek dokunuşla müşteri, görev, ilan ve mesaj akışına geç',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ConsultantDailyTokens.horizontal,
                0,
                ConsultantDailyTokens.horizontal,
                ConsultantDailyTokens.moduleGap,
              ),
              child: KeyedSubtree(
                key: _tourQuickNavKey,
                child: const ConsultantDashboardQuickNavGrid(),
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
