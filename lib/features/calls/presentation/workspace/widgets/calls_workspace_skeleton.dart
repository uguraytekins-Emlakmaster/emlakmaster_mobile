import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/consultant_calls_tokens.dart';
import 'package:flutter/material.dart';

/// Hafif yükleme iskeleti — sonsuz shimmer yok.
class CallsWorkspaceSkeleton extends StatelessWidget {
  const CallsWorkspaceSkeleton({super.key});

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
        ConsultantCallsTokens.horizontal,
        16,
        ConsultantCallsTokens.horizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(18, 150),
          bar(11, 240),
          const SizedBox(height: 10),
          bar(52, double.infinity),
          const SizedBox(height: 8),
          bar(38, double.infinity),
          const SizedBox(height: 10),
          for (var i = 0; i < 5; i++) bar(58, double.infinity),
        ],
      ),
    );
  }
}
