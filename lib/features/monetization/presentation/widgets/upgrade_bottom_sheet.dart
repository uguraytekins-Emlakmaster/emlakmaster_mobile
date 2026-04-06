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
    final benefits = _benefits(feature);
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
          const SizedBox(height: DesignTokens.space4),
          Wrap(
            spacing: DesignTokens.space2,
            runSpacing: DesignTokens.space2,
            children: benefits
                .map((benefit) => _BenefitChip(label: benefit))
                .toList(),
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            _featureLine(feature),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ext.textTertiary,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: DesignTokens.space4),
          const _PlanComparisonSurface(),
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
            child: const Text('PRO\'yu Aç'),
          ),
          const SizedBox(height: DesignTokens.space2),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Şimdilik sonra',
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
        return 'Bu ayki AI öneri hakkın doldu';
      case 'revenue_insights':
        return 'Burada daha derin satış sinyalleri var';
      default:
        return 'PRO ile daha güçlü satış akışını aç';
    }
  }

  static String _body(String feature) {
    switch (feature) {
      case 'ai_analysis':
        return 'Temel CRM akışın devam ediyor. Yeni AI önerileri gelecek dönemde yenilenir; PRO ile sınırsız kullanım açılır.';
      case 'revenue_insights':
        return 'PRO, sıcak müşterileri daha net görmeni ve hangi adımın geliri büyüteceğini daha hızlı anlamanı sağlar.';
      default:
        return 'PRO; AI önerilerini, daha derin müşteri içgörülerini ve daha güçlü satış yönlendirmesini tek akışta sunar.';
    }
  }

  static String _featureLine(String feature) {
    switch (feature) {
      case 'ai_analysis':
        return 'Kısıt yalnızca maliyetli AI katmanında. Arama, CRM ve temel takip akışların aynen çalışmaya devam eder.';
      case 'revenue_insights':
        return 'PRO ile derin gelir analitiği, çok danışmanlı sıralama ve ileri satış rehberliği açılır.';
      default:
        return 'Ücretsiz plan tamamen kullanılabilir; PRO yalnızca yüksek değerli içgörü katmanını büyütür.';
    }
  }

  static List<String> _benefits(String feature) {
    switch (feature) {
      case 'ai_analysis':
        return const [
          'Sınırsız AI önerileri',
          'Daha derin müşteri içgörüleri',
          'Daha güçlü satış yönlendirmesi',
        ];
      case 'revenue_insights':
        return const [
          'Derin gelir içgörüleri',
          'Çok danışmanlı sıralama',
          'İleri satış rehberliği',
        ];
      default:
        return const [
          'Sınırsız AI önerileri',
          'Gelişmiş analizler',
          'Premium satış rehberliği',
        ];
    }
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space3,
        vertical: DesignTokens.space2,
      ),
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ext.border.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: ext.textPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _PlanComparisonSurface extends StatelessWidget {
  const _PlanComparisonSurface();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PlanCard(
            title: 'Ücretsiz',
            accent: false,
            lines: [
              'Sınırsız arama',
              'Sınırsız CRM',
              '20 / ay AI önerisi',
              'Temel analizler',
            ],
          ),
        ),
        SizedBox(width: DesignTokens.space3),
        Expanded(
          child: _PlanCard(
            title: 'PRO',
            accent: true,
            lines: [
              'Sınırsız arama',
              'Sınırsız CRM',
              'Sınırsız AI önerisi',
              'İleri analizler açık',
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.accent,
    required this.lines,
  });

  final String title;
  final bool accent;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final color = accent ? ext.accent : ext.border;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space3),
      decoration: BoxDecoration(
        color:
            accent ? ext.accent.withValues(alpha: 0.10) : ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: accent ? ext.accent.withValues(alpha: 0.35) : color,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: DesignTokens.space2),
          for (final line in lines) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: accent ? ext.accent : ext.success,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    line,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ext.textSecondary,
                          height: 1.3,
                        ),
                  ),
                ),
              ],
            ),
            if (line != lines.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
