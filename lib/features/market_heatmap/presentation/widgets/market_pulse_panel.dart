import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/app_toaster.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/external_listings/data/client_external_listings_sync_service.dart';
import 'package:emlakmaster_mobile/features/external_listings/data/external_listings_sync_outcome.dart';
import 'package:emlakmaster_mobile/features/external_listings/presentation/providers/external_listings_provider.dart';
import 'package:emlakmaster_mobile/features/market_heatmap/presentation/widgets/market_pulse_investment_listing_tile.dart';
import 'package:emlakmaster_mobile/features/market_heatmap/presentation/widgets/market_pulse_listings_meta.dart';
import 'package:emlakmaster_mobile/features/market_heatmap/presentation/widgets/market_pulse_region_comparison_cards.dart';
import 'package:firebase_core/firebase_core.dart'
    show Firebase, FirebaseException;
import 'package:emlakmaster_mobile/shared/widgets/error_state.dart';
import 'package:emlakmaster_mobile/shared/widgets/fade_in_on_mount.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// İstemci tarafı ilan çekme hataları (Firestore / ağ).
String marketPulseClientSyncErrorMessage(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firestore izni yok. firestore.rules güncellemesini deploy edin: '
            'firebase deploy --only firestore:rules';
      case 'unavailable':
        return 'Ağ veya Firestore geçici olarak kullanılamıyor.';
      default:
        return 'Güncelleme başarısız (${error.code}): ${error.message ?? ''}';
    }
  }
  if (error is UnsupportedError) {
    final m = error.message;
    if (m != null && m.isNotEmpty) return m;
    return 'Bu ortamda desteklenmiyor.';
  }
  return error.toString().split('\n').first;
}

/// Dashboard: "Market Pulse" – Bölgesel talep + harici sitelerden son atılan ilanlar.
class MarketPulsePanel extends ConsumerWidget {
  const MarketPulsePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final surface = ext.surface;
    final border = ext.border;
    final textPrimary = ext.textPrimary;
    final textSecondary = ext.textSecondary;
    final role = ref.watch(displayRoleOrNullProvider);
    if (role == null || !FeaturePermission.canViewOpportunityRadar(role)) {
      return const SizedBox.shrink();
    }
    final async = ref.watch(marketHeatmapProvider);
    final listingsAsync = ref.watch(externalListingsStreamProvider);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.show_chart_rounded,
                          color: ext.accent, size: 22),
                      const SizedBox(width: DesignTokens.space2),
                      Text(
                        'Market Pulse',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30, top: 2),
                    child: Text(
                      'Yatırım istihbaratı — bölgesel akış',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                ],
              ),
              const _MarketPulseListingActions(),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bölge analizi',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.15,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Karşılaştırmalı talep · fiyat bandı · pazar baskınlığı',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          async.when(
            data: (regions) => FadeInOnMount(
              child: MarketPulseRegionComparisonStrip(
                regions: regions,
                onRegionTap: (region) {
                  HapticFeedback.selectionClick();
                  context.push(
                    AppRouter.regionInsightPath(region.regionId),
                    extra: region,
                  );
                },
              ),
            ),
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: MarketPulseRegionComparisonStrip.skeleton(context),
            ),
            error: (e, _) => ErrorState(
              message: 'Bölgesel talep yüklenemedi.',
              onRetry: () => ref.invalidate(marketHeatmapProvider),
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Divider(height: 1, color: border),
          const SizedBox(height: DesignTokens.space2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Son işlemler — çoklu kaynak',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Sahibinden · Emlakjet · Hepsi Emlak · canlı + örnek',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          listingsAsync.when(
            data: (listings) {
              if (listings.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liste boş. Mobil istemci çoğu sitede Cloudflare nedeniyle ham HTML alamaz.',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Çözüm: GitHub Actions + Playwright ile saatlik çekim → Firestore (ücretsiz kota). '
                        'Ayrıntı: doc/GITHUB_ACTIONS_LISTINGS_INGEST.md',
                        style: TextStyle(
                            color: textSecondary, fontSize: 11, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Üstte «Örnek yükle» ile örnek ilanları veya «Güncelle» ile istemci senkronunu deneyin.',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cihazda kontrol: USB ile telefon/tablet bağlayıp flutter run veya yükleme ile doğrulayın.',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final list = listings.take(10).toList();
              // FadeInUp × 10 + stagger GPU/bellek yükünü artırıyordu (OOM riski); statik liste yeterli.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...list.map(
                    (e) => MarketPulseInvestmentListingTile(listing: e),
                  ),
                  const SizedBox(height: 8),
                  MarketPulseListingsMeta(
                    listings: list,
                    textSecondary: textSecondary,
                  ),
                ],
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: List.generate(
                  3,
                  (_) => const MarketPulseListingTileSkeleton(),
                ),
              ),
            ),
            error: (e, _) => ErrorState(
              message: 'İlanlar yüklenemedi.',
              onRetry: () => ref.invalidate(externalListingsStreamProvider),
            ),
          ),
        ],
      ),
    );
  }
}

/// Güncelle + örnek yükle (Cloudflare / SPA nedeniyle canlı çekme sık başarısız olur).
class _MarketPulseListingActions extends ConsumerStatefulWidget {
  const _MarketPulseListingActions();

  @override
  ConsumerState<_MarketPulseListingActions> createState() =>
      _MarketPulseListingActionsState();
}

class _MarketPulseListingActionsState
    extends ConsumerState<_MarketPulseListingActions> {
  bool _loading = false;
  bool _demoLoading = false;

  static Future<ExternalListingsSyncOutcome>? _inFlight;

  Future<void> _fetchNow() async {
    if (_loading || _demoLoading || _inFlight != null) return;
    if (Firebase.apps.isEmpty) {
      AppToaster.error(
        context,
        'Firebase başlatılamadı. Uygulamayı yeniden başlatın veya yapılandırmayı kontrol edin.',
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    _inFlight = ClientExternalListingsSyncService.syncNow().whenComplete(() {
      _inFlight = null;
    });
    try {
      final outcome = await _inFlight!;
      if (mounted) {
        ref.invalidate(externalListingsStreamProvider);
        if (outcome.written > 0) {
          if (outcome.usedDemoFallback) {
            AppToaster.success(
              context,
              'Liste hazır: ${outcome.written} ilan (örnek veri; canlı siteler otomatik çekmeye izin vermiyor).',
            );
          } else {
            AppToaster.success(
              context,
              '${outcome.liveWritten} ilan güncellendi.',
            );
          }
        } else {
          AppToaster.error(
            context,
            'İlan yazılamadı. İnternet veya Firestore izinlerini kontrol edin.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToaster.error(context, marketPulseClientSyncErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _seedDemo() async {
    if (_loading || _demoLoading) return;
    if (Firebase.apps.isEmpty) return;
    setState(() => _demoLoading = true);
    try {
      final n = await ClientExternalListingsSyncService.seedDemoListings();
      if (mounted) {
        ref.invalidate(externalListingsStreamProvider);
        AppToaster.success(context, '$n örnek ilan eklendi (kaynak: örnek).');
      }
    } catch (e) {
      if (mounted) {
        AppToaster.error(context, marketPulseClientSyncErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _demoLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final busy = _loading || _demoLoading;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: busy ? null : _fetchNow,
          icon: _loading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ext.accent,
                  ),
                )
              : Icon(Icons.refresh_rounded,
                  size: 18, color: ext.accent),
          label: Text(
            _loading ? 'Güncelleniyor…' : 'İlanları güncelle',
            style: TextStyle(fontSize: 11, color: ext.accent),
          ),
        ),
        TextButton(
          onPressed: busy ? null : _seedDemo,
          child: Text(
            _demoLoading ? '…' : 'Örnek yükle',
            style: TextStyle(
              fontSize: 11,
              color: ext.accent.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
