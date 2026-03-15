import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/resilience/sync_status.dart';
import '../../core/theme/design_tokens.dart';

/// Son senkron / çevrimdışı göstergesi. Shell veya sayfa üstünde/altında kullanılır.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    if (status.isOnline && status.lastSyncAt == null && !compact) {
      return const SizedBox.shrink();
    }
    final isOffline = !status.isOnline;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isOffline
                    ? 'İnternet bağlantısı yok. Veriler yerelde saklanıyor; bağlantı gelince otomatik senkronize edilecek.'
                    : 'Son güncelleme: ${status.shortLabel}',
              ),
              backgroundColor: isOffline ? DesignTokens.warning : const Color(0xFF161B22),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space3,
            vertical: compact ? DesignTokens.space1 : DesignTokens.space2,
          ),
          decoration: BoxDecoration(
            color: isOffline
                ? DesignTokens.warning.withOpacity(0.15)
                : DesignTokens.surfaceDark.withOpacity(0.6),
            border: Border(
              bottom: BorderSide(
                color: isOffline ? DesignTokens.warning.withOpacity(0.5) : DesignTokens.borderDark,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                size: compact ? 14 : 16,
                color: isOffline ? DesignTokens.warning : DesignTokens.primary,
              ),
              if (!compact) ...[
                const SizedBox(width: DesignTokens.space2),
                Text(
                  status.shortLabel,
                  style: TextStyle(
                    color: isOffline ? DesignTokens.warning : DesignTokens.textSecondaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
