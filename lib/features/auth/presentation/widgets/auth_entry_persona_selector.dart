import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/login_entry_persona.dart';
import 'package:flutter/material.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

/// Yönetici / danışman giriş yolu seçici — login ve rol seçiminde ortak.
class AuthEntryPersonaSelector extends StatelessWidget {
  const AuthEntryPersonaSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });

  final LoginEntryPersona? selected;
  final ValueChanged<LoginEntryPersona> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          Text(
            l10n.t('persona_selector_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            l10n.t('persona_selector_sub'),
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: DesignTokens.fontSizeSm,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.space5),
        ],
        Row(
          children: [
            Expanded(
              child: _PersonaTile(
                persona: LoginEntryPersona.manager,
                selected: selected == LoginEntryPersona.manager,
                onTap: () => _select(context, LoginEntryPersona.manager),
                compact: compact,
              ),
            ),
            SizedBox(width: compact ? DesignTokens.space2 : DesignTokens.space3),
            Expanded(
              child: _PersonaTile(
                persona: LoginEntryPersona.consultant,
                selected: selected == LoginEntryPersona.consultant,
                onTap: () => _select(context, LoginEntryPersona.consultant),
                compact: compact,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _select(BuildContext context, LoginEntryPersona persona) {
    AppFeedback.selectionClick();
    onSelected(persona);
  }
}

class _PersonaTile extends StatelessWidget {
  const _PersonaTile({
    required this.persona,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final LoginEntryPersona persona;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final accent = _accentFor(ext, persona);
    final icon = persona == LoginEntryPersona.manager
        ? Icons.dashboard_customize_rounded
        : Icons.handshake_rounded;

    return Semantics(
      button: true,
      selected: selected,
      label: l10n.t(persona.loginTitleKey),
      child: AnimatedContainer(
        duration: DesignTokens.durationNormal,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? [
                    accent.withValues(alpha: 0.22),
                    ext.surfaceElevated,
                  ]
                : [
                    ext.surface,
                    ext.card,
                  ],
          ),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.85)
                : ext.border.withValues(alpha: 0.9),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? DesignTokens.space3 : DesignTokens.space4,
                vertical: compact ? DesignTokens.space3 : DesignTokens.space5,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: compact ? 40 : 48,
                        height: compact ? 40 : 48,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                        child: Icon(icon, color: accent, size: compact ? 22 : 26),
                      ),
                      if (selected)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: ext.background, width: 2),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: ext.onBrand,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: compact ? DesignTokens.space2 : DesignTokens.space3),
                  Text(
                    persona == LoginEntryPersona.manager
                        ? l10n.t('persona_manager_short')
                        : l10n.t('persona_consultant_short'),
                    style: TextStyle(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? DesignTokens.fontSizeSm : DesignTokens.fontSizeMd,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: DesignTokens.space1),
                    Text(
                      persona == LoginEntryPersona.manager
                          ? l10n.t('persona_manager_tagline')
                          : l10n.t('persona_consultant_tagline'),
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: DesignTokens.fontSizeXs,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _accentFor(AppThemeExtension ext, LoginEntryPersona persona) {
    return switch (persona) {
      LoginEntryPersona.manager => ext.brandPrimary,
      LoginEntryPersona.consultant =>
        Color.lerp(ext.brandPrimary, ext.info, 0.45)!,
    };
  }
}
