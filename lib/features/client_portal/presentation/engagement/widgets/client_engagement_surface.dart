import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/client_engagement_actions.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/client_engagement_filter.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/client_engagement_types.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/providers/client_engagement_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/widgets/client_engagement_chrome.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/widgets/client_engagement_row.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/widgets/client_engagement_skeleton.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_chrome.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/session_avatar_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// İlgi & Etkileşim komuta yüzeyi (Screen 20) — premium, dürüst, hızlı.
class ClientEngagementSurface extends ConsumerStatefulWidget {
  const ClientEngagementSurface({super.key});

  @override
  ConsumerState<ClientEngagementSurface> createState() =>
      _ClientEngagementSurfaceState();
}

class _ClientEngagementSurfaceState
    extends ConsumerState<ClientEngagementSurface> {
  EngagementFilter _filter = EngagementFilter.all;
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
    return 112 * ratio.clamp(1.0, 1.38);
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(clientEngagementSnapshotProvider);
    final reserve = _dockReserve(context);

    return snapshotAsync.when(
      loading: () => const CustomScrollView(
        slivers: [SliverToBoxAdapter(child: ClientEngagementSkeleton())],
      ),
      error: (_, __) => CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: PremiumClientPortalHeader(
              title: 'İlgi & Etkileşim',
              subtitle: 'Kaydedilen ilgi ve son etkileşimler',
              verificationNote: null,
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: EmptyState(
                compact: true,
                grouped: true,
                premiumVisual: true,
                icon: Icons.cloud_off_rounded,
                title: 'Etkileşim yüzeyi yüklenemedi',
                subtitle: 'Bağlantınızı kontrol edip tekrar deneyin.',
                actionLabel: 'Yeniden dene',
                onAction: () => ClientEngagementActions.refresh(ref),
              ),
            ),
          ),
        ],
      ),
      data: (snapshot) => _buildData(context, snapshot, reserve),
    );
  }

  Widget _buildData(
    BuildContext context,
    ClientEngagementSnapshot snapshot,
    double reserve,
  ) {
    final searching = _search.trim().isNotEmpty;
    final filtered = filterEngagementEntries(
      snapshot.entries,
      query: _search,
      filter: _filter,
    );
    final showHistoryLane = _filter == EngagementFilter.all && !searching;

    return CustomScrollView(
      cacheExtent: 360,
      slivers: [
        SliverToBoxAdapter(
          child: PremiumClientPortalHeader(
            title: 'İlgi & Etkileşim',
            subtitle: snapshot.greetingName.isNotEmpty
                ? '${snapshot.greetingName} · kaydedilen ilgi ve son etkileşimler'
                : 'Kaydedilen ilgi ve son etkileşimler',
            verificationNote: snapshot.coverageNote,
            actions: snapshot.signedIn
                ? const [
                    Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: SessionAvatarButton(size: 38),
                    ),
                  ]
                : const [],
          ),
        ),
        SliverToBoxAdapter(
          child: ClientEngagementSummaryStrip(summary: snapshot.summary),
        ),
        SliverToBoxAdapter(
          child: PremiumClientPortalSearchRow(
            controller: _debouncedSearch.controller,
            hintText: 'Kanal, etkileşim veya durum ara',
          ),
        ),
        SliverToBoxAdapter(
          child: ClientEngagementFilterStrip(
            selected: _filter,
            onSelected: (f) {
              AppFeedback.selectionClick();
              setState(() => _filter = f);
            },
          ),
        ),
        SliverToBoxAdapter(
          child: PremiumClientSectionLabel(
            label: 'Etkileşim kanalları',
            secondary: filtered.isEmpty ? null : '${filtered.length} kanal',
          ),
        ),
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: ClientEngagementInlineNote(
              icon: Icons.filter_alt_off_rounded,
              message: searching || _filter != EngagementFilter.all
                  ? 'Bu arama/filtre ile eşleşen kanal yok. Bu kategori için '
                      'sunucuda tutulan kayıt bulunmuyor.'
                  : 'Açık etkileşim kanalı yok.',
            ),
          )
        else
          SliverList.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) => ClientEngagementRow(
              entry: filtered[index],
              onTap: () =>
                  ClientEngagementActions.open(context, ref, filtered[index]),
              onDetail: () => ClientEngagementActions.showDetailSheet(
                context,
                ref,
                filtered[index],
              ),
            ),
          ),

        // ——— İlgi geçmişi — dürüst kapsam (sunucuda izlenmiyor) ———
        if (showHistoryLane) ...[
          const SliverToBoxAdapter(
            child: PremiumClientSectionLabel(
              label: 'İlgi geçmişi',
              secondary: 'Henüz sunucuda tutulmuyor',
            ),
          ),
          const SliverToBoxAdapter(
            child: ClientEngagementInlineNote(
              icon: Icons.history_toggle_off_rounded,
              message:
                  'Görüntülenen ilan, favori ve son etkileşim geçmişi henüz '
                  'sunucuda tutulmuyor. Kanallar canlandıkça gerçek kayıtlarınız '
                  'burada görünecek; uydurma geçmiş gösterilmez.',
            ),
          ),
        ],

        SliverPadding(padding: EdgeInsets.only(bottom: reserve)),
      ],
    );
  }
}
