import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_outcome_style.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/crm_call_operating_card.dart';
import 'package:flutter/material.dart';

/// Danışman / müşteri gruplu özet satırı — teknik ID yok.
class CallGroupSummaryTile extends StatelessWidget {
  const CallGroupSummaryTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.outcomeLabel,
    this.badgeLabel,
    this.leadingLetter,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String outcomeLabel;
  final String? badgeLabel;
  final String? leadingLetter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final outcome = CallOutcomeStyle.resolve(ext, outcomeLabel);
    final letter = (leadingLetter ?? title).trim();
    final initial =
        letter.isNotEmpty ? letter.substring(0, 1).toUpperCase() : '?';

    final body = Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.space3 + 2,
          DesignTokens.space3,
          DesignTokens.space3,
          DesignTokens.space3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ext.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: ext.accent.withValues(alpha: 0.28),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: TextStyle(
                  color: ext.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: ext.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badgeLabel != null && badgeLabel!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ext.surfaceElevated,
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusPill),
                            border: Border.all(
                              color: ext.border.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Text(
                            badgeLabel!,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: ext.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ext.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: outcome.fill,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusPill),
                      border: Border.all(color: outcome.border),
                    ),
                    child: Text(
                      outcomeLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: outcome.text,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );

    return CrmCallOperatingCard(
      dense: true,
      child: onTap == null
          ? body
          : Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap, child: body),
            ),
    );
  }
}
