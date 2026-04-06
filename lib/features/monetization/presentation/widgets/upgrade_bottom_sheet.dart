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
            'You are using this feature very actively 🔥',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Text(
            'Upgrade to PRO to continue tracking more customers and sales opportunities',
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

  static String _featureLine(String feature) {
    switch (feature) {
      case 'call_recording':
        return 'Phone call continues normally; only CRM call tracking is limited.';
      case 'ai_analysis':
        return 'Core CRM flow continues; advanced AI analysis is paused on free usage.';
      case 'customer_limit':
        return 'Existing customers stay available; only new customer tracking is limited.';
      case 'revenue_insights':
        return 'Unlock full insights, ranking and revenue context with PRO.';
      default:
        return 'PRO unlocks higher limits and deeper CRM intelligence.';
    }
  }
}
