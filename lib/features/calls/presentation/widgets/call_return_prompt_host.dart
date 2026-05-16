import 'dart:async';

import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/post_call_capture_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_quick_capture_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uygulama-içi handoff sonrası dönüşte tek seferlik kayıt istemi.
class CallReturnPromptHost extends ConsumerStatefulWidget {
  const CallReturnPromptHost({super.key});

  @override
  ConsumerState<CallReturnPromptHost> createState() =>
      _CallReturnPromptHostState();
}

class _CallReturnPromptHostState extends ConsumerState<CallReturnPromptHost> {
  StreamSubscription<void>? _resumeSub;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _resumeSub = AppLifecyclePowerService.onAppResumed.listen((_) {
      _maybeShowReturnPrompt();
    });
  }

  @override
  void dispose() {
    _resumeSub?.cancel();
    super.dispose();
  }

  Future<void> _maybeShowReturnPrompt() async {
    if (!mounted || _dialogOpen) return;
    final notifier = ref.read(postCallCaptureProvider.notifier);
    if (!notifier.shouldOfferReturnPrompt) return;
    final draft = ref.read(postCallCaptureProvider);
    if (draft == null) return;

    _dialogOpen = true;
    final ext = AppThemeExtension.of(context);
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ext.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        title: Text(
          'Aramayı CRM\'ye kaydet?',
          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        content: Text(
          draft.phone,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: ext.textSecondary,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Daha sonra',
              style: TextStyle(color: ext.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: ext.accent,
              foregroundColor: ext.onBrand,
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
    if (!mounted) return;
    await notifier.markReturnPromptShown();
    if (save == true && mounted) {
      AppFeedback.lightImpact();
      final d = ref.read(postCallCaptureProvider);
      if (d != null) {
        await showPostCallQuickCaptureSheet(context: context, draft: d);
      }
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
