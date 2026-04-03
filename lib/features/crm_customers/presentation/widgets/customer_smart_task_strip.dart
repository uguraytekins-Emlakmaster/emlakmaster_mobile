import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/crm_intelligence_explanations.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/smart_task_suggestion.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_smart_task_suggestions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Yönetici müşteri detayında: tek birincil görev önerisi (onaylı yazım).
class CustomerSmartTaskStrip extends ConsumerStatefulWidget {
  const CustomerSmartTaskStrip({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<CustomerSmartTaskStrip> createState() => _CustomerSmartTaskStripState();
}

class _CustomerSmartTaskStripState extends ConsumerState<CustomerSmartTaskStrip> {
  bool _busy = false;

  Future<void> _create(SmartTaskSuggestion s) async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    try {
      await FirestoreService.setTask({
        'advisorId': s.assigneeAdvisorId,
        'customerId': s.relatedCustomerId,
        'title': s.titleForFirestore,
        'dueAt': Timestamp.fromDate(s.suggestedDueAt),
        'done': false,
        'smartSuggestionSource': 'v1',
        'smartSuggestionCode': s.code.taskSuggestionCode,
      });
      await ref.read(taskSuggestionDedupeStoreProvider).suppress(uid, s.dedupeKey);
      ref.invalidate(brokerSmartTaskSuggestionsProvider);
      ref.invalidate(customerSmartTaskSuggestionProvider(widget.customerId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Görev oluşturuldu'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görev eklenemedi: ${FirestoreService.userFacingErrorMessage(e)}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dismiss(SmartTaskSuggestion s) async {
    if (_busy) return;
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    await ref.read(taskSuggestionDedupeStoreProvider).suppress(uid, s.dedupeKey);
    ref.invalidate(customerSmartTaskSuggestionProvider(widget.customerId));
    ref.invalidate(brokerSmartTaskSuggestionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final async = ref.watch(customerSmartTaskSuggestionProvider(widget.customerId));
    return async.when(
      data: (s) {
        if (s == null) return const SizedBox.shrink();
        final dueStr = DateFormat('d MMM HH:mm', 'tr_TR').format(s.suggestedDueAt);
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              color: ext.surfaceElevated,
              border: Border.all(color: ext.accent.withValues(alpha: 0.38)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, size: 18, color: ext.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Önerilen görev',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ext.textTertiary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.taskSuggestionLabelTr,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  explainSmartTaskNarrative(s.code),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ext.textSecondary,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vade: $dueStr',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ext.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton(
                      onPressed: _busy ? null : () => _dismiss(s),
                      child: Text('Gizle', style: TextStyle(color: ext.textTertiary)),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _busy ? null : () => _create(s),
                      style: FilledButton.styleFrom(
                        backgroundColor: ext.accent,
                        foregroundColor: Colors.black,
                      ),
                      child: _busy
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black.withValues(alpha: 0.7),
                              ),
                            )
                          : const Text('Görev oluştur'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
