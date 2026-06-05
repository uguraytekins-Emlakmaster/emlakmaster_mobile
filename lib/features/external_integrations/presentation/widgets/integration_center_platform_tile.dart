import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/consultant_integrations_tokens.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/models/integration_center_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/integration_center_row_actions.dart';
import 'package:flutter/material.dart';

class IntegrationCenterPlatformTile extends StatelessWidget {
  const IntegrationCenterPlatformTile({
    super.key,
    required this.platform,
    required this.snapshot,
    this.onTap,
    this.onConnect,
    this.onConfigure,
    this.onOpen,
    this.onRetry,
    this.onLearnMore,
  });

  final IntegrationPlatform platform;
  final IntegrationCenterRowSnapshot snapshot;
  final VoidCallback? onTap;
  final VoidCallback? onConnect;
  final VoidCallback? onConfigure;
  final VoidCallback? onOpen;
  final VoidCallback? onRetry;
  final VoidCallback? onLearnMore;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ConsultantIntegrationsTokens.rowPaddingH,
          ConsultantIntegrationsTokens.rowPaddingV,
          ConsultantIntegrationsTokens.rowPaddingH,
          ConsultantIntegrationsTokens.rowPaddingV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PlatformOrb(
                  letter: platform.logoLabel,
                  color: premium.champagneGold.withValues(alpha: 0.95),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snapshot.platformName,
                        style: TextStyle(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: ConsultantIntegrationsTokens.rowTitleSize,
                          letterSpacing: -0.2,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        snapshot.providerLine,
                        style: TextStyle(
                          color: ext.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _StatusChip(
                  label: snapshot.healthBadge,
                  tone: _statusTone(snapshot.healthToneKey, ext),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (snapshot.syncBadge != null)
                  _MiniChip(label: snapshot.syncBadge!, fg: ext.info),
                if (snapshot.roleBadge != null)
                  _MiniChip(label: snapshot.roleBadge!, fg: ext.danger),
                _MiniChip(
                  label: snapshot.healthToneKey == 'unavailable'
                      ? 'Not available'
                      : 'Bağlantı durumu',
                  fg: ext.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              snapshot.descriptionLine,
              style: TextStyle(
                color: ext.textPrimary.withValues(alpha: 0.88),
                fontSize: ConsultantIntegrationsTokens.rowMetaSize,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (snapshot.metaLine.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                snapshot.metaLine,
                style: TextStyle(
                  color: ext.textTertiary,
                  fontSize: 9.5,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            IntegrationCenterRowActions(
              onConnect: onConnect,
              onConfigure: onConfigure,
              onOpen: onOpen,
              onRetry: onRetry,
              onLearnMore: onLearnMore,
              canConnect: snapshot.canConnect,
              canConfigure: snapshot.canConfigure,
              canOpen: snapshot.canOpen,
              canRetry: snapshot.canRetry,
              canLearnMore: snapshot.canLearnMore,
            ),
          ],
        ),
      ),
    );
  }

  Color _statusTone(String key, AppThemeExtension ext) {
    switch (key) {
      case 'connected':
        return ext.success;
      case 'setup':
        return ext.warning;
      case 'preview':
        return ext.info;
      case 'unavailable':
        return ext.danger;
      default:
        return ext.textSecondary;
    }
  }
}

class _PlatformOrb extends StatelessWidget {
  const _PlatformOrb({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tone,
          fontSize: ConsultantIntegrationsTokens.statusChipFontSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.fg});

  final String label;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
