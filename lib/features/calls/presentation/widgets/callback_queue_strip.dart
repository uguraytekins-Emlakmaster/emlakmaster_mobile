import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/application/start_crm_outbound_call.dart';
import 'package:emlakmaster_mobile/features/calls/domain/callback_queue_item.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/callback_queue_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Geri arama kuyruğu — danışman çağrı yüzeyinde kompakt şerit.
class CallbackQueueStrip extends ConsumerWidget {
  const CallbackQueueStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(callbackQueueProvider);
    if (items.isEmpty) return const SizedBox.shrink();

    final ext = AppThemeExtension.of(context);
    final due = items.where((e) => e.isDue).take(3).toList();
    final upcoming = items.where((e) => !e.isDue).take(2).toList();
    final show = [...due, ...upcoming];
    if (show.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space3,
        DesignTokens.space2,
        DesignTokens.space3,
        0,
      ),
      child: Material(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.queue_rounded, size: 18, color: ext.accent),
                  const SizedBox(width: DesignTokens.space2),
                  Text(
                    'Geri arama kuyruğu',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ext.textPrimary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space2),
              for (final item in show)
                _QueueRow(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueRow extends ConsumerWidget {
  const _QueueRow({required this.item});

  final CallbackQueueItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final label = item.displayName.isNotEmpty
        ? item.displayName
        : item.phone;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.call_rounded, color: ext.success, size: 22),
            onPressed: () {
              startCrmOutboundCall(
                context,
                phone: item.phone,
                customerId: item.customerId,
                startedFromScreen: 'consultant_calls',
              );
              ref.read(callbackQueueProvider.notifier).complete(item.id);
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.check_rounded, color: ext.textTertiary, size: 20),
            onPressed: () =>
                ref.read(callbackQueueProvider.notifier).complete(item.id),
          ),
        ],
      ),
    );
  }
}
