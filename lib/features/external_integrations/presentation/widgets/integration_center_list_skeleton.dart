import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/consultant_integrations_tokens.dart';
import 'package:flutter/material.dart';

class IntegrationCenterListSkeleton extends StatelessWidget {
  const IntegrationCenterListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return SliverList.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          height: 108,
          margin: const EdgeInsets.fromLTRB(
            ConsultantIntegrationsTokens.horizontal,
            0,
            ConsultantIntegrationsTokens.horizontal,
            6,
          ),
          decoration: BoxDecoration(
            color: ext.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: ext.border.withValues(alpha: 0.25)),
          ),
          padding: const EdgeInsets.all(10),
          child: const Row(
            children: [
              ShimmerPlaceholder(width: 34, height: 34),
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
                      width: 180,
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
    );
  }
}
