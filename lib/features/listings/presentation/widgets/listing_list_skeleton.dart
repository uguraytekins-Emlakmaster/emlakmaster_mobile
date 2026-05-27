import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/consultant_listings_tokens.dart';
import 'package:flutter/material.dart';

/// İlan listesi yükleme iskeleti — kompakt satırlar.
class ListingListSkeleton extends StatelessWidget {
  const ListingListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantListingsTokens.horizontal,
        0,
        ConsultantListingsTokens.horizontal,
        ConsultantListingsTokens.sectionGap,
      ),
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: ext.card.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                border: Border.all(color: ext.border.withValues(alpha: 0.25)),
              ),
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const ShimmerPlaceholder(width: 52, height: 52),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShimmerPlaceholder(
                          width: double.infinity,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        ShimmerPlaceholder(
                          width: 120,
                          height: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < itemCount - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
