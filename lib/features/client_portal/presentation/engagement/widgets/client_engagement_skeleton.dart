import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/client_portal_tokens.dart';
import 'package:flutter/material.dart';

/// Hafif yükleme iskeleti — sonsuz shimmer yok, sabit blok.
class ClientEngagementSkeleton extends StatelessWidget {
  const ClientEngagementSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    Widget bar(double h, double w) => Container(
          height: h,
          width: w,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: ext.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalTokens.horizontal,
        18,
        ClientPortalTokens.horizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(20, 160),
          bar(12, 240),
          const SizedBox(height: 10),
          bar(ClientPortalTokens.summaryStripHeight, double.infinity),
          const SizedBox(height: 10),
          for (var i = 0; i < 4; i++) bar(70, double.infinity),
        ],
      ),
    );
  }
}
