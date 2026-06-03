import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/config/legal_links.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:emlakmaster_mobile/core/services/auth_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
          // Dürüstlük: uygulama içi satın alma (IAP) henüz yok. Bu yüzden burada
          // sahte "satın al/aktive et" yapılmaz. PRO geçişi satış ekibi tarafından
          // yapıldığından, CTA gerçek bir eyleme (iletişim) bağlanır; iletişim
          // adresi tanımlı değilse yalnızca bilgilendirme gösterilir.
          if (LegalLinks.hasSupportEmail) ...[
            FilledButton(
              onPressed: () {
                AnalyticsService.instance.logEvent(
                  AnalyticsEvents.upgradeClicked,
                  {AnalyticsEvents.paramFeature: feature},
                );
                _contactSales(context, feature);
              },
              style: FilledButton.styleFrom(
                backgroundColor: ext.accent,
                foregroundColor: ext.onBrand,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('PRO için iletişime geç'),
            ),
            const SizedBox(height: DesignTokens.space2),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Şimdilik sonra',
                style: TextStyle(color: ext.textSecondary),
              ),
            ),
          ] else
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
                foregroundColor: ext.onBrand,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Anladım'),
            ),
        ],
      ),
    );
  }

  Future<void> _contactSales(BuildContext context, String feature) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    // Hesap bilgisi: satış ekibinin kimi PRO'ya yükselteceğini bilmesi için
    // (PRO, ilgili ofisin planType alanı 'pro' yapılarak verilir).
    final user = AuthService.instance.currentUser;
    final email = user?.email ?? '';
    final accountLine = email.isNotEmpty ? 'Hesap e-postası: $email\n' : '';
    final uidLine = (user?.uid.isNotEmpty ?? false)
        ? 'Hesap kimliği: ${user!.uid}\n'
        : '';
    final uri = Uri(
      scheme: 'mailto',
      path: LegalLinks.supportEmail,
      queryParameters: {
        'subject': 'Portivo CRM PRO yükseltme talebi',
        'body': 'Merhaba, PRO planı ile ilgileniyorum.\n\n'
            '$accountLine$uidLine'
            'İlgi alanı: $feature\n\n'
            'PRO\'ya geçiş için bilgi rica ederim.',
      },
    );
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    navigator.pop();
    if (!launched) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Destek: ${LegalLinks.supportEmail}')),
      );
    }
  }

  static String _title(String feature) {
    switch (feature) {
      case 'ai_analysis':
        return 'Bu ayki akıllı öneri hakkın doldu';
      case 'revenue_insights':
        return 'Burada daha derin satış sinyalleri var';
      default:
        return 'PRO ile daha güçlü satış akışını aç';
    }
  }

  static String _body(String feature) {
    switch (feature) {
      case 'ai_analysis':
        return 'Temel müşteri akışın devam ediyor. Yeni akıllı öneriler gelecek dönemde yenilenir; PRO ile sınırsız kullanım açılır.';
      case 'revenue_insights':
        return 'PRO, sıcak müşterileri daha net görmeni ve hangi adımın geliri büyüteceğini daha hızlı anlamanı sağlar.';
      default:
        return 'PRO; akıllı önerileri, daha derin müşteri içgörülerini ve daha güçlü satış yönlendirmesini tek akışta sunar.';
    }
  }

  static String _featureLine(String feature) {
    switch (feature) {
      case 'ai_analysis':
        return 'Sınır yalnızca maliyetli akıllı öneri katmanında. Arama, müşteri akışı ve temel takip düzenin aynen devam eder.';
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
          'Sınırsız akıllı öneri',
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
          'Sınırsız akıllı öneri',
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
              'Sınırsız müşteri akışı',
              'Ayda 20 akıllı öneri',
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
              'Sınırsız müşteri akışı',
              'Sınırsız akıllı öneri',
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
