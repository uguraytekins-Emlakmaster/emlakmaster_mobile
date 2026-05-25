import 'package:emlakmaster_mobile/screens/consultant_dashboard/consultant_dashboard_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_color_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:flutter/material.dart';

/// Executive section label — gold rail + optional subtitle.
class ConsultantDashboardSectionHeader extends StatelessWidget {
  const ConsultantDashboardSectionHeader({
    super.key,
    required this.label,
    this.subtitle,
    this.trailing,
    this.icon,
  });

  final String label;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final premium = PremiumThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        bottom: ConsultantDashboardTokens.sectionHeaderBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      PremiumColorTokens.champagneGoldLight,
                      premium.champagneGold,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: premium.champagneGold.withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (icon != null) ...[
                Icon(icon, size: 13, color: premium.champagneGold),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: PremiumColorTokens.champagneGoldLight,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.45,
                    height: 1.05,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 11),
              child: Text(
                subtitle!,
                style: TextStyle(
                  color: premium.champagneGoldMuted.withValues(alpha: 0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  letterSpacing: 0.15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
