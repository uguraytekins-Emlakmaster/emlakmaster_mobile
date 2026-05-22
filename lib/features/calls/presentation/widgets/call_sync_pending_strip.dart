import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Yerel taslakların CRM’e aktarımı beklerken ince üst şerit.
class CallSyncPendingStrip extends StatelessWidget {
  const CallSyncPendingStrip({
    super.key,
    required this.pendingCount,
    this.onTap,
  });

  final int pendingCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (pendingCount <= 0) return const SizedBox.shrink();
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.screenEdgePadding,
        DesignTokens.space1,
        DesignTokens.screenEdgePadding,
        DesignTokens.space1,
      ),
      child: Material(
        color: ext.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space3,
              vertical: DesignTokens.space2 + 2,
            ),
            child: Row(
              children: [
                Icon(Icons.sync_rounded, color: ext.warning, size: 20),
                const SizedBox(width: DesignTokens.space2),
                Expanded(
                  child: Text(
                    '$pendingCount kayıt aktarılıyor veya sonuç bekliyor',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: ext.textTertiary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
