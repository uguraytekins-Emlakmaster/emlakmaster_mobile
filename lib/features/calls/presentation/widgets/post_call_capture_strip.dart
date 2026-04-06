import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/post_call_capture_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_quick_capture_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handoff sonrası üst şerit: hızlı kayıt girişi (banner benzeri).
class PostCallCaptureShellStrip extends ConsumerWidget {
  const PostCallCaptureShellStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(postCallCaptureProvider);
    if (draft == null || draft.dismissedFromStrip) {
      return const SizedBox.shrink();
    }
    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.accent.withValues(alpha: 0.12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          showPostCallQuickCaptureSheet(context: context, draft: draft);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.phone_callback_rounded, color: ext.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Çağrı sonucunu ekle',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Az önceki aramayı kaydet — hızlı sonuç ve not',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ext.textSecondary,
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(postCallCaptureProvider.notifier).dismissStrip();
                },
                child: Text(
                  'Sonra',
                  style: TextStyle(color: ext.textSecondary, fontSize: 13),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: ext.accent),
            ],
          ),
        ),
      ),
    );
  }
}
