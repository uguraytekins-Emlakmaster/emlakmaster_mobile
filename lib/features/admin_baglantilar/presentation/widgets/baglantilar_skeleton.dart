import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/admin_baglantilar_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:flutter/material.dart';

class BaglantilarLoadingSkeleton extends StatelessWidget {
  const BaglantilarLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AdminBaglantilarTokens.horizontal,
        AdminCommandTokens.headerMetrics(context).topInset,
        AdminBaglantilarTokens.horizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bar(width: 200, height: 22, color: ext.border),
          const SizedBox(height: 8),
          _Bar(width: 300, height: 14, color: ext.border),
          const SizedBox(height: 16),
          _Bar(width: double.infinity, height: 52, color: ext.border),
          const SizedBox(height: 12),
          _Bar(width: double.infinity, height: 38, color: ext.border),
          const SizedBox(height: 12),
          for (var i = 0; i < 4; i++) ...[
            _Bar(width: double.infinity, height: 76, color: ext.border),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
