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
        padding: EdgeInsets.fromLTRB(
          AdminCommandTokens.horizontal,
          AdminCommandTokens.topInset,
          AdminCommandTokens.horizontal,
          AdminCommandTokens.sectionGap,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerPlaceholder(width: 200, height: 22),
            const SizedBox(height: 8),
            ShimmerPlaceholder(width: 260, height: 14),
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
