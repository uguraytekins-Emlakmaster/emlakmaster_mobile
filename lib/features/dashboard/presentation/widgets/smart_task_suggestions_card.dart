import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/crm_intelligence_explanations.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/smart_task_suggestion.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_smart_task_suggestions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Akıllı görev önerileri — yalnızca onayla Firestore’a yazılır (v1 güvenli mod).
class SmartTaskSuggestionsCard extends ConsumerWidget {
  const SmartTaskSuggestionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final async = ref.watch(brokerSmartTaskSuggestionsProvider);
    return async.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space5),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.space4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              color: ext.surfaceElevated,
              border: Border.all(color: ext.accent.withValues(alpha: 0.38)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.task_alt_rounded, size: 20, color: ext.accent),
                    const SizedBox(width: DesignTokens.space2),
                    Expanded(
                      child: Text(
                        'Akıllı görev önerileri',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Text(
                      '${items.length}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: ext.textTertiary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  'Öneri — tek dokunuşla danışmana atanmış görev oluşturun',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ext.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: DesignTokens.space3),
                ...items.map((s) => _SuggestionRow(suggestion: s)),
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

class _SuggestionRow extends ConsumerStatefulWidget {
  const _SuggestionRow({required this.suggestion});

  final SmartTaskSuggestion suggestion;

  @override
  ConsumerState<_SuggestionRow> createState() => _SuggestionRowState();
}

class _SuggestionRowState extends ConsumerState<_SuggestionRow> {
  bool _busy = false;

  Future<void> _createTask() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    final s = widget.suggestion;
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
      ref.invalidate(customerSmartTaskSuggestionProvider(s.relatedCustomerId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görev oluşturuldu: ${s.taskSuggestionLabelTr}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görev eklenemedi: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dismiss() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.lightImpact();
    final s = widget.suggestion;
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    await ref.read(taskSuggestionDedupeStoreProvider).suppress(uid, s.dedupeKey);
    ref.invalidate(brokerSmartTaskSuggestionsProvider);
    ref.invalidate(customerSmartTaskSuggestionProvider(s.relatedCustomerId));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final s = widget.suggestion;
    final dueStr = DateFormat('d MMM HH:mm', 'tr_TR').format(s.suggestedDueAt);
    final urgColor = switch (s.urgency) {
      TaskSuggestionUrgency.high => ext.danger,
      TaskSuggestionUrgency.medium => ext.warning,
      TaskSuggestionUrgency.low => ext.textSecondary,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          color: ext.background.withValues(alpha: 0.45),
          border: Border.all(color: ext.border.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.customerName?.trim().isNotEmpty == true
                            ? s.customerName!.trim()
                            : 'Müşteri',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ext.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.taskSuggestionLabelTr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        explainSmartTaskNarrative(s.code),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: ext.textTertiary,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : () => context.push('/customer/${s.relatedCustomerId}'),
                  child: const Text('Profil'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: urgColor.withValues(alpha: 0.12),
                    border: Border.all(color: urgColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    '${_urgencyLabel(s.urgency)} · $dueStr',
                    style: TextStyle(
                      color: urgColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _busy ? null : _dismiss,
                  child: Text('Gizle', style: TextStyle(color: ext.textTertiary)),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: _busy ? null : _createTask,
                  style: FilledButton.styleFrom(
                    backgroundColor: ext.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
  }

  String _urgencyLabel(TaskSuggestionUrgency u) {
    switch (u) {
      case TaskSuggestionUrgency.high:
        return 'Acil';
      case TaskSuggestionUrgency.medium:
        return 'Normal';
      case TaskSuggestionUrgency.low:
        return 'Esnek';
    }
  }
}
