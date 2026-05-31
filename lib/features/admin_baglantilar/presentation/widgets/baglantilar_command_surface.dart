import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/admin_baglantilar_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/baglantilar_actions.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/providers/baglantilar_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/utils/baglantilar_filter.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/utils/baglantilar_types.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/widgets/baglantilar_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/widgets/baglantilar_row.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/widgets/baglantilar_skeleton.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BaglantilarCommandSurface extends ConsumerStatefulWidget {
  const BaglantilarCommandSurface({super.key});

  @override
  ConsumerState<BaglantilarCommandSurface> createState() =>
      _BaglantilarCommandSurfaceState();
}

class _BaglantilarCommandSurfaceState
    extends ConsumerState<BaglantilarCommandSurface> {
  String _search = '';
  BaglantilarFilter _filter = BaglantilarFilter.all;

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(baglantilarSnapshotProvider);
    final canManage = ref.watch(canManagePlatformIntegrationsProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return snapshotAsync.when(
      loading: () => const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: BaglantilarLoadingSkeleton()),
        ],
      ),
      error: (_, __) => CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: PremiumBaglantilarHeader()),
          SliverFillRemaining(
            hasScrollBody: false,
            child: BaglantilarEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Bağlantı verisi yüklenemedi',
              message: 'Bağlantınızı kontrol edip tekrar deneyin.',
              onRetry: () => BaglantilarActions.retryLoad(ref),
            ),
          ),
        ],
      ),
      data: (snapshot) {
        final searching = _search.trim().isNotEmpty;

        if (snapshot.isEmpty) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PremiumBaglantilarHeader(
                  coverageNote: snapshot.coverageNote,
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: BaglantilarEmptyState(
                  title: 'Platform kaydı bulunamadı',
                  message:
                      'Entegrasyon kataloğu hazır olduğunda platformlar burada görünecek.',
                  actionLabel: 'Kurulum sihirbazı',
                  onAction: () => BaglantilarActions.openSetupWizard(context),
                ),
              ),
            ],
          );
        }

        final filtered = filterBaglantilarRows(
          snapshot.rows,
          query: _search,
          filter: _filter,
        );
        final showLanes = _filter == BaglantilarFilter.all && !searching;
        final intervention = showLanes
            ? filtered.where((r) => r.needsAction).toList(growable: false)
            : const <BaglantiRowViewModel>[];
        final primary = showLanes
            ? filtered.where((r) => !r.needsAction).toList(growable: false)
            : filtered;

        return CustomScrollView(
          cacheExtent: 600,
          slivers: [
            SliverToBoxAdapter(
              child: PremiumBaglantilarHeader(
                coverageNote: snapshot.coverageNote,
              ),
            ),
            SliverToBoxAdapter(
              child: BaglantilarSummaryStripView(summary: snapshot.summary),
            ),
            SliverToBoxAdapter(
              child: BaglantilarQuickRoutes(
                onSetupWizard: () =>
                    BaglantilarActions.openSetupWizard(context),
                onImport: () => BaglantilarActions.openImportHub(context),
                onMyListings: () =>
                    BaglantilarActions.openMyExternalListings(context),
                onOfficeAdmin: () =>
                    BaglantilarActions.openOfficeAdmin(context),
                onAudit: () => BaglantilarActions.openAudit(context),
              ),
            ),
            SliverToBoxAdapter(
              child: BaglantilarCompactSearch(
                hintText: 'Platform, durum veya sağlayıcı ara',
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            SliverToBoxAdapter(
              child: BaglantilarFilterStrip(
                selected: _filter,
                onSelected: (f) => setState(() => _filter = f),
              ),
            ),

            // ——— Müdahale gereken (yalnızca gerçek dikkat durumları) ———
            if (showLanes && intervention.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: BaglantilarSectionHeader(
                  title: 'Müdahale gereken',
                  note:
                      'Kurulum kaydı dikkat isteyen platformlar; önce bunları çözün.',
                ),
              ),
              SliverList.builder(
                itemCount: intervention.length,
                itemBuilder: (context, index) =>
                    _buildRow(context, intervention[index], canManage),
              ),
            ],

            // ——— Birincil bağlantı listesi ———
            SliverToBoxAdapter(
              child: BaglantilarSectionHeader(
                title: showLanes ? 'Tüm bağlantılar' : 'Bağlantılar',
                count: primary.isEmpty ? null : primary.length,
              ),
            ),
            if (primary.isEmpty)
              SliverToBoxAdapter(
                child: BaglantilarInlineEmpty(
                  message: searching || _filter != BaglantilarFilter.all
                      ? 'Bu arama/filtre ile eşleşen platform yok.'
                      : 'Tanımlı platform bağlantısı yok.',
                ),
              )
            else
              SliverList.builder(
                itemCount: primary.length,
                itemBuilder: (context, index) =>
                    _buildRow(context, primary[index], canManage),
              ),

            SliverPadding(
              padding: EdgeInsets.only(
                bottom: AdminBaglantilarTokens.bottomReserve + bottom,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRow(
    BuildContext context,
    BaglantiRowViewModel row,
    bool canManage,
  ) {
    return BaglantilarRow(
      viewModel: row,
      onTap: () => BaglantilarActions.openPrimary(
        context,
        canManage: canManage,
        row: row,
      ),
      onDetail: () => BaglantilarActions.showDetailSheet(context, row),
      onOpen: row.canImport
          ? () => BaglantilarActions.openMyExternalListings(context)
          : null,
      onConnect: row.canConnect
          ? () => BaglantilarActions.connect(
                context,
                canManage: canManage,
                platformId: row.platformId,
              )
          : null,
      onConfigure: row.canConfigure
          ? () => BaglantilarActions.configure(
                context,
                canManage: canManage,
                platformId: row.platformId,
              )
          : null,
      onImport:
          row.canImport ? () => BaglantilarActions.openImportHub(context) : null,
      onRetry: row.canRetry
          ? () => BaglantilarActions.retry(
                context,
                ref,
                canManage: canManage,
                platformName: row.platformName,
              )
          : null,
      onOfficeAdmin: () => BaglantilarActions.openOfficeAdmin(context),
    );
  }
}
