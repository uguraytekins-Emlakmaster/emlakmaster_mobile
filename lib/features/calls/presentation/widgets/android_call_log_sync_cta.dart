import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Android — telefon arama geçmişini CRM’e içe aktarma CTA.
class AndroidCallLogSyncCta extends StatelessWidget {
  const AndroidCallLogSyncCta({
    super.key,
    required this.onSync,
    this.isSyncing = false,
  });

  final VoidCallback? onSync;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.screenEdgePadding,
        0,
        DesignTokens.screenEdgePadding,
        DesignTokens.space2,
      ),
      child: OutlinedButton.icon(
        onPressed: isSyncing ? null : onSync,
        icon: isSyncing
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ext.accent,
                ),
              )
            : Icon(Icons.phone_android_rounded, color: ext.accent, size: 20),
        label: Text(
          isSyncing
              ? 'Telefon geçmişi içe aktarılıyor…'
              : 'Telefon arama geçmişini içe aktar',
          style: TextStyle(
            color: ext.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: ext.accent.withValues(alpha: 0.35)),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3,
            vertical: DesignTokens.space2 + 2,
          ),
        ),
      ),
    );
  }
}
