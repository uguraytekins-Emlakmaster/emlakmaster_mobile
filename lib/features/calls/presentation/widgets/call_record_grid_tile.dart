import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_outcome_style.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';

/// Izgara görünümü — kompakt çağrı kartı.
class CallRecordGridTile extends StatelessWidget {
  const CallRecordGridTile({
    super.key,
    required this.title,
    required this.directionDuration,
    required this.outcomeLabel,
    this.onTap,
  });

  final String title;
  final String directionDuration;
  final String outcomeLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tone = CallOutcomeStyle.resolve(ext, outcomeLabel);
    return PremiumSurfaceCard(
      padding: const EdgeInsets.all(DesignTokens.space2 + 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              directionDuration,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ext.textSecondary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tone.fill,
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                border: Border.all(color: tone.border),
              ),
              child: Text(
                outcomeLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: tone.text,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
