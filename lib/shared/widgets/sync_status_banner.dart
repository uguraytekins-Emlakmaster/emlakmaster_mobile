import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/resilience/sync_status.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/app_toaster.dart';

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
    final isOffline = !status.isOnline;
    // Compact: sadece çevrimdışıyken bant göster. Normal: çevrimdışı veya son senkron bilgisi varsa göster.
    if (compact && status.isOnline) return const SizedBox.shrink();
    if (!compact && status.isOnline && status.lastSyncAt == null) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          AppToaster.show(
            context,
            message: isOffline
                ? 'İnternet yok. Veriler önbellekten gösteriliyor; bağlantı gelince otomatik güncellenecek.'
                : 'Son güncelleme: ${status.shortLabel}',
            type: isOffline ? ToastType.warning : ToastType.info,
          );
        },
        child: Container(
          width: double.infinity,
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
              SizedBox(width: compact ? DesignTokens.space2 : DesignTokens.space2),
              Text(
                isOffline ? 'İnternet yok. Veriler önbellekten gösteriliyor.' : status.shortLabel,
                style: TextStyle(
                  color: isOffline ? DesignTokens.warning : DesignTokens.textSecondaryDark,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
