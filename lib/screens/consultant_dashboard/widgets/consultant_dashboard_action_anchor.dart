import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Danışman panelinin aksiyon sabiti: birincil arama + ikincil CRM / geçmiş.
class ConsultantDashboardActionAnchor extends StatelessWidget {
  const ConsultantDashboardActionAnchor({super.key});

  static const double narrowActionBreakpoint = 360;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return PremiumSurfaceCard(
      goldBorder: true,
      padding: const EdgeInsets.all(DesignTokens.space4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < narrowActionBreakpoint;
          final secondaryBorder =
              BorderSide(color: ext.border.withValues(alpha: 0.72));
          final secondaryShape = RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
          );
          ButtonStyle secondaryStyle() => OutlinedButton.styleFrom(
                foregroundColor: ext.textPrimary,
                side: secondaryBorder,
                minimumSize: const Size(0, 48),
                padding: EdgeInsets.symmetric(
                  vertical: narrow ? 14 : 12,
                  horizontal: narrow ? 10 : 8,
                ),
                shape: secondaryShape,
                visualDensity: VisualDensity.standard,
              );
          final secondaryChildren = [
            Semantics(
              button: true,
              label: 'Akıllı görüşme ile ara',
              child: Tooltip(
                message: 'Uygulama içi kayıt oturumu',
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppFeedback.selectionClick();
                    AnalyticsService.instance
                        .logEvent(AnalyticsEvents.magicCallTap);
                    context.push(
                      AppRouter.routeCall,
                      extra: const {
                        'inAppCrmSession': true,
                        'startedFromScreen': 'consultant_dashboard',
                      },
                    );
                  },
                  style: secondaryStyle(),
                  icon: Icon(Icons.phone_in_talk_rounded,
                      size: 22, color: premium.champagneGold),
                  label: Text(
                    'Akıllı Görüşme',
                    style: AppTypography.secondaryButton(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            SizedBox(
                height: narrow ? DesignTokens.space2 : DesignTokens.space2),
            Semantics(
              button: true,
              label: 'Tüm çağrılarımı aç',
              child: Tooltip(
                message: 'Kayıtlı çağrı geçmişi',
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppFeedback.selectionClick();
                    AnalyticsService.instance
                        .logEvent(AnalyticsEvents.consultantCallsTap);
                    context.push(AppRouter.routeConsultantCalls);
                  },
                  style: secondaryStyle(),
                  icon: Icon(Icons.history_rounded,
                      size: 22, color: ext.textSecondary),
                  label: Text(
                    narrow ? 'Çağrılar' : 'Çağrılarım',
                    style: AppTypography.secondaryButton(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ];
          final header = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PremiumSectionHeader(
                label: 'Bugünün birinci adımı',
                icon: Icons.call_rounded,
              ),
              Text(
                narrow
                    ? 'Bir görüşme günü açar; özet ve görevler ardından akışa düşer.'
                    : 'Tek bir görüşme günü açar; özet ve görevler hemen ardından akışa düşer.',
                style: AppTypography.meta(context).copyWith(
                  color: ext.textTertiary,
                  height: 1.35,
                ),
              ),
            ],
          );
          final primaryButton = ConsultantDashboardPhoneCallPrimaryButton(
            onPressed: () {
              AppFeedback.mediumImpact();
              context.push(
                AppRouter.routeCall,
                extra: const {
                  'startedFromScreen': 'consultant_dashboard',
                },
              );
            },
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: DesignTokens.space3),
                primaryButton,
                const SizedBox(height: DesignTokens.space3),
                ...secondaryChildren,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: DesignTokens.space3),
                    primaryButton,
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: secondaryChildren,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ConsultantDashboardPhoneCallPrimaryButton extends StatelessWidget {
  const ConsultantDashboardPhoneCallPrimaryButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const String _subtitleFull =
      'Kayıtlı arama; özet ve görevler akışta seni bekler';
  static const String _subtitleShort = 'Kayıtlı arama; özet ve görevler hazır';

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final ts = MediaQuery.textScalerOf(context);
    final textScaleRatio =
        ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
    return Semantics(
      button: true,
      label:
          'Telefon ile ara. Kayıtlı aramada özet ve görevler otomatik hazırlanır.',
      child: Material(
        borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
        color: ext.accent,
        child: InkWell(
          onTap: onPressed,
          borderRadius:
              BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
          splashColor: ext.onBrand.withValues(alpha: 0.14),
          highlightColor: ext.onBrand.withValues(alpha: 0.08),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useShortSubtitle =
                  constraints.maxWidth < 304 || textScaleRatio > 1.18;
              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: DesignTokens.space4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call_rounded,
                              size: 24, color: ext.onBrand),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Telefon ile ara',
                              style: AppTypography.primaryButton(context)
                                  .copyWith(color: ext.onBrand),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        useShortSubtitle ? _subtitleShort : _subtitleFull,
                        style: TextStyle(
                          color: ext.onBrand.withValues(alpha: 0.92),
                          fontSize: DesignTokens.fontSizeXs,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
