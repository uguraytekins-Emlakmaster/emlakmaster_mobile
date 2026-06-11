import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';

/// Danışman kabuğunda alt menüde olmayan hedefler — hafif, tek elle.
Future<void> showConsultantMoreSheet(
  BuildContext context, {
  required void Function(int pageIndex) onSelectPage,
}) {
  return showPremiumModalBottomSheet<void>(
    context: context,
    builder: (ctx) => _ConsultantMoreSheetBody(onSelectPage: onSelectPage),
  );
}

class _ConsultantMoreSheetBody extends StatelessWidget {
  const _ConsultantMoreSheetBody({required this.onSelectPage});

  final void Function(int pageIndex) onSelectPage;

  static const _destinations = <_MoreDestination>[
    _MoreDestination(
      pageIndex: 3,
      icon: Icons.home_work_rounded,
      labelKey: 'nav_listings',
      subtitleKey: 'more_listings_sub',
    ),
    _MoreDestination(
      pageIndex: 4,
      icon: Icons.replay_rounded,
      labelKey: 'nav_followup',
      subtitleKey: 'more_followup_sub',
    ),
    _MoreDestination(
      pageIndex: 6,
      icon: Icons.settings_rounded,
      labelKey: 'nav_settings',
      subtitleKey: 'more_settings_sub',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space2,
        DesignTokens.space4,
        DesignTokens.space4 + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PremiumBottomSheetHandle(),
          Text(
            l10n.t('nav_more'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
          ),
          const SizedBox(height: DesignTokens.space1),
          Text(
            l10n.t('more_subtitle'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ext.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: DesignTokens.space4),
          for (var i = 0; i < _destinations.length; i++) ...[
            _MoreTile(
              destination: _destinations[i],
              onTap: () {
                AppFeedback.lightImpact();
                Navigator.pop(context);
                onSelectPage(_destinations[i].pageIndex);
              },
            ),
            if (i < _destinations.length - 1)
              Divider(
                height: 1,
                color: ext.border.withValues(alpha: 0.35),
              ),
          ],
        ],
      ),
    );
  }
}

class _MoreDestination {
  const _MoreDestination({
    required this.pageIndex,
    required this.icon,
    required this.labelKey,
    required this.subtitleKey,
  });

  final int pageIndex;
  final IconData icon;
  final String labelKey;
  final String subtitleKey;
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.destination,
    required this.onTap,
  });

  final _MoreDestination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: DesignTokens.space3,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: premium.champagneGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(
                    color: premium.champagneGold.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(
                  destination.icon,
                  color: premium.champagneGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t(destination.labelKey),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.t(destination.subtitleKey),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ext.textSecondary,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: premium.champagneGoldMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
