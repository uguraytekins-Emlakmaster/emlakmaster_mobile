import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/models/integration_center_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/integration_center_platform_tile.dart';
import 'package:flutter/material.dart';

class IntegrationCenterPlatformCard extends StatelessWidget {
  const IntegrationCenterPlatformCard({
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
    return Semantics(
      label: '${snapshot.platformName} bağlantı satırı',
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.card.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(
            color: snapshot.emphasizeSetup
                ? ext.warning.withValues(alpha: 0.5)
                : ext.border.withValues(alpha: 0.4),
            width: snapshot.emphasizeSetup ? 1.2 : 1,
          ),
        ),
        child: IntegrationCenterPlatformTile(
          platform: platform,
          snapshot: snapshot,
          onTap: onTap,
          onConnect: onConnect,
          onConfigure: onConfigure,
          onOpen: onOpen,
          onRetry: onRetry,
          onLearnMore: onLearnMore,
        ),
      ),
    );
  }
}
