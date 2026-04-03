import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/domain/call_transcript_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Transkript `ready` olduğunda tek satır — sadece gerçek veri varken görünür.
class CustomerTranscriptHintStrip extends ConsumerWidget {
  const CustomerTranscriptHintStrip({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final async = ref.watch(customerEntityByIdProvider(customerId));
    return async.when(
      data: (entity) {
        final t = entity?.lastCallTranscript;
        if (t == null || t.transcriptStatus != TranscriptStatus.ready) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space4),
          child: Row(
            children: [
              Icon(Icons.subtitles_outlined, size: 16, color: ext.accent.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ham kayıt (transkript) saklandı',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ext.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
