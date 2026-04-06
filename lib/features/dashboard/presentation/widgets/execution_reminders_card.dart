import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/execution_reminder.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/execution_reminders_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// İcra hatırlatıcıları — danışman veya broker kapsamı.
enum ExecutionReminderSurface {
  consultant,
  broker,
}

extension ExecutionReminderSurfaceX on ExecutionReminderSurface {
  String get titleTr => switch (this) {
        ExecutionReminderSurface.consultant => 'Bugün yapılmalı',
        ExecutionReminderSurface.broker => 'Yaklaşan takipler',
      };

  String get subtitleTr => switch (this) {
        ExecutionReminderSurface.consultant =>
          'Kişisel müşteri takibi; tek dokunuşla ilerleyin',
        ExecutionReminderSurface.broker =>
          'Ekip için öncelikli icra adımları',
      };

  AsyncValue<List<ExecutionReminderItem>> remindersAsync(WidgetRef ref) =>
      switch (this) {
        ExecutionReminderSurface.consultant =>
          ref.watch(consultantExecutionRemindersProvider),
        ExecutionReminderSurface.broker => ref.watch(brokerExecutionRemindersProvider),
      };

  void invalidateReminders(WidgetRef ref) => switch (this) {
        ExecutionReminderSurface.consultant =>
          ref.invalidate(consultantExecutionRemindersProvider),
        ExecutionReminderSurface.broker => ref.invalidate(brokerExecutionRemindersProvider),
      };
}

class ExecutionRemindersCard extends ConsumerWidget {
  const ExecutionRemindersCard({super.key, required this.surface});

  final ExecutionReminderSurface surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final async = surface.remindersAsync(ref);
    return async.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.space4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              color: ext.surfaceElevated,
              border: Border.all(color: ext.accent.withValues(alpha: 0.42)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.play_circle_outline_rounded, size: 20, color: ext.accent),
                    const SizedBox(width: DesignTokens.space2),
                    Expanded(
                      child: Text(
                        surface.titleTr,
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
                  surface.subtitleTr,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ext.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: DesignTokens.space3),
                ...items.map((r) => _ReminderRow(reminder: r, surface: surface)),
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

class _ReminderRow extends ConsumerStatefulWidget {
  const _ReminderRow({
    required this.reminder,
    required this.surface,
  });

  final ExecutionReminderItem reminder;
  final ExecutionReminderSurface surface;

  @override
  ConsumerState<_ReminderRow> createState() => _ReminderRowState();
}

class _ReminderRowState extends ConsumerState<_ReminderRow> {
  bool _busy = false;

  Future<void> _suppress() async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    await ref.read(executionReminderDedupeStoreProvider).suppress(uid, widget.reminder.dedupeKey);
    widget.surface.invalidateReminders(ref);
  }

  Future<void> _createTask() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    final r = widget.reminder;
    final advisorId = (r.assigneeAdvisorId != null && r.assigneeAdvisorId!.isNotEmpty)
        ? r.assigneeAdvisorId!
        : uid;
    final due = DateTime.now().add(const Duration(days: 1));
    try {
      await FirestoreService.setTask({
        'advisorId': advisorId,
        'customerId': r.relatedCustomerId,
        'title': r.reminderTitleTr,
        'dueAt': Timestamp.fromDate(due),
        'done': false,
        'executionReminderSource': 'v1',
        'executionReminderCode': r.code.reminderCode,
      });
      await ref.read(executionReminderDedupeStoreProvider).suppress(uid, r.dedupeKey);
      widget.surface.invalidateReminders(ref);
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
          SnackBar(content: Text('Görev eklenemedi: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final r = widget.reminder;
    final pColor = switch (r.reminderPriority) {
      ExecutionReminderPriority.critical => ext.danger,
      ExecutionReminderPriority.high => ext.warning,
      ExecutionReminderPriority.medium => ext.textSecondary,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          color: ext.background.withValues(alpha: 0.4),
          border: Border.all(color: ext.border.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: pColor.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.customerName?.trim().isNotEmpty == true
                            ? r.customerName!.trim()
                            : 'Müşteri',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ext.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.reminderTitleTr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: ext.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.reminderDescriptionTr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: ext.textTertiary,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : _suppress,
                  icon: Icon(Icons.close_rounded, size: 18, color: ext.textTertiary),
                  tooltip: 'Gizle',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (r.suggestedActionCode == SuggestedActionCode.openCustomer)
                  _ActionChip(
                    label: 'Detay',
                    accent: true,
                    onTap: _busy
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            context.push('/customer/${r.relatedCustomerId}');
                          },
                  )
                else ...[
                  if (r.suggestedActionCode == SuggestedActionCode.createTask)
                    _ActionChip(
                      label: 'Görev',
                      accent: true,
                      onTap: _busy ? null : _createTask,
                    ),
                  if (r.suggestedActionCode == SuggestedActionCode.startCall ||
                      r.suggestedActionCode == SuggestedActionCode.confirmFollowUp)
                    _ActionChip(
                      label: 'Ara',
                      accent: true,
                      onTap: _busy
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              context.push(
                              AppRouter.routeCall,
                              extra: {
                                'customerId': r.relatedCustomerId,
                                'startedFromScreen': 'execution_reminder',
                              },
                            );
                            },
                    ),
                  _ActionChip(
                    label: 'Profil',
                    onTap: _busy
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            context.push('/customer/${r.relatedCustomerId}');
                          },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: accent ? ext.accent.withValues(alpha: 0.18) : ext.surface.withValues(alpha: 0.5),
            border: Border.all(
              color: accent ? ext.accent.withValues(alpha: 0.5) : ext.border.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: accent ? ext.accent : ext.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
