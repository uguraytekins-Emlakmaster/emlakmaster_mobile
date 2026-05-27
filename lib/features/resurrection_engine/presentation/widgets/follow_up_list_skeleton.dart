import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/consultant_follow_up_tokens.dart';
import 'package:flutter/material.dart';

class FollowUpListSkeleton extends StatelessWidget {
  const FollowUpListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index.isOdd) {
            return const SizedBox(height: 6);
          }
          return Container(
            height: 96,
            margin: EdgeInsets.only(
              left: ConsultantFollowUpTokens.horizontal,
              right: ConsultantFollowUpTokens.horizontal,
              bottom: index == itemCount * 2 - 2 ? ConsultantFollowUpTokens.sectionGap : 0,
            ),
            decoration: BoxDecoration(
              color: ext.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: ext.border.withValues(alpha: 0.25)),
            ),
            padding: const EdgeInsets.all(10),
            child: const Row(
              children: [
                ShimmerPlaceholder(width: 36, height: 36),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerPlaceholder(
                        width: double.infinity,
                        height: 12,
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                      SizedBox(height: 6),
                      ShimmerPlaceholder(
                        width: 140,
                        height: 10,
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        childCount: itemCount * 2,
      ),
    );
  }
}
