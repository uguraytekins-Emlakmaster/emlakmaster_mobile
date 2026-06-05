import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_color_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/consultant_calls_tokens.dart';
import 'package:flutter/material.dart';

/// Compact section label — matches Günüm executive DNA.
class ConsultantCallsSectionHeader extends StatelessWidget {
  const ConsultantCallsSectionHeader({
    super.key,
    required this.label,
    this.subtitle,
    this.icon,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: ConsultantCallsTokens.chromeGap),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: premium.champagneGold,),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: PremiumColorTokens.champagneGoldLight,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.85,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: ext.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
