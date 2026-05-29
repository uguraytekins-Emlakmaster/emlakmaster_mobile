import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/client_portal_tokens.dart';
import 'package:flutter/material.dart';

class ClientPortalSkeleton extends StatelessWidget {
  const ClientPortalSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClientPortalTokens.horizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerPlaceholder(width: 200, height: 22),
              const SizedBox(height: 8),
              const ShimmerPlaceholder(width: 260, height: 14),
              const SizedBox(height: 10),
              ShimmerPlaceholder(
                width: double.infinity,
                height: ClientPortalTokens.summaryStripHeight,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              const SizedBox(height: 10),
              ShimmerPlaceholder(
                width: double.infinity,
                height: ClientPortalTokens.searchBarHeight,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < 3; i++) ...[
                ShimmerPlaceholder(
                  width: double.infinity,
                  height: 118,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                const SizedBox(height: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}
