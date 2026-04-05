import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_truth_kind.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_ui_state.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_ui_capabilities.dart';
import 'package:flutter/material.dart';

/// ✔️ ❌ ⚠️ — yetenek satırı; teknik detay yok.
class CapabilityBadgeRow extends StatelessWidget {
  const CapabilityBadgeRow({
    super.key,
    required this.capabilities,
    this.connectionState,
    this.truthKind,
  });

  final PlatformUiCapabilities capabilities;
  final PlatformConnectionUiState? connectionState;
  /// Canlı üretim yoksa yetenekler "hedef" olarak gösterilir (yeşil tik yok).
  final PlatformConnectionTruthKind? truthKind;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final live = truthKind?.isLiveProduction ?? false;
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _item(ext, 'İlan içe aktarma', capabilities.canImportListings, false, live),
        _item(ext, 'Fiyat güncelleme', capabilities.canUpdatePrice, false, live),
        _item(
          ext,
          'Mesajlar',
          capabilities.canManageMessages,
          !capabilities.canManageMessages &&
              connectionState == PlatformConnectionUiState.limited,
          live,
        ),
        _item(
          ext,
          'Senkron',
          capabilities.canSync,
          !capabilities.canSync &&
              connectionState == PlatformConnectionUiState.needsAttention,
          live,
        ),
      ],
    );
  }

  Widget _item(AppThemeExtension ext, String label, bool supported, bool warn, bool live) {
    final effective = supported && live;
    final roadmap = supported && !live;
    final String icon;
    if (effective) {
      icon = '✔️';
    } else if (roadmap) {
      icon = '○';
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
          roadmap ? '$label · hedef' : label,
          style: TextStyle(
            color: roadmap ? ext.textTertiary : ext.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
