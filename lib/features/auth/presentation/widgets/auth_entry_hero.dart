import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/login_entry_persona.dart';
import 'package:flutter/material.dart';

/// Giriş ekranı üst alanı — seçilen yönetici / danışman yoluna göre metin.
class AuthEntryHero extends StatelessWidget {
  const AuthEntryHero({
    super.key,
    required this.persona,
    this.emblemSize = 92,
  });

  final LoginEntryPersona? persona;
  final double emblemSize;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final accent = persona == null
        ? ext.brandPrimary
        : persona == LoginEntryPersona.manager
            ? ext.brandPrimary
            : Color.lerp(ext.brandPrimary, ext.info, 0.45)!;

    final title = persona?.loginTitle ?? 'Axion CRM';
    final subtitle =
        persona?.loginSubtitle ?? AppLocalizations.of(context).t('brand_tagline');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.space4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                accent.withValues(alpha: 0.14),
                Colors.transparent,
              ],
            ),
          ),
          child: BrandEmblem(
            variant: BrandEmblemVariant.full,
            size: emblemSize,
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: ext.brandPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                fontSize: 26,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          subtitle,
          style: TextStyle(
            color: ext.foregroundSecondary,
            fontSize: DesignTokens.fontSizeMd,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
