import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/post_call_capture_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_quick_capture_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handoff sonrası üst şerit: çağrı otomatik kaydedilir, kullanıcıdan yalnızca detay ister.
/// [SafeArea] ile çentik/status bar üstünde kalır; metin taşması önlenir.
class PostCallCaptureShellStrip extends ConsumerWidget {
  const PostCallCaptureShellStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(postCallCaptureProvider);
    if (draft == null || draft.dismissedFromStrip) {
      return const SizedBox.shrink();
    }
    final ext = AppThemeExtension.of(context);
    return SafeArea(
      bottom: false,
      left: false,
      right: false,
      child: Material(
        color: ext.accent.withValues(alpha: 0.14),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            showPostCallQuickCaptureSheet(context: context, draft: draft);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: ext.accent, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Cagri kaydi hazir',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sadece detay ekle: sonuc, kisa not ve takip plani',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: ext.textSecondary,
                              height: 1.25,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(postCallCaptureProvider.notifier).dismissStrip();
                  },
                  child: Text(
                    'Sonra',
                    style: TextStyle(color: ext.textSecondary, fontSize: 13),
                  ),
                ),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: ext.accent.withValues(alpha: 0.16),
                    foregroundColor: ext.accent,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    showPostCallQuickCaptureSheet(
                        context: context, draft: draft);
                  },
                  child: const Text('Detay ekle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
