import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_truth_kind.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_connection_mode.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_setup_status.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_setup_lifecycle.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_capability.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/capability_badge_row.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/platform_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class ConnectedPlatformCard extends StatelessWidget {
  const ConnectedPlatformCard({
    super.key,
    required this.platform,
    required this.onConnect,
    required this.onReconnect,
    required this.onSync,
    required this.onDisconnect,
  });

  final IntegrationPlatform platform;
  final VoidCallback onConnect;
  final VoidCallback onReconnect;
  final VoidCallback onSync;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final color = _brandTint(platform.id.index);

    return Container(
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: ext.border.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LogoOrb(letter: platform.logoLabel, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        platform.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.foreground,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _supportLabel(platform.supportLevel),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.foregroundSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (platform.setupRecord != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Kurulum: ${platform.setupLifecycle?.cardSubtitleTr ?? platform.setupRecord!.setupStatus.shortLabelTr} · '
                          '${_connectionModeShort(platform.setupRecord!.connectionMode)}',
                          maxLines: 2,
                          style: TextStyle(
                            color: ext.accent.withValues(alpha: 0.95),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PlatformStatusChip(
                  truthKind: platform.truthKind,
                  labelOverride: platform.setupLifecycle?.chipLabelTr,
                ),
              ],
            ),
            if (platform.connectedAccountLabel != null) ...[
              const SizedBox(height: 10),
              Text(
                platform.connectedAccountLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ext.foregroundSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (!platform.truthKind.isLiveProduction) ...[
              const SizedBox(height: 8),
              Text(
                'Resmi entegrasyonlar beta öncesi: aşağıdaki yetenekler yol haritasıdır.',
                style: TextStyle(
                  color: ext.foregroundMuted,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            CapabilityBadgeRow(
              capabilities: platform.capabilities,
              connectionState: platform.connectionState,
              truthKind: platform.truthKind,
            ),
            if (platform.errorState != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: ext.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  border: Border.all(color: ext.danger.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform.errorState!.shortMessage,
                      style: TextStyle(
                        color: ext.foreground,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    if (platform.errorState!.hint != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        platform.errorState!.hint!,
                        style: TextStyle(
                          color: ext.foregroundSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              _lastSync(platform.lastSyncAt),
              style: TextStyle(color: ext.foregroundMuted, fontSize: 11),
            ),
            const SizedBox(height: 14),
            _ActionRow(
              onConnect: onConnect,
              onReconnect: onReconnect,
              onSync: onSync,
              onDisconnect: onDisconnect,
            ),
          ],
        ),
      ),
    );
  }

  static String _lastSync(DateTime? t) {
    if (t == null) return 'Son senkron: —';
    final d =
        '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';
    final time =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return 'Son senkron: $d · $time';
  }

  static String _connectionModeShort(IntegrationConnectionMode mode) {
    switch (mode) {
      case IntegrationConnectionMode.officialSetup:
        return 'Resmi kurulum';
      case IntegrationConnectionMode.transferKey:
        return 'Transfer anahtarı';
      case IntegrationConnectionMode.fileImport:
        return 'Dosya içe aktarma';
      case IntegrationConnectionMode.manualOnly:
        return 'Manuel portföy';
    }
  }

  static String _supportLabel(IntegrationSupportLevel l) => switch (l) {
        IntegrationSupportLevel.tier1Official => 'Resmi entegrasyon hedefi',
        IntegrationSupportLevel.tier2UserControlled => 'Kullanıcı kontrollü senkron',
        IntegrationSupportLevel.tier3Experimental => 'Deneysel · sınırlı destek',
      };

  static Color _brandTint(int seed) {
    const tints = [
      Color(0xFF1E6F5C),
      Color(0xFF2B4F81),
      Color(0xFF8B4513),
    ];
    return tints[seed % tints.length];
  }
}

class _LogoOrb extends StatelessWidget {
  const _LogoOrb({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onConnect,
    required this.onReconnect,
    required this.onSync,
    required this.onDisconnect,
  });

  final VoidCallback onConnect;
  final VoidCallback onReconnect;
  final VoidCallback onSync;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MiniAction(
          label: 'Bağlan',
          icon: Icons.link_rounded,
          onTap: onConnect,
          filled: true,
        ),
        _MiniAction(
          label: 'Yeniden bağlan',
          icon: Icons.refresh_rounded,
          onTap: onReconnect,
        ),
        _MiniAction(
          label: 'Şimdi senkron',
          icon: Icons.sync_rounded,
          onTap: onSync,
        ),
        _MiniAction(
          label: 'Bağlantıyı kes',
          icon: Icons.link_off_rounded,
          onTap: onDisconnect,
          danger: true,
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: filled
          ? ext.accent.withValues(alpha: 0.9)
          : ext.surfaceElevated,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: danger
                    ? ext.danger
                    : filled
                        ? ext.onBrand
                        : ext.foreground,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: danger
                      ? ext.danger
                      : filled
                          ? ext.onBrand
                          : ext.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
