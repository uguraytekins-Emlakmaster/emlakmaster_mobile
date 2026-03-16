import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/app_toaster.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/external_listings/domain/entities/external_listing_entity.dart';
import 'package:emlakmaster_mobile/features/external_listings/presentation/providers/external_listings_provider.dart';
import 'package:emlakmaster_mobile/shared/widgets/error_state.dart';
import 'package:emlakmaster_mobile/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dashboard: "Market Pulse" – Bölgesel talep + harici sitelerden son atılan ilanlar.
class MarketPulsePanel extends ConsumerWidget {
  const MarketPulsePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(displayRoleOrNullProvider);
    if (role == null || !FeaturePermission.canViewOpportunityRadar(role)) {
      return const SizedBox.shrink();
    }
    final async = ref.watch(marketHeatmapProvider);
    final listingsAsync = ref.watch(externalListingsStreamProvider);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: DesignTokens.borderDark.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: DesignTokens.primary, size: 22),
              const SizedBox(width: DesignTokens.space2),
              Expanded(
                child: Text(
                  'Market Pulse',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: DesignTokens.textPrimaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const _FetchListingsNowButton(),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          async.when(
            data: (regions) {
              if (regions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Bölgesel talep hesaplanıyor.',
                    style: TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 12),
                  ),
                );
              }
              return Column(
                children: regions.map((e) => _RegionRow(region: e)).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SkeletonLoader(width: 80, height: 16, borderRadius: BorderRadius.all(Radius.circular(4))),
                  SizedBox(width: 16),
                  SkeletonLoader(width: 60, height: 16, borderRadius: BorderRadius.all(Radius.circular(4))),
                  Spacer(),
                  SkeletonLoader(width: 36, height: 16, borderRadius: BorderRadius.all(Radius.circular(4))),
                ],
              ),
            ),
            error: (e, _) => ErrorState(
              message: 'Bölgesel talep yüklenemedi.',
              onRetry: () => ref.invalidate(marketHeatmapProvider),
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          const Divider(height: 1, color: DesignTokens.borderDark),
          const SizedBox(height: DesignTokens.space2),
          Text(
            'Son atılan ilanlar (sahibinden / emlakjet / hepsi emlak)',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: DesignTokens.textSecondaryDark,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: DesignTokens.space2),
          listingsAsync.when(
            data: (listings) {
              if (listings.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Bu bölge için henüz ilan yok. Ayarlardan şehir/ilçe seçin; ilanlar arka planda çekilir.',
                    style: TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 12),
                  ),
                );
              }
              final list = listings.take(10).toList();
              return Column(
                children: List.generate(list.length, (i) => FadeInUp(
                  duration: DesignTokens.durationNormal,
                  delay: Duration(milliseconds: i * 60),
                  child: _ListingTile(listing: list[i]),
                )),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: List.generate(3, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const SkeletonLoader(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(6))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SkeletonLoader(height: 12, width: double.infinity, borderRadius: BorderRadius.all(Radius.circular(4))),
                            const SizedBox(height: 6),
                            const SkeletonLoader(height: 10, width: 120, borderRadius: BorderRadius.all(Radius.circular(4))),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
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

/// Callable fetchListingsNow tetikleyen buton.
class _FetchListingsNowButton extends ConsumerStatefulWidget {
  const _FetchListingsNowButton();

  @override
  ConsumerState<_FetchListingsNowButton> createState() => _FetchListingsNowButtonState();
}

class _FetchListingsNowButtonState extends ConsumerState<_FetchListingsNowButton> {
  bool _loading = false;

  Future<void> _fetchNow() async {
    if (_loading) return;
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      await functions.httpsCallable('fetchListingsNow').call();
      if (mounted) {
        ref.invalidate(externalListingsStreamProvider);
        AppToaster.success(context, 'İlanlar güncelleniyor. Kısa süre içinde listelenecek.');
      }
    } catch (e) {
      if (mounted) {
        AppToaster.error(context, 'Güncelleme başarısız: ${e.toString().split('\n').first}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _loading ? null : _fetchNow,
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.primary),
            )
          : const Icon(Icons.refresh_rounded, size: 18, color: DesignTokens.primary),
      label: Text(
        _loading ? 'Güncelleniyor…' : 'İlanları güncelle',
        style: const TextStyle(fontSize: 12, color: DesignTokens.primary),
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.listing});
  final ExternalListingEntity listing;

  @override
  Widget build(BuildContext context) {
    final price = listing.priceText ?? (listing.priceValue != null ? '${listing.priceValue!.toStringAsFixed(0)} ₺' : '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () {
          final uri = Uri.tryParse(listing.link);
          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (listing.imageUrl != null && listing.imageUrl!.isNotEmpty)
              Hero(
                tag: 'listing_${listing.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: listing.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => ShimmerPlaceholder(
                      width: 48,
                      height: 48,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.home_rounded, color: DesignTokens.textTertiaryDark),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.home_rounded, color: DesignTokens.textTertiaryDark),
              ),
            const SizedBox(width: DesignTokens.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      color: DesignTokens.textPrimaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (listing.district != null)
                        Text(
                          listing.district!,
                          style: const TextStyle(
                            color: DesignTokens.textTertiaryDark,
                            fontSize: 11,
                          ),
                        ),
                      if (listing.district != null && price.isNotEmpty) const Text(' · ', style: TextStyle(color: DesignTokens.textTertiaryDark, fontSize: 11)),
                      if (price.isNotEmpty)
                        Text(
                          price,
                          style: const TextStyle(
                            color: DesignTokens.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: DesignTokens.surfaceDarkElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      listing.source.label,
                      style: const TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, size: 16, color: DesignTokens.textTertiaryDark),
          ],
        ),
      ),
    );
  }
}

class _RegionRow extends StatelessWidget {
  const _RegionRow({required this.region});
  final RegionHeatmapScore region;

  @override
  Widget build(BuildContext context) {
    final pct = (region.demandScore * 100).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              region.regionName,
              style: const TextStyle(color: DesignTokens.textPrimaryDark, fontSize: 13),
            ),
          ),
          if (region.budgetSegment != null)
            Text(
              region.budgetSegment!,
              style: const TextStyle(color: DesignTokens.textTertiaryDark, fontSize: 11),
            ),
          const SizedBox(width: 8),
          Text(
            '%$pct',
            style: TextStyle(
              color: region.demandScore >= 0.7 ? DesignTokens.success : DesignTokens.textSecondaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
