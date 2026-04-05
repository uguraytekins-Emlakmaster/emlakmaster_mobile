import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_insight_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
/// Danışman görevleri: vade tarihine göre liste, yapıldı işaretleme, görev ekleme.
class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  int _tasksRetryKey = 0;

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    return Scaffold(
      backgroundColor: AppThemeExtension.of(context).background,
      appBar: emlakAppBar(
        context,
        backgroundColor: AppThemeExtension.of(context).background,
        foregroundColor: AppThemeExtension.of(context).textPrimary,
        title: const Text('Görevlerim'),
      ),
      body: uid.isEmpty
          ? Center(
              child: Text(
                'Giriş yapılmamış.',
                style: TextStyle(color: AppThemeExtension.of(context).textSecondary),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                            'Görevler yüklenemedi.',
                            style: TextStyle(
                              color: AppThemeExtension.of(context).textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
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
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: EmptyState(
                      premiumVisual: true,
                      icon: Icons.task_alt_rounded,
                      title: AppLocalizations.of(context).t('empty_tasks'),
                      subtitle: AppLocalizations.of(context).t('empty_tasks_sub'),
                      actionLabel: AppLocalizations.of(context).t('empty_tasks_cta'),
                      onAction: () => _showAddTaskDialog(context, ref, uid),
                    ),
                  );
                }
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.space6,
                        DesignTokens.space2,
                        DesignTokens.space6,
                        88,
                      ),
                      itemCount: docs.length,
                      cacheExtent: 300,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
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
                          isOverdue: dueAt != null &&
                              dueAt.isBefore(today) &&
                              !done,
                          onToggleDone: () => _toggleDone(id, d, !done),
                          onTap: () => _toggleDone(id, d, !done),
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
                          onPressed: () => _showAddTaskDialog(context, ref, uid),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _toggleDone(
    String id,
    Map<String, dynamic> current,
    bool done,
  ) async {
    HapticFeedback.lightImpact();
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
          customerId != null &&
          customerId.isNotEmpty) {
        try {
          await FirestoreService.mergeCustomerCrmAfterTaskCompleted(customerId);
          ref.invalidate(customerInsightProvider(customerId));
        } catch (e, st) {
          AppLogger.w('Müşteri CRM geri bildirimi (görev sonrası) yazılamadı', e, st);
        }
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görev güncellenemedi: ${e.message ?? e.code}'),
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

  void _showAddTaskDialog(BuildContext context, WidgetRef ref, String uid) {
    HapticFeedback.lightImpact();
    final titleController = TextEditingController();
    final customerIdController = TextEditingController();
    DateTime? pickedDate;

    showPremiumModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.space6,
            right: DesignTokens.space6,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + DesignTokens.space6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PremiumBottomSheetHandle(),
              const SizedBox(height: DesignTokens.space4),
              const PremiumSheetHeader(
                title: 'Yeni görev',
                subtitle: 'Vade ve müşteri bağlantısı opsiyonel; görevler Görevler sekmesinde listelenir.',
              ),
              const SizedBox(height: DesignTokens.space4),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Görev başlığı',
                  labelStyle: TextStyle(color: AppThemeExtension.of(context).textSecondary),
                  filled: true,
                  fillColor: AppThemeExtension.of(context).background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
                style: TextStyle(color: AppThemeExtension.of(context).textPrimary),
                autofocus: true,
              ),
              const SizedBox(height: DesignTokens.space4),
              TextField(
                controller: customerIdController,
                decoration: InputDecoration(
                  labelText: 'Müşteri ID (opsiyonel)',
                  hintText: 'Müşteri detaydan kopyalayabilirsiniz',
                  labelStyle: TextStyle(color: AppThemeExtension.of(context).textSecondary),
                  filled: true,
                  fillColor: AppThemeExtension.of(context).background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
                style: TextStyle(color: AppThemeExtension.of(context).textPrimary),
              ),
              const SizedBox(height: DesignTokens.space4),
              StatefulBuilder(
                builder: (ctx, setModalState) {
                  return OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setModalState(() => pickedDate = date);
                      }
                    },
                    icon: Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppThemeExtension.of(context).accent,
                    ),
                    label: Text(
                      pickedDate != null
                          ? '${pickedDate!.day}.${pickedDate!.month}.${pickedDate!.year}'
                          : 'Vade tarihi seç',
                      style: TextStyle(color: AppThemeExtension.of(context).accent),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppThemeExtension.of(context).accent,
                      side: BorderSide(color: AppThemeExtension.of(context).accent),
                    ),
                  );
                },
              ),
              const SizedBox(height: DesignTokens.space6),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'İptal',
                        style: TextStyle(color: AppThemeExtension.of(context).textSecondary),
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
                                    DateTime.now().add(const Duration(days: 1)),
                                  ),
                            'done': false,
                            if (custId.isNotEmpty) 'customerId': custId,
                          });
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: const Text('Görev eklendi.'),
                                backgroundColor: AppThemeExtension.of(context).accent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } on FirebaseException catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Görev eklenemedi: ${e.message ?? e.code}'),
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
                        backgroundColor: AppThemeExtension.of(context).accent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Ekle'),
                    ),
                  ),
                ],
              ),
            ],
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
              HapticFeedback.mediumImpact();
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
    required this.isOverdue,
    required this.onToggleDone,
    required this.onTap,
  });

  final String id;
  final String title;
  final DateTime? dueAt;
  final bool done;
  final String? customerId;
  final bool isOverdue;
  final VoidCallback onToggleDone;
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
            horizontal: DesignTokens.space3,
            vertical: DesignTokens.space2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: done,
                onChanged: (_) => onToggleDone(),
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: done ? ext.textTertiary : ext.textPrimary,
                            fontWeight: FontWeight.w600,
                            decoration: done ? TextDecoration.lineThrough : null,
                            height: 1.25,
                          ),
                    ),
                    if (dueAt != null) ...[
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        _formatDue(dueAt!, isOverdue),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: ext.accent,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ],
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
