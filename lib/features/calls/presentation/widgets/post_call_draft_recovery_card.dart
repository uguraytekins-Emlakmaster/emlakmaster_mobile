import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/post_call_capture_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_quick_capture_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yarım kalan hızlı kayıt — tek kart, abartısız.
class PostCallDraftRecoveryCard extends ConsumerWidget {
  const PostCallDraftRecoveryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(postCallCaptureProvider.notifier);
    if (!notifier.shouldShowRecoveryCard) {
      return const SizedBox.shrink();
    }
    final draft = ref.watch(postCallCaptureProvider);
    if (draft == null) return const SizedBox.shrink();

    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.warning.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space2,
        ),
        child: Row(
          children: [
            Icon(Icons.restore_rounded, color: ext.warning, size: 20),
            const SizedBox(width: DesignTokens.space2),
            Expanded(
              child: Text(
                'Tamamlanmamış çağrı kaydı bulundu',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            TextButton(
              onPressed: () {
                AppFeedback.selectionClick();
                ref.read(postCallCaptureProvider.notifier).dismissRecovery();
              },
              child: Text('Kapat', style: TextStyle(color: ext.textSecondary)),
            ),
            FilledButton.tonal(
              onPressed: () {
                AppFeedback.lightImpact();
                showPostCallQuickCaptureSheet(context: context, draft: draft);
              },
              child: const Text('Devam et'),
            ),
          ],
        ),
      ),
    );
  }
}
