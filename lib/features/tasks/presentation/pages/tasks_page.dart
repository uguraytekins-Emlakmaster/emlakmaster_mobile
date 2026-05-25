import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/navigation/sheet_back_behavior.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_insight_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/consultant_tasks_tokens.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/models/task_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/utils/task_list_filter.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/widgets/consultant_tasks_chrome.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/features/tasks/domain/task_recurrence.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_display_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_stream_provider.dart';

/// Danışman görevleri: vade tarihine göre liste, yapıldı işaretleme, görev ekleme.
class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  final _readyTracker = ShellScreenReadyTracker('tasks');
  int _tasksRetryKey = 0;
  final Set<String> _deletingIds = <String>{};
  TaskListFilter _listFilter = TaskListFilter.all;

  double _tasksDockBottomReserve(BuildContext context) {
    final ts = MediaQuery.textScalerOf(context);
    final ratio =
        ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
    final clamped = ratio.clamp(1.0, 1.38);
    return 120 * clamped;
  }

  @override
  Widget build(BuildContext context) {
    final uid =
        ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    if (uid.isNotEmpty) {
      ref.listen(advisorTasksDisplayProvider(uid), (previous, next) {
        if (next.hasValue) {
          _readyTracker.onContentReady(itemCount: next.value!.length);
        }
      });
    }
    final dockReserve = _tasksDockBottomReserve(context);

    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: uid.isEmpty
            ? Center(
                child: Text(
                  'Oturum açık değil.',
                  style: AppTypography.body(context),
                ),
              )
            : SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Builder(
                        key: ValueKey(_tasksRetryKey),
                        builder: (context) {
                          final tasksAsync =
                              ref.watch(advisorTasksDisplayProvider(uid));
                          if (tasksAsync.isLoading && !tasksAsync.hasValue) {
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          if (tasksAsync.hasError && !tasksAsync.hasValue) {
                            return _TasksErrorState(
                              onRetry: () {
                                ref.invalidate(advisorTasksStreamProvider(uid));
                                ref.invalidate(
                                    advisorTasksStaleCacheProvider(uid));
                                setState(() => _tasksRetryKey++);
                              },
                            );
                          }

                          final now = DateTime.now();
                          final today =
                              DateTime(now.year, now.month, now.day);
                          final allDocs = (tasksAsync.valueOrNull ?? [])
                              .where((d) => !_deletingIds.contains(d.id))
                              .toList();
                          final summary =
                              computeTaskListSummary(allDocs, today);
                          final filtered = allDocs
                              .where((d) =>
                                  matchesTaskListFilter(d, _listFilter, today))
                              .toList();
                          final showDock = allDocs.isNotEmpty;

                          return CustomScrollView(
                            cacheExtent: 320,
                            slivers: [
                              SliverToBoxAdapter(
                                child: PremiumTasksPageHeader(
                                  title: ProductLabels.myTasks,
                                  subtitle:
                                      'Ajanda, takip ve hatırlatmalar — tek ekran.',
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: PremiumTasksSummaryStrip(
                                  summary: summary,
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: PremiumTaskFilterStrip(
                                  selected: _listFilter,
                                  onSelected: (f) =>
                                      setState(() => _listFilter = f),
                                ),
                              ),
                              if (filtered.isEmpty)
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      ConsultantTasksTokens.horizontal,
                                      0,
                                      ConsultantTasksTokens.horizontal,
                                      dockReserve,
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: PremiumEmptyState(
                                            icon: Icons.task_alt_rounded,
                                            title: AppLocalizations.of(context)
                                                .t('empty_tasks'),
                                            subtitle: AppLocalizations.of(
                                                    context)
                                                .t('empty_tasks_sub'),
                                            actionLabel: AppLocalizations.of(
                                                    context)
                                                .t('empty_tasks_cta'),
                                            onAction: () => _showAddTaskDialog(
                                                context, ref, uid),
                                          ),
                                        ),
                                        const PremiumSectionHeader(
                                          label: 'Hızlı işlemler',
                                          icon: Icons.bolt_rounded,
                                        ),
                                        _TasksQuickActionsRow(
                                          onAddTask: () => _showAddTaskDialog(
                                              context, ref, uid),
                                          onRecurring: () =>
                                              _showRecurringTasksSheet(
                                                  context, ref, uid),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                SliverPadding(
                                  padding: EdgeInsets.fromLTRB(
                                    ConsultantTasksTokens.horizontal,
                                    0,
                                    ConsultantTasksTokens.horizontal,
                                    showDock ? dockReserve : dockReserve / 2,
                                  ),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final doc = filtered[index];
                                        final d = doc.data();
                                        final id = doc.id;
                                        final title =
                                            d['title'] as String? ?? 'Görev';
                                        final done = taskDocIsDone(d);
                                        final customerId =
                                            d['customerId'] as String?;
                                        final row =
                                            TaskListRowSnapshot.fromTaskData(
                                          d,
                                          today: today,
                                        );
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 6),
                                          child: RepaintBoundary(
                                            child: TaskCard(
                                              taskId: id,
                                              title: title,
                                              done: done,
                                              row: row,
                                              customerId: customerId,
                                              isDeleting:
                                                  _deletingIds.contains(id),
                                              onTap: () => _showTaskDetailSheet(
                                                context,
                                                ref: ref,
                                                uid: uid,
                                                id: id,
                                                data: d,
                                                onToggleDone: () =>
                                                    _toggleDone(id, d, !done),
                                                onDelete: () =>
                                                    _confirmDeleteTask(
                                                        id, title),
                                              ),
                                              onComplete: () =>
                                                  _toggleDone(id, d, !done),
                                              onPostpone: done
                                                  ? null
                                                  : () => _postponeTask(
                                                        context,
                                                        id: id,
                                                        data: d,
                                                      ),
                                              onOpenCustomer: customerId !=
                                                          null &&
                                                      customerId.isNotEmpty
                                                  ? () => context.push(
                                                        AppRouter
                                                            .routeCustomerDetail
                                                            .replaceFirst(
                                                          ':id',
                                                          customerId,
                                                        ),
                                                      )
                                                  : null,
                                              onEdit: () => _showTaskDetailSheet(
                                                context,
                                                ref: ref,
                                                uid: uid,
                                                id: id,
                                                data: d,
                                                onToggleDone: () =>
                                                    _toggleDone(id, d, !done),
                                                onDelete: () =>
                                                    _confirmDeleteTask(
                                                        id, title),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      childCount: filtered.length,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (uid.isNotEmpty)
                      Builder(
                        builder: (context) {
                          final tasksAsync =
                              ref.watch(advisorTasksDisplayProvider(uid));
                          final hasTasks = tasksAsync.valueOrNull
                                  ?.where((d) => !_deletingIds.contains(d.id))
                                  .isNotEmpty ??
                              false;
                          if (!hasTasks) return const SizedBox.shrink();
                          return _TasksAddDockBar(
                            onPressed: () =>
                                _showAddTaskDialog(context, ref, uid),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _postponeTask(
    BuildContext context, {
    required String id,
    required Map<String, dynamic> data,
  }) async {
    AppFeedback.lightImpact();
    final currentDue = taskDocDueAt(data) ?? DateTime.now();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        final ext = AppThemeExtension.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.wb_sunny_outlined, color: ext.accent),
                title: const Text('Yarına ertele'),
                onTap: () => Navigator.pop(ctx, 'tomorrow'),
              ),
              ListTile(
                leading: Icon(Icons.date_range_outlined, color: ext.accent),
                title: const Text('3 gün sonra'),
                onTap: () => Navigator.pop(ctx, 'three_days'),
              ),
              ListTile(
                leading: Icon(Icons.calendar_today_outlined, color: ext.accent),
                title: const Text('Tarih seç'),
                onTap: () => Navigator.pop(ctx, 'pick'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || choice == null) return;

    DateTime? newDue;
    switch (choice) {
      case 'tomorrow':
        newDue = currentDue.add(const Duration(days: 1));
      case 'three_days':
        newDue = currentDue.add(const Duration(days: 3));
      case 'pick':
        if (!context.mounted) return;
        final picked = await showDatePicker(
          context: context,
          initialDate: currentDue.add(const Duration(days: 1)),
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 730)),
        );
        if (picked == null) return;
        newDue = picked;
    }
    if (newDue == null) return;

    try {
      await FirestoreService.setTask({
        ...data,
        'id': id,
        'dueAt': Timestamp.fromDate(newDue),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Görev ${newDue.day}.${newDue.month}.${newDue.year} tarihine ertelendi.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erteleme başarısız: ${e.message ?? e.code}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleDone(
    String id,
    Map<String, dynamic> current,
    bool done,
  ) async {
    AppFeedback.lightImpact();
    final wasDone = current['done'] == true;
    final customerId = (current['customerId'] as String?)?.trim();
    try {
      await FirestoreService.setTask({
        ...current,
        'id': id,
        'done': done,
      });
      if (!wasDone &&
          done &&
          current['recurrence'] is String &&
          (current['recurrence'] as String).isNotEmpty) {
        final due = (current['dueAt'] as Timestamp?)?.toDate() ??
            (current['dueDate'] as Timestamp?)?.toDate() ??
            DateTime.now();
        final recurrence = current['recurrence'] as String;
        final title = current['title'] as String? ?? 'Görev';
        await FirestoreService.setTask({
          'advisorId': current['advisorId'] as String? ?? '',
          'title': title,
          'dueAt': Timestamp.fromDate(nextDueForRecurrence(due, recurrence)),
          'done': false,
          'recurrence': recurrence,
          if (customerId != null && customerId.isNotEmpty)
            'customerId': customerId,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tekrar eden görev: sonraki vade ${taskRecurrenceLabel(recurrence)?.toLowerCase() ?? ''} için eklendi.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      if (!wasDone && done && customerId != null && customerId.isNotEmpty) {
        try {
          await FirestoreService.mergeCustomerCrmAfterTaskCompleted(customerId);
          ref.invalidate(customerInsightProvider(customerId));
        } catch (e, st) {
          AppLogger.w(
              'Müşteri CRM geri bildirimi (görev sonrası) yazılamadı', e, st);
        }
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görev kaydı güncellenemedi: ${e.message ?? e.code}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDeleteTask(String id, String title) async {
    AppFeedback.lightImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final ext = AppThemeExtension.of(ctx);
        return AlertDialog(
          backgroundColor: ext.surface,
          title: Text(
            'Görev kaldırılsın mı?',
            style: TextStyle(color: ext.textPrimary),
          ),
          content: Text(
            '"$title" kaydı kalıcı olarak kaldırılacak.',
            style: TextStyle(color: ext.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Şimdilik kalsın',
                style: TextStyle(color: ext.textSecondary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: ext.danger,
                foregroundColor:
                    ThemeData.estimateBrightnessForColor(ext.danger) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    await _deleteTask(id);
  }

  Future<void> _deleteTask(String id) async {
    if (_deletingIds.contains(id)) return;
    AppFeedback.mediumImpact();
    setState(() => _deletingIds.add(id));
    try {
      await FirestoreService.deleteTask(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Görev kaydı kaldırıldı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görev kaydı kaldırılamadı: ${e.message ?? e.code}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görev kaydı kaldırılamadı: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showTaskDetailSheet(
    BuildContext context, {
    required WidgetRef ref,
    required String uid,
    required String id,
    required Map<String, dynamic> data,
    required VoidCallback onToggleDone,
    required VoidCallback onDelete,
  }) {
    AppFeedback.lightImpact();
    final titleController =
        TextEditingController(text: data['title'] as String? ?? '');
    final customerId = (data['customerId'] as String?)?.trim();
    final done = data['done'] == true;
    final initialTitle = data['title'] as String? ?? '';
    final initialDue = (data['dueAt'] as Timestamp?)?.toDate() ??
        (data['dueDate'] as Timestamp?)?.toDate();
    var pickedDate = initialDue;
    final initialRecurrence = data['recurrence'] as String?;
    var recurrence = initialRecurrence;
    var saving = false;

    showPremiumScrollableBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final ext = AppThemeExtension.of(ctx);
          final recurrenceLabel = taskRecurrenceLabel(recurrence);
          final dirty = titleController.text.trim() != initialTitle.trim() ||
              recurrence != initialRecurrence ||
              pickedDate?.millisecondsSinceEpoch !=
                  initialDue?.millisecondsSinceEpoch;
          return sheetBackWrapper(
            isDirty: dirty && !saving,
            child: PremiumScrollableBottomSheetShell(
            title: 'Görev detayı',
            subtitle: done
                ? 'Tamamlandı'
                : recurrenceLabel != null
                    ? 'Tekrar: $recurrenceLabel'
                    : 'Düzenleyip kaydedin',
            bottomActions: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;
                          setModal(() => saving = true);
                          try {
                            await FirestoreService.setTask({
                              ...data,
                              'id': id,
                              'advisorId': uid,
                              'title': title,
                              if (pickedDate != null)
                                'dueAt': Timestamp.fromDate(pickedDate!),
                              'recurrence': recurrence,
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              showPremiumActionFeedback(
                                context,
                                title: 'Görev güncellendi',
                                message: 'Değişiklikler kaydedildi.',
                                type: PremiumActionFeedbackType.success,
                                useSheet: false,
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('Kaydedilemedi: $e'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } finally {
                            if (ctx.mounted) setModal(() => saving = false);
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: ext.accent,
                    foregroundColor: ext.onBrand,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: saving
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ext.onBrand,
                          ),
                        )
                      : const Text('Kaydet'),
                ),
                const SizedBox(height: DesignTokens.space2),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onToggleDone();
                  },
                  icon: Icon(done ? Icons.undo_rounded : Icons.check_rounded),
                  label: Text(done ? 'Yeniden aç' : 'Tamamlandı işaretle'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ext.surfaceElevated,
                    foregroundColor: ext.textPrimary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: DesignTokens.space2),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onDelete();
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Görevi sil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ext.danger,
                    side: BorderSide(color: ext.danger.withValues(alpha: 0.6)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    filled: true,
                    fillColor: ext.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: pickedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (date != null) setModal(() => pickedDate = date);
                  },
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: Text(
                    pickedDate != null
                        ? '${pickedDate!.day}.${pickedDate!.month}.${pickedDate!.year}'
                        : 'Vade tarihi seç',
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),
                DropdownButtonFormField<String?>(
                  initialValue: recurrence,
                  decoration: InputDecoration(
                    labelText: 'Tekrar',
                    filled: true,
                    fillColor: ext.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      child: Text('Tek seferlik'),
                    ),
                    DropdownMenuItem(value: 'daily', child: Text('Her gün')),
                    DropdownMenuItem(value: 'weekly', child: Text('Her hafta')),
                    DropdownMenuItem(value: 'monthly', child: Text('Her ay')),
                  ],
                  onChanged: (v) => setModal(() => recurrence = v),
                ),
                if (customerId != null && customerId.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.space3),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(
                        AppRouter.routeCustomerDetail
                            .replaceFirst(':id', customerId),
                      );
                    },
                    icon: const Icon(Icons.person_rounded),
                    label: const Text('Müşteriyi aç'),
                  ),
                ],
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  void _showRecurringTasksSheet(
    BuildContext context,
    WidgetRef ref,
    String uid,
  ) {
    AppFeedback.lightImpact();
    showPremiumScrollableBottomSheet<void>(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final snap = ref.watch(advisorTasksStreamProvider(uid));
          final docs = snap.when(
            data: (snapshot) => snapshot.docs
                .where((d) {
                  final r = d.data()['recurrence'];
                  return r is String && r.isNotEmpty;
                })
                .toList(),
            loading: () => <QueryDocumentSnapshot<Map<String, dynamic>>>[],
            error: (_, __) => <QueryDocumentSnapshot<Map<String, dynamic>>>[],
          );
          return PremiumScrollableBottomSheetShell(
            title: 'Tekrar eden görevler',
            subtitle: docs.isEmpty
                ? 'Rutin görev tanımlayın; tamamlanınca sonraki vade otomatik eklenir.'
                : '${docs.length} rutin kayıt',
            bottomActions: FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showAddTaskDialog(
                  context,
                  ref,
                  uid,
                  initialRecurrence: 'weekly',
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Rutin görev ekle'),
              style: FilledButton.styleFrom(
                backgroundColor: AppThemeExtension.of(ctx).accent,
                foregroundColor: AppThemeExtension.of(ctx).onBrand,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (docs.isEmpty)
                  Text(
                    'Henüz tekrarlı görev yok. Yeni görev eklerken “Tekrar” alanından günlük, haftalık veya aylık seçebilirsiniz.',
                    style: AppTypography.body(ctx),
                  )
                else
                  ...docs.map((doc) {
                    final d = doc.data();
                    final title = d['title'] as String? ?? 'Görev';
                    final recurrence = d['recurrence'] as String? ?? '';
                    final due = (d['dueAt'] as Timestamp?)?.toDate();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(title),
                      subtitle: Text(
                        '${taskRecurrenceLabel(recurrence) ?? recurrence}'
                        '${due != null ? ' · ${due.day}.${due.month}.${due.year}' : ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showTaskDetailSheet(
                          context,
                          ref: ref,
                          uid: uid,
                          id: doc.id,
                          data: d,
                          onToggleDone: () => _toggleDone(
                            doc.id,
                            d,
                            !(d['done'] == true),
                          ),
                          onDelete: () => _confirmDeleteTask(doc.id, title),
                        );
                      },
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddTaskDialog(
    BuildContext context,
    WidgetRef ref,
    String uid, {
    String? initialRecurrence,
  }) {
    AppFeedback.lightImpact();
    final titleController = TextEditingController();
    final customerIdController = TextEditingController();
    DateTime? pickedDate;
    String? recurrence = initialRecurrence;

    showPremiumModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final viewInsets = MediaQuery.viewInsetsOf(ctx);
        final bottomPad = viewInsets.bottom + DesignTokens.space6;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(bottom: bottomPad),
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: DesignTokens.space5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PremiumBottomSheetHandle(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      DesignTokens.space2,
                      0,
                      DesignTokens.space3,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.task_alt_outlined,
                          size: DesignTokens.iconLg,
                          color: AppThemeExtension.of(ctx)
                              .accent
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: DesignTokens.space3),
                        const Expanded(
                          child: PremiumSheetHeader(
                            compact: true,
                            title: 'Yeni görev kaydı',
                            subtitle:
                                'Vade ve müşteri bağlantısı isteğe bağlıdır. Kaydettiğiniz iş burada akışa düşer.',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Kapat',
                          style: IconButton.styleFrom(
                            foregroundColor:
                                AppThemeExtension.of(ctx).textTertiary,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                      height: viewInsets.bottom > 0
                          ? DesignTokens.space4
                          : DesignTokens.space3),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Görev başlığı',
                      labelStyle: TextStyle(
                          color: AppThemeExtension.of(context).textSecondary),
                      filled: true,
                      fillColor: AppThemeExtension.of(context).background,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                    ),
                    style: TextStyle(
                        color: AppThemeExtension.of(context).textPrimary),
                    autofocus: true,
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  TextField(
                    controller: customerIdController,
                    decoration: InputDecoration(
                      labelText: 'Müşteri ID (opsiyonel)',
                      hintText: 'Müşteri detaydan kopyalayabilirsiniz',
                      labelStyle: TextStyle(
                          color: AppThemeExtension.of(context).textSecondary),
                      filled: true,
                      fillColor: AppThemeExtension.of(context).background,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                    ),
                    style: TextStyle(
                        color: AppThemeExtension.of(context).textPrimary),
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  StatefulBuilder(
                    builder: (ctx, setModalState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: ctx,
                                initialDate:
                                    DateTime.now().add(const Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setModalState(() => pickedDate = date);
                              }
                            },
                            icon: Icon(
                              Icons.calendar_today_rounded,
                              size: DesignTokens.iconMd,
                              color: AppThemeExtension.of(context).accent,
                            ),
                            label: Text(
                              pickedDate != null
                                  ? '${pickedDate!.day}.${pickedDate!.month}.${pickedDate!.year}'
                                  : 'Vade tarihi seç',
                              style: TextStyle(
                                  color: AppThemeExtension.of(context).accent),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  AppThemeExtension.of(context).accent,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusControl,
                                ),
                              ),
                              side: BorderSide(
                                color: AppThemeExtension.of(context).accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: DesignTokens.space3),
                          DropdownButtonFormField<String?>(
                            initialValue: recurrence,
                            decoration: InputDecoration(
                              labelText: 'Tekrar',
                              filled: true,
                              fillColor:
                                  AppThemeExtension.of(context).background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusControl,
                                ),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                child: Text('Tek seferlik'),
                              ),
                              DropdownMenuItem(
                                value: 'daily',
                                child: Text('Her gün'),
                              ),
                              DropdownMenuItem(
                                value: 'weekly',
                                child: Text('Her hafta'),
                              ),
                              DropdownMenuItem(
                                value: 'monthly',
                                child: Text('Her ay'),
                              ),
                            ],
                            onChanged: (v) =>
                                setModalState(() => recurrence = v),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(
                      height: viewInsets.bottom > 0
                          ? DesignTokens.space5
                          : DesignTokens.space6),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'İptal',
                            style: TextStyle(
                                color: AppThemeExtension.of(context)
                                    .textSecondary),
                          ),
                        ),
                      ),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final title = titleController.text.trim();
                            if (title.isEmpty) return;
                            Navigator.pop(ctx);
                            final custId = customerIdController.text.trim();
                            try {
                              await FirestoreService.setTask({
                                'advisorId': uid,
                                'title': title,
                                'dueAt': pickedDate != null
                                    ? Timestamp.fromDate(pickedDate!)
                                    : Timestamp.fromDate(
                                        DateTime.now()
                                            .add(const Duration(days: 1)),
                                      ),
                                'done': false,
                                if (custId.isNotEmpty) 'customerId': custId,
                                if (recurrence != null && recurrence!.isNotEmpty)
                                  'recurrence': recurrence,
                              });
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: const Text('Görev eklendi.'),
                                    backgroundColor:
                                        AppThemeExtension.of(context).accent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } on FirebaseException catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Görev eklenemedi: ${e.message ?? e.code}'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } on StateError catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(e.message),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                AppThemeExtension.of(context).accent,
                            foregroundColor:
                                AppThemeExtension.of(context).onBrand,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusControl,
                              ),
                            ),
                          ),
                          child: const Text('Ekle'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TasksAddDockBar extends StatelessWidget {
  const _TasksAddDockBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Semantics(
      container: true,
      label: 'Yeni görev ekle',
      child: Material(
        color: ext.surfaceElevated,
        elevation: 10,
        shadowColor: ext.shadowColor.withValues(alpha: 0.28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: ext.border.withValues(alpha: 0.55)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              ConsultantTasksTokens.horizontal,
              DesignTokens.space3,
              ConsultantTasksTokens.horizontal,
              DesignTokens.space4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ajandaya ekle',
                  textAlign: TextAlign.center,
                  style: AppTypography.meta(context).copyWith(
                    color: ext.textTertiary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: DesignTokens.space2),
                FilledButton.icon(
                  onPressed: () {
                    AppFeedback.mediumImpact();
                    onPressed();
                  },
                  icon: Icon(Icons.add_rounded, color: ext.onBrand, size: 20),
                  label: Text(
                    'Yeni görev',
                    style: AppTypography.bodyStrong(context).copyWith(
                      color: ext.onBrand,
                      fontSize: DesignTokens.fontSizeMd,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: ext.accent,
                    foregroundColor: ext.onBrand,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TasksErrorState extends StatelessWidget {
  const _TasksErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: ext.textSecondary,
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              'Görev akışı yüklenemedi.',
              style: AppTypography.cardHeading(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space4),
            TextButton(
              onPressed: onRetry,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksQuickActionsRow extends ConsumerWidget {
  const _TasksQuickActionsRow({
    required this.onAddTask,
    required this.onRecurring,
  });

  final VoidCallback onAddTask;
  final VoidCallback onRecurring;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _TasksQuickActionCard(
            icon: Icons.event_repeat_rounded,
            title: 'Takip et',
            subtitle: 'Takip akışı',
            onTap: () {
              AppFeedback.lightImpact();
              ref
                  .read(mainShellShortcutProvider.notifier)
                  .enqueue(MainShellShortcut.openFollowUpTab);
              context.go(AppRouter.routeHome);
            },
          ),
        ),
        const SizedBox(width: DesignTokens.space2),
        Expanded(
          child: _TasksQuickActionCard(
            icon: Icons.notifications_active_outlined,
            title: 'Hatırlat',
            subtitle: 'Görev ekle',
            onTap: () {
              AppFeedback.lightImpact();
              onAddTask();
            },
          ),
        ),
        const SizedBox(width: DesignTokens.space2),
        Expanded(
          child: _TasksQuickActionCard(
            icon: Icons.timer_outlined,
            title: 'Tekrar eden',
            subtitle: 'Rutin görev',
            onTap: () {
              AppFeedback.lightImpact();
              onRecurring();
            },
          ),
        ),
        const SizedBox(width: DesignTokens.space2),
        Expanded(
          child: _TasksQuickActionCard(
            icon: Icons.bar_chart_rounded,
            title: 'Raporlar',
            subtitle: 'Özet gör',
            onTap: () => context.push(AppRouter.routePipeline),
          ),
        ),
      ],
    );
  }
}

class _TasksQuickActionCard extends StatelessWidget {
  const _TasksQuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return PremiumSurfaceCard(
      onTap: onTap ??
          () => showPremiumActionFeedback(
                context,
                title: title,
                message: 'Bu kısayol henüz bağlanmadı.',
                type: PremiumActionFeedbackType.warning,
              ),
      padding: const EdgeInsets.all(DesignTokens.space3),
      child: Column(
        children: [
          Icon(icon, color: ext.accent, size: 22),
          const SizedBox(height: DesignTokens.space2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ext.textPrimary,
              fontSize: DesignTokens.fontSizeXs,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: 9,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
