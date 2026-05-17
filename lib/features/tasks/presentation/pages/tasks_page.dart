import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_insight_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/features/tasks/domain/task_recurrence.dart';

/// Danışman görevleri: vade tarihine göre liste, yapıldı işaretleme, görev ekleme.
class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  int _tasksRetryKey = 0;
  final Set<String> _deletingIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final uid =
        ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    final bottomPad = DashboardLayoutTokens.shellScrollBottomPadding(context);
    return Scaffold(
      backgroundColor: AppThemeExtension.of(context).background,
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
                  const PremiumPageHeader(
                    title: ProductLabels.myTasks,
                    subtitle: 'Tüm görevlerini tek yerde yönet.',
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: ValueKey(_tasksRetryKey),
              stream: FirestoreService.tasksByAdvisorStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppThemeExtension.of(context).accent,
                      strokeWidth: 2,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.space6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: AppThemeExtension.of(context).textSecondary,
                          ),
                          const SizedBox(height: DesignTokens.space4),
                          Text(
                            'Görev akışı yüklenemedi.',
                            style: AppTypography.cardHeading(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: DesignTokens.space4),
                          TextButton(
                            onPressed: () => setState(() => _tasksRetryKey++),
                            child: const Text('Tekrar dene'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final docs = (snapshot.data?.docs ?? [])
                    .where((d) => !_deletingIds.contains(d.id))
                    .toList();
                if (docs.isEmpty) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      DesignTokens.space5,
                      0,
                      DesignTokens.space5,
                      bottomPad,
                    ),
                    child: Column(
                      children: [
                        PremiumEmptyState(
                          icon: Icons.task_alt_rounded,
                          title: AppLocalizations.of(context).t('empty_tasks'),
                          subtitle:
                              AppLocalizations.of(context).t('empty_tasks_sub'),
                          actionLabel:
                              AppLocalizations.of(context).t('empty_tasks_cta'),
                          onAction: () => _showAddTaskDialog(context, ref, uid),
                        ),
                        const SizedBox(height: DesignTokens.space6),
                        const PremiumSectionHeader(
                          label: 'Hızlı işlemler',
                          icon: Icons.bolt_rounded,
                        ),
                        _TasksQuickActionsRow(
                          onAddTask: () => _showAddTaskDialog(context, ref, uid),
                          onRecurring: () =>
                              _showRecurringTasksSheet(context, ref, uid),
                        ),
                        const SizedBox(height: DesignTokens.space6),
                        const _TasksWeeklyStatsStrip(),
                      ],
                    ),
                  );
                }
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final lowDensity = docs.isNotEmpty && docs.length <= 4;
                final headerCount = lowDensity ? 1 : 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        DesignTokens.space6,
                        DesignTokens.space4,
                        DesignTokens.space6,
                        bottomPad + 72,
                      ),
                      itemCount: docs.length + headerCount,
                      cacheExtent: 300,
                      itemBuilder: (context, index) {
                        if (lowDensity && index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: DesignTokens.space3),
                            child: Text(
                              'Yakın ajandanız',
                              style:
                                  AppTypography.cardHeading(context).copyWith(
                                color:
                                    AppThemeExtension.of(context).textSecondary,
                                fontSize: DesignTokens.fontSizeLg,
                              ),
                            ),
                          );
                        }
                        final docIndex = index - headerCount;
                        final doc = docs[docIndex];
                        final d = doc.data();
                        final id = doc.id;
                        final title = d['title'] as String? ?? 'Görev';
                        final dueAt = (d['dueAt'] as Timestamp?)?.toDate();
                        final done = d['done'] == true;
                        final customerId = d['customerId'] as String?;
                        return _TaskTile(
                          id: id,
                          title: title,
                          dueAt: dueAt,
                          done: done,
                          customerId: customerId,
                          isDeleting: _deletingIds.contains(id),
                          isOverdue:
                              dueAt != null && dueAt.isBefore(today) && !done,
                          onToggleDone: () => _toggleDone(id, d, !done),
                          onDelete: () => _confirmDeleteTask(id, title),
                          onTap: () => _showTaskDetailSheet(
                            context,
                            ref: ref,
                            uid: uid,
                            id: id,
                            data: d,
                            onToggleDone: () => _toggleDone(id, d, !done),
                            onDelete: () => _confirmDeleteTask(id, title),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        top: false,
                        child: _TasksDockedAddBar(
                          onPressed: () =>
                              _showAddTaskDialog(context, ref, uid),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
                  ),
                ],
              ),
            ),
    );
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
    var pickedDate = (data['dueAt'] as Timestamp?)?.toDate() ??
        (data['dueDate'] as Timestamp?)?.toDate();
    var recurrence = data['recurrence'] as String?;
    var saving = false;

    showPremiumScrollableBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final ext = AppThemeExtension.of(ctx);
          final recurrenceLabel = taskRecurrenceLabel(recurrence);
          return PremiumScrollableBottomSheetShell(
            title: 'Görev detayı',
            subtitle: done
                ? 'Tamamlandı'
                : recurrenceLabel != null
                    ? 'Tekrar: $recurrenceLabel'
                    : 'Düzenleyip kaydedin',
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
                  value: recurrence,
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
                    DropdownMenuItem(value: null, child: Text('Tek seferlik')),
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
      builder: (ctx) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.tasksByAdvisorStream(uid),
        builder: (context, snap) {
          final docs = (snap.data?.docs ?? [])
              .where((d) {
                final r = d.data()['recurrence'];
                return r is String && r.isNotEmpty;
              })
              .toList();
          return PremiumScrollableBottomSheetShell(
            title: 'Tekrar eden görevler',
            subtitle: docs.isEmpty
                ? 'Rutin görev tanımlayın; tamamlanınca sonraki vade otomatik eklenir.'
                : '${docs.length} rutin kayıt',
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
                            value: recurrence,
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
                                value: null,
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

class _TasksDockedAddBar extends StatelessWidget {
  const _TasksDockedAddBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.surfaceElevated,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: ext.border.withValues(alpha: 0.5)),
          ),
          boxShadow: [
            BoxShadow(
              color: ext.shadowColor.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space6,
            DesignTokens.space3,
            DesignTokens.space6,
            DesignTokens.space3,
          ),
          child: FilledButton.icon(
            onPressed: () {
              AppFeedback.mediumImpact();
              onPressed();
            },
            icon: Icon(Icons.add_rounded, color: ext.onBrand, size: 22),
            label: Text(
              'Yeni görev',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: ext.onBrand,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: ext.accent,
              foregroundColor: ext.onBrand,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.id,
    required this.title,
    this.dueAt,
    required this.done,
    this.customerId,
    required this.isDeleting,
    required this.isOverdue,
    required this.onToggleDone,
    required this.onDelete,
    required this.onTap,
  });

  final String id;
  final String title;
  final DateTime? dueAt;
  final bool done;
  final String? customerId;
  final bool isDeleting;
  final bool isOverdue;
  final VoidCallback onToggleDone;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: DesignTokens.space3),
      color: ext.surfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
        side: BorderSide(
          color: isOverdue
              ? ext.danger.withValues(alpha: 0.42)
              : ext.border.withValues(alpha: 0.55),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: done,
                onChanged: isDeleting ? null : (_) => onToggleDone(),
                activeColor: ext.accent,
                side: BorderSide(color: ext.border.withValues(alpha: 0.8)),
                fillColor: WidgetStateProperty.resolveWith((_) {
                  return done ? ext.accent : Colors.transparent;
                }),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.cardHeading(context).copyWith(
                        color: done
                            ? ext.textSecondary.withValues(alpha: 0.72)
                            : ext.textPrimary,
                        fontSize: DesignTokens.fontSizeMd,
                        fontWeight: done ? FontWeight.w500 : FontWeight.w700,
                        fontStyle: done ? FontStyle.italic : FontStyle.normal,
                        height: 1.25,
                      ),
                    ),
                    if (dueAt != null) ...[
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        _formatDue(dueAt!, isOverdue),
                        style: AppTypography.meta(context).copyWith(
                          color: isOverdue ? ext.danger : ext.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (customerId != null && customerId!.isNotEmpty) ...[
                      const SizedBox(height: DesignTokens.space2),
                      InkWell(
                        onTap: () => context.push(
                          AppRouter.routeCustomerDetail.replaceFirst(
                            ':id',
                            customerId!,
                          ),
                        ),
                        child: Text(
                          'Müşteriye git →',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: ext.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Görevi sil',
                onPressed: isDeleting ? null : onDelete,
                icon: isDeleting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ext.danger,
                        ),
                      )
                    : Icon(
                        Icons.delete_outline_rounded,
                        color: ext.danger,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDue(DateTime due, bool isOverdue) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;
    if (diff == 0) return 'Bugün';
    if (diff == 1) return 'Yarın';
    if (diff == -1) return 'Dün (geçti)';
    if (diff < -1) return '${-diff} gün önce (geçti)';
    return '${due.day}.${due.month}.${due.year}';
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

class _TasksWeeklyStatsStrip extends StatelessWidget {
  const _TasksWeeklyStatsStrip();

  @override
  Widget build(BuildContext context) {
    const stats = [
      ('0', 'Tamamlanan'),
      ('0', 'Devam eden'),
      ('0', 'Hatırlatma'),
      ('0%', 'Tamamlama'),
    ];
    return PremiumSurfaceCard(
      padding: const EdgeInsets.symmetric(
        vertical: DesignTokens.space4,
        horizontal: DesignTokens.space3,
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 36,
                color: AppThemeExtension.of(context)
                    .border
                    .withValues(alpha: 0.35),
              ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    stats[i].$1,
                    style: AppTypography.metricValue(context).copyWith(
                      fontSize: DesignTokens.fontSizeLg,
                    ),
                  ),
                  Text(
                    stats[i].$2,
                    style: TextStyle(
                      color: AppThemeExtension.of(context).textTertiary,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
