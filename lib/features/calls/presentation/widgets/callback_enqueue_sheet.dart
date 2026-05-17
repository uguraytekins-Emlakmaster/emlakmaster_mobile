import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/application/start_crm_outbound_call.dart';
import 'package:emlakmaster_mobile/features/calls/domain/callback_queue_item.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/callback_queue_provider.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hızlı geri arama kuyruğu — şimdi / 15 dk / 1 saat / bugün / yarın.
Future<void> showCallbackEnqueueSheet(
  BuildContext context,
  WidgetRef ref, {
  required String phone,
  String? customerId,
  String displayName = '',
  String note = '',
  String source = 'call_action_sheet',
}) async {
  final anchor = context;

  Future<void> enqueue(Duration offset) async {
    final now = DateTime.now();
    final due = offset == Duration.zero ? now : now.add(offset);
    final id = '${now.millisecondsSinceEpoch}_${phone.hashCode}';
    await ref.read(callbackQueueProvider.notifier).enqueue(
          CallbackQueueItem(
            id: id,
            phone: phone,
            customerId: customerId,
            displayName: displayName,
            note: note,
            dueAtMs: due.millisecondsSinceEpoch,
            createdAtMs: now.millisecondsSinceEpoch,
          ),
        );
    if (anchor.mounted) {
      ScaffoldMessenger.of(anchor).showSnackBar(
        const SnackBar(
          content: Text('Geri arama kuyruğuna eklendi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  await showPremiumScrollableBottomSheet<void>(
    context: context,
    maxHeightFactor: 0.55,
    builder: (ctx) {
      final sheetExt = AppThemeExtension.of(ctx);

      Widget chip(String label, Duration Function() offset) {
        return ActionChip(
          label: Text(label),
          backgroundColor: sheetExt.card,
          side: BorderSide(color: sheetExt.border.withValues(alpha: 0.4)),
          onPressed: () async {
            AppFeedback.lightImpact();
            Navigator.pop(ctx);
            await enqueue(offset());
          },
        );
      }

      return PremiumScrollableBottomSheetShell(
        title: 'Geri arama kuyruğu',
        subtitle: displayName.isNotEmpty ? '$displayName · $phone' : phone,
        bottomActions: OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(ctx);
            if (!anchor.mounted) return;
            startCrmOutboundCall(
              anchor,
              phone: phone,
              customerId: customerId,
              startedFromScreen: source,
            );
          },
          icon: const Icon(Icons.call_rounded, size: 20),
          label: const Text('Hemen ara (CRM)'),
        ),
        child: Wrap(
          spacing: DesignTokens.space2,
          runSpacing: DesignTokens.space2,
          children: [
            chip('Şimdi ara', () => Duration.zero),
            chip('15 dk', () => const Duration(minutes: 15)),
            chip('1 saat', () => const Duration(hours: 1)),
            chip('Bugün', () {
              final now = DateTime.now();
              final end = DateTime(now.year, now.month, now.day, 18);
              return end.isAfter(now)
                  ? end.difference(now)
                  : const Duration(hours: 2);
            }),
            chip('Yarın', () {
              final t = DateTime.now().add(const Duration(days: 1));
              final target = DateTime(t.year, t.month, t.day, 10);
              return target.difference(DateTime.now());
            }),
          ],
        ),
      );
    },
  );
}
