import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';

Future<void> showUpgradeBottomSheet(
  BuildContext context, {
  required String feature,
}) async {
  await showPremiumModalBottomSheet<void>(
    context: context,
    builder: (ctx) => _UpgradeBottomSheet(feature: feature),
  );
}

class _UpgradeBottomSheet extends StatelessWidget {
  const _UpgradeBottomSheet({required this.feature});

  final String feature;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final title = _title(feature);
    final body = _body(feature);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space4,
        DesignTokens.space5,
        DesignTokens.space5 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ext.textSecondary,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            _featureLine(feature),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ext.textTertiary,
                ),
          ),
          const SizedBox(height: DesignTokens.space5),
          FilledButton(
            onPressed: () {
              AnalyticsService.instance.logEvent(
                AnalyticsEvents.upgradeClicked,
                {AnalyticsEvents.paramFeature: feature},
              );
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: ext.accent,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Upgrade to PRO'),
          ),
          const SizedBox(height: DesignTokens.space2),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Later',
              style: TextStyle(color: ext.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  static String _title(String feature) {
    switch (feature) {
      case 'ai_analysis':
        return 'AI onerileri bu ay icin doldu';
      case 'revenue_insights':
        return 'Bu gorunum daha derin sinyaller tasiyor';
      default:
        return 'You are using this feature very actively 🔥';
    }
  }

  static String _body(String feature) {
    switch (feature) {
      case 'ai_analysis':
        return 'Sinirsiz kullanim icin PRO';
      case 'revenue_insights':
        return 'Upgrade to PRO to continue tracking more customers and sales opportunities';
      default:
        return 'Upgrade to PRO to continue tracking more customers and sales opportunities';
    }
  }

  static String _featureLine(String feature) {
    switch (feature) {
      case 'ai_analysis':
        return 'Temel CRM akisi devam eder; yalnizca AI onerileri bir sonraki doneme kadar durur.';
      case 'revenue_insights':
        return 'Tam gelir icgoruleri, ranking ve ileri AI onerileri PRO ile acilir.';
      default:
        return 'PRO unlocks higher limits and deeper CRM intelligence.';
    }
  }
}
