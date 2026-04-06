import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/post_call_capture_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_quick_capture_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Şerit kapatıldıktan sonra ana ekranda görünen hafif hatırlatıcı.
class PostCallCaptureDashboardReminder extends ConsumerWidget {
  const PostCallCaptureDashboardReminder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(postCallCaptureProvider);
    if (draft == null || !draft.dismissedFromStrip) {
      return const SizedBox.shrink();
    }
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Material(
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
        color: ext.surfaceElevated,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
          onTap: () {
            HapticFeedback.lightImpact();
            showPostCallQuickCaptureSheet(context: context, draft: draft);
          },
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: ext.accent, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bekleyen çağrı kaydı',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${draft.phone} — sonucu eklemek için dokunun',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ext.textSecondary,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: ext.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
