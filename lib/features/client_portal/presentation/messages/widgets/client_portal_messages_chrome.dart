import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/client_portal_tokens.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/messages/client_portal_messages_tokens.dart';
import 'package:flutter/material.dart';

/// Güven öncelikli iletişim masası üst alanı.
class ClientMessagesConciergeHeader extends StatelessWidget {
  const ClientMessagesConciergeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 360;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalMessagesTokens.horizontal,
        ClientPortalTokens.topInset,
        ClientPortalMessagesTokens.horizontal,
        ClientPortalTokens.headerBottomGap,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.surface.withValues(alpha: 0.58),
          borderRadius:
              BorderRadius.circular(ClientPortalMessagesTokens.surfaceRadius),
          border: Border.all(color: ext.border.withValues(alpha: 0.28)),
        ),
        child: Padding(
          padding: EdgeInsets.all(narrow ? 11 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: ClientPortalMessagesTokens.headerIconSize,
                    height: ClientPortalMessagesTokens.headerIconSize,
                    decoration: BoxDecoration(
                      color: premium.champagneGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: premium.champagneGold.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Icon(
                      Icons.support_agent_rounded,
                      color: premium.champagneGold.withValues(alpha: 0.92),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GÜVENLİ İLETİŞİM',
                          style: AppTypography.pageEyebrow(context).copyWith(
                            fontSize: 9.5,
                            letterSpacing: 0.65,
                            color: premium.champagneGold.withValues(alpha: 0.88),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Mesajlar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.pageHeading(context).copyWith(
                            fontSize: ClientPortalTokens.headerTitleSize + 0.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Danışmanınıza hızlı, güvenli ve net yollar',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.meta(context).copyWith(
                            color: ext.textSecondary.withValues(alpha: 0.9),
                            fontSize: ClientPortalTokens.headerSubtitleSize,
                            fontWeight: FontWeight.w600,
                            height: 1.22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ext.surfaceElevated.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ext.border.withValues(alpha: 0.22),
                      ),
                    ),
                    child: const BrandEmblem(
                      variant: BrandEmblemVariant.mini,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ClientMessagesHonestyNote(
                message:
                    'Uygulama içi mesaj geçmişi henüz aktif değil. '
                    'Aşağıdaki kanallar harici uygulamalarda açılır; '
                    'sohbet arşivi uygulamada saklanmaz.',
                accent: premium.champagneGold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClientMessagesTrustStrip extends StatelessWidget {
  const ClientMessagesTrustStrip({super.key, required this.cells});

  final List<(String value, String label)> cells;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalMessagesTokens.horizontal,
        ClientPortalMessagesTokens.chromeGap,
        ClientPortalMessagesTokens.horizontal,
        ClientPortalMessagesTokens.chromeGap,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.surface.withValues(alpha: 0.55),
          borderRadius:
              BorderRadius.circular(ClientPortalMessagesTokens.surfaceRadius),
          border: Border.all(color: ext.border.withValues(alpha: 0.24)),
        ),
        child: SizedBox(
          height: ClientPortalMessagesTokens.trustStripHeight,
          child: Row(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 30,
                    color: ext.border.withValues(alpha: 0.22),
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cells[i].$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: i == 0
                              ? premium.champagneGold.withValues(alpha: 0.92)
                              : ext.accent.withValues(alpha: 0.88),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cells[i].$2.toUpperCase(),
                        style: TextStyle(
                          color: ext.textTertiary,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ClientMessagesSectionLabel extends StatelessWidget {
  const ClientMessagesSectionLabel({
    super.key,
    required this.label,
    this.secondary,
  });

  final String label;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalMessagesTokens.horizontal,
        ClientPortalMessagesTokens.sectionGap,
        ClientPortalMessagesTokens.horizontal,
        ClientPortalMessagesTokens.chromeGap,
      ),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  premium.champagneGold.withValues(alpha: 0.85),
                  premium.champagneGold.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.65,
            ),
          ),
          if (secondary != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                secondary!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ext.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ClientMessagesReassuranceNote extends StatelessWidget {
  const ClientMessagesReassuranceNote({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ext.surface.withValues(alpha: 0.48),
        borderRadius:
            BorderRadius.circular(ClientPortalMessagesTokens.surfaceRadius),
        border: Border.all(color: ext.border.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 16,
              color: premium.champagneGold.withValues(alpha: 0.82),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Her kanal gerçek bir iletişim yoludur. '
                'Dokunduğunuzda harici uygulama açılır; '
                'uygulama içi sohbet arşivi yakında devreye alınacaktır.',
                style: TextStyle(
                  color: ext.textSecondary.withValues(alpha: 0.92),
                  fontSize: 11,
                  height: 1.38,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientMessagesHonestyNote extends StatelessWidget {
  const _ClientMessagesHonestyNote({
    required this.message,
    required this.accent,
  });

  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ext.surfaceElevated.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: ext.border.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: accent.withValues(alpha: 0.85)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: ext.textSecondary.withValues(alpha: 0.92),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
