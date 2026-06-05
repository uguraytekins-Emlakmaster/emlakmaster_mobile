// Görev CRUD / sheet akışları — workspace ve yüzey paylaşır.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/navigation/sheet_back_behavior.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_insight_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/domain/task_recurrence.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_stream_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/utils/task_list_filter.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class ConsultantTaskFlows {
  ConsultantTaskFlows._();
  static Future<void> postponeTask(
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
    if (!context.mounted || choice == null) return;

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
      if (context.mounted) {
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erteleme başarısız: ${e.message ?? e.code}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on StateError catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static Future<void> toggleDone(
    BuildContext context,
    WidgetRef ref,
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
        if (context.mounted) {
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görev kaydı güncellenemedi: ${e.message ?? e.code}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on StateError catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static Future<void> confirmDeleteTask(
    BuildContext context,
    String id,
    String title) async {
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
    if (ok != true || !context.mounted) return;
    await ConsultantTaskFlows.deleteTask(context, id);
  }

  static Future<void> deleteTask(BuildContext context, String id) async {
    AppFeedback.mediumImpact();
    try {
      await FirestoreService.deleteTask(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Görev kaydı kaldırıldı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görev kaydı kaldırılamadı: ${e.message ?? e.code}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on StateError catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görev kaydı kaldırılamadı: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static void showTaskDetailSheet(
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

  static void showRecurringTasksSheet(
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
                ConsultantTaskFlows.showAddTaskDialog(
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
                        ConsultantTaskFlows.showTaskDetailSheet(
                          context,
                          ref: ref,
                          uid: uid,
                          id: doc.id,
                          data: d,
                          onToggleDone: () => ConsultantTaskFlows.toggleDone(context, ref, 
                            doc.id,
                            d,
                            !(d['done'] == true),
                          ),
                          onDelete: () => ConsultantTaskFlows.confirmDeleteTask(context, doc.id, title),
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

  static void showAddTaskDialog(
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
        // Klavye boşluğu (viewInsets.bottom) shell tarafından zaten eklenir
        // (showPremiumScrollableBottomSheet). Burada tekrar eklemek çift sayım
        // → taşma yaratır; bu yüzden yalnızca sabit alt boşluk bırakılır.
        final viewInsets = MediaQuery.viewInsetsOf(ctx);
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space5,
              0,
              DesignTokens.space5,
              DesignTokens.space6,
            ),
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
          );
      },
    );
  }
}
