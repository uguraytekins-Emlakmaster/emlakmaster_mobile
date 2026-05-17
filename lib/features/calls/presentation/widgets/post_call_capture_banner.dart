import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/post_call_capture_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_quick_capture_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

/// Post-call üst şeridi — kabuk veya Çağrılarım gövdesi içinde kompakt banner.
class PostCallCaptureBanner extends ConsumerWidget {
  const PostCallCaptureBanner({
    super.key,
    this.margin,
    this.insetPadding = true,
  });

  final EdgeInsetsGeometry? margin;
  final bool insetPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(postCallCaptureProvider);
    if (draft == null || draft.dismissedFromStrip) {
      return const SizedBox.shrink();
    }
    final ext = AppThemeExtension.of(context);
    final horizontal = insetPadding
        ? DesignTokens.screenEdgePadding
        : 0.0;

    return Padding(
      padding: margin ??
          EdgeInsets.fromLTRB(
            horizontal,
            DesignTokens.space1,
            horizontal,
            DesignTokens.space2,
          ),
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(DesignTokens.radiusCardSecondary),
            gradient: LinearGradient(
              colors: [
                ext.accent.withValues(alpha: 0.22),
                ext.accent.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(color: ext.accent.withValues(alpha: 0.28)),
          ),
          child: InkWell(
            borderRadius:
                BorderRadius.circular(DesignTokens.radiusCardSecondary),
            onTap: () {
              AppFeedback.lightImpact();
              showPostCallQuickCaptureSheet(context: context, draft: draft);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: ext.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Çağrı kaydı hazır',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: ext.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Text(
                          'Detay ekleyin: sonuç, kısa not ve takip planı',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: ext.textSecondary,
                                    height: 1.2,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      AppFeedback.selectionClick();
                      ref
                          .read(postCallCaptureProvider.notifier)
                          .dismissStrip();
                    },
                    child: Text(
                      'Sonra',
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: ext.accent,
                      foregroundColor: ext.onBrand,
                    ),
                    onPressed: () {
                      AppFeedback.lightImpact();
                      showPostCallQuickCaptureSheet(
                          context: context, draft: draft);
                    },
                    child: const Text(
                      'Detay ekle',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kapat',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () {
                      AppFeedback.selectionClick();
                      ref
                          .read(postCallCaptureProvider.notifier)
                          .dismissStrip();
                    },
                    icon: Icon(Icons.close_rounded,
                        size: 20, color: ext.textSecondary),
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
