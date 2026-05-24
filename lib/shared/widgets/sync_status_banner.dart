import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

import '../../core/resilience/sync_status.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/premium/premium_theme_extension.dart';
import '../../core/widgets/app_toaster.dart';
import '../../widgets/premium/v2/premium_state_views.dart';

/// Son senkron / çevrimdışı göstergesi. Shell veya sayfa üstünde/altında kullanılır.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    final premium = PremiumThemeExtension.of(context);
    final status = ref.watch(syncStatusProvider);
    final isOffline = !status.isOnline;
    // Compact: sadece çevrimdışıyken bant göster. Normal: çevrimdışı veya son senkron bilgisi varsa göster.
    if (compact && status.isOnline) return const SizedBox.shrink();
    if (!compact && status.isOnline && status.lastSyncAt == null) {
      return const SizedBox.shrink();
    }

    void showDetails() {
      AppFeedback.selectionClick();
      AppToaster.show(
        context,
        message: isOffline
            ? 'İnternet yok. Veriler önbellekten gösteriliyor; bağlantı gelince otomatik güncellenecek.'
            : 'Son güncelleme: ${status.shortLabel}',
        type: isOffline ? ToastType.warning : ToastType.info,
      );
    }

    if (isOffline) {
      return PremiumStateViews.offlineBanner(
        context: context,
        onTap: showDetails,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: showDetails,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: premium.glassBlur * 0.5,
              sigmaY: premium.glassBlur * 0.5,
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.space3,
                vertical: compact ? DesignTokens.space1 : DesignTokens.space2,
              ),
              decoration: BoxDecoration(
                color: premium.glassSurface.withValues(alpha: 0.72),
                border: Border(
                  bottom: BorderSide(
                    color: premium.glassBorder.withValues(alpha: 0.28),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_done_rounded,
                    size: compact ? 14 : 16,
                    color: premium.champagneGoldMuted,
                  ),
                  SizedBox(width: compact ? DesignTokens.space2 : DesignTokens.space2),
                  Text(
                    status.shortLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ext.textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
