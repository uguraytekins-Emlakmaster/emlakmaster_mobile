import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
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
      pageIndex: 1,
      icon: Icons.forum_rounded,
      label: ProductLabels.messageCenter,
      subtitle: 'Ekip sohbeti ve bildirimler',
    ),
    _MoreDestination(
      pageIndex: 4,
      icon: Icons.home_work_rounded,
      label: ProductLabels.listings,
      subtitle: 'Portföy ve ilan yönetimi',
    ),
    _MoreDestination(
      pageIndex: 5,
      icon: Icons.replay_rounded,
      label: ProductLabels.followUp,
      subtitle: 'Takip ve yeniden temas',
    ),
    _MoreDestination(
      pageIndex: 7,
      icon: Icons.settings_rounded,
      label: ProductLabels.settings,
      subtitle: 'Hesap ve uygulama ayarları',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
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
            ProductLabels.consultantMore,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
          ),
          const SizedBox(height: DesignTokens.space1),
          Text(
            'Diğer çalışma alanları',
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
    required this.label,
    required this.subtitle,
  });

  final int pageIndex;
  final IconData icon;
  final String label;
  final String subtitle;
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
                  color: ext.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(
                    color: ext.accent.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  destination.icon,
                  color: ext.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destination.subtitle,
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
                color: ext.textTertiary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
