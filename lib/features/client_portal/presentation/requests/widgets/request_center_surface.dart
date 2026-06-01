import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_actions.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_filter.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_types.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/providers/request_center_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/widgets/request_center_chrome.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/widgets/request_center_row.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/widgets/request_center_skeleton.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_chrome.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/session_avatar_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Talep Merkezi komuta yüzeyi (Screen 23) — premium, dürüst, hızlı.
/// Kayıtlı talep altyapısı yokken gerçek kanallar + dürüst boş/"yakında" durumu.
class RequestCenterSurface extends ConsumerStatefulWidget {
  const RequestCenterSurface({super.key});

  @override
  ConsumerState<RequestCenterSurface> createState() =>
      _RequestCenterSurfaceState();
}

class _RequestCenterSurfaceState extends ConsumerState<RequestCenterSurface> {
  RequestCenterFilter _filter = RequestCenterFilter.all;
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
    final snapshotAsync = ref.watch(requestCenterSnapshotProvider);
    final reserve = _dockReserve(context);

    return snapshotAsync.when(
      loading: () => const CustomScrollView(
        slivers: [SliverToBoxAdapter(child: RequestCenterSkeleton())],
      ),
      error: (_, __) => CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: PremiumClientPortalHeader(
              title: 'Talep Merkezi',
              subtitle: 'Kayıtlı talepler ve sonraki adımlar',
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
                title: 'Talep merkezi yüklenemedi',
                subtitle: 'Bağlantınızı kontrol edip tekrar deneyin.',
                actionLabel: 'Yeniden dene',
                onAction: () => RequestCenterActions.refresh(ref),
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
    RequestCenterSnapshot snapshot,
    double reserve,
  ) {
    final searching = _search.trim().isNotEmpty;
    final filtered = filterRequestCenterEntries(
      snapshot.entries,
      query: _search,
      filter: _filter,
    );
    final showSavedLane = _filter == RequestCenterFilter.all && !searching;

    return CustomScrollView(
      cacheExtent: 360,
      slivers: [
        SliverToBoxAdapter(
          child: PremiumClientPortalHeader(
            title: 'Talep Merkezi',
            subtitle: snapshot.greetingName.isNotEmpty
                ? '${snapshot.greetingName} · kayıtlı talepler ve sonraki adımlar'
                : 'Kayıtlı talepler ve sonraki adımlar',
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
          child: RequestCenterSummaryStrip(summary: snapshot.summary),
        ),
        SliverToBoxAdapter(
          child: PremiumClientPortalSearchRow(
            controller: _debouncedSearch.controller,
            hintText: 'Talep adımı veya durum ara',
          ),
        ),
        SliverToBoxAdapter(
          child: RequestCenterFilterStrip(
            selected: _filter,
            onSelected: (f) {
              AppFeedback.selectionClick();
              setState(() => _filter = f);
            },
          ),
        ),
        SliverToBoxAdapter(
          child: PremiumClientSectionLabel(
            label: 'Talep adımları',
            secondary: filtered.isEmpty ? null : '${filtered.length} kanal',
          ),
        ),
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: RequestCenterInlineNote(
              icon: Icons.filter_alt_off_rounded,
              message: searching || _filter != RequestCenterFilter.all
                  ? 'Bu arama/filtre ile eşleşen adım yok. Bu kategori için '
                      'sunucuda tutulan kayıt bulunmuyor.'
                  : 'Açık talep adımı yok.',
            ),
          )
        else
          SliverList.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) => RequestCenterRow(
              entry: filtered[index],
              onTap: () =>
                  RequestCenterActions.open(context, ref, filtered[index]),
              onDetail: () => RequestCenterActions.showDetailSheet(
                context,
                ref,
                filtered[index],
              ),
            ),
          ),

        // ——— Kayıtlı talepler — dürüst kapsam (sunucuda izlenmiyor) ———
        if (showSavedLane) ...[
          const SliverToBoxAdapter(
            child: PremiumClientSectionLabel(
              label: 'Kayıtlı talepler',
              secondary: 'Henüz sunucuda tutulmuyor',
            ),
          ),
          const SliverToBoxAdapter(
            child: RequestCenterInlineNote(
              icon: Icons.history_toggle_off_rounded,
              message:
                  'Kaydedilen talep, talep durumu ve danışman eşleşmesi henüz '
                  'sunucuda tutulmuyor. Talep altyapısı aktifleştiğinde gerçek '
                  'talepleriniz burada görünecek; uydurma talep gösterilmez.',
            ),
          ),
        ],

        SliverPadding(padding: EdgeInsets.only(bottom: reserve)),
      ],
    );
  }
}
