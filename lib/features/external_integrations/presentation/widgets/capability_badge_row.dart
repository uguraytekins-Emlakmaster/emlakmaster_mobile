import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_ui_state.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_ui_capabilities.dart';
import 'package:flutter/material.dart';

/// ✔️ ❌ ⚠️ — yetenek satırı; teknik detay yok.
class CapabilityBadgeRow extends StatelessWidget {
  const CapabilityBadgeRow({
    super.key,
    required this.capabilities,
    this.connectionState,
  });

  final PlatformUiCapabilities capabilities;
  final PlatformConnectionUiState? connectionState;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _item(ext, 'İlan içe aktarma', capabilities.canImportListings, false),
        _item(ext, 'Fiyat güncelleme', capabilities.canUpdatePrice, false),
        _item(
          ext,
          'Mesajlar',
          capabilities.canManageMessages,
          !capabilities.canManageMessages &&
              connectionState == PlatformConnectionUiState.limited,
        ),
        _item(
          ext,
          'Senkron',
          capabilities.canSync,
          !capabilities.canSync &&
              connectionState == PlatformConnectionUiState.needsAttention,
        ),
      ],
    );
  }

  Widget _item(AppThemeExtension ext, String label, bool supported, bool warn) {
    final String icon;
    if (supported) {
      icon = '✔️';
    } else if (warn) {
      icon = '⚠️';
    } else {
      icon = '❌';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: ext.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
