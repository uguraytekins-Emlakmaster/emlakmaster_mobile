import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:flutter/material.dart';

class AdminCommandSkeleton extends StatelessWidget {
  const AdminCommandSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: AdminCommandTokens.topInset),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AdminCommandTokens.horizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerPlaceholder(width: 180, height: 18),
              const SizedBox(height: 6),
              const ShimmerPlaceholder(width: 240, height: 12),
              const SizedBox(height: 10),
              ShimmerPlaceholder(
                width: double.infinity,
                height: AdminCommandTokens.summaryStripHeight,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < 3; i++) ...[
                ShimmerPlaceholder(
                  width: double.infinity,
                  height: AdminCommandTokens.urgentBlockHeight,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                const SizedBox(height: 6),
              ],
            ],
          ),
        ),
        SizedBox(height: ext.surface == Colors.transparent ? 8 : 8),
      ]),
    );
  }
}
