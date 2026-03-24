import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
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
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.space6,
                    DesignTokens.space2,
                    DesignTokens.space6,
                    100,
                  ),
                  itemCount: docs.length,
                  cacheExtent: 300,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final d = doc.data();
                    final id = doc.id;
                    final title =
                        d['title'] as String? ?? 'Görev';
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
                );
              },
            ),
      floatingActionButton: uid.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddTaskDialog(context, ref, uid),
              backgroundColor: AppThemeExtension.of(context).accent,
              foregroundColor: Colors.black,
              child: const Icon(Icons.add_rounded, size: 28),
            ),
    );
  }

  Future<void> _toggleDone(
    String id,
    Map<String, dynamic> current,
    bool done,
  ) async {
    HapticFeedback.lightImpact();
    try {
      await FirestoreService.setTask({
        ...current,
        'id': id,
        'done': done,
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görev güncellenemedi: ${e.message ?? e.code}'),
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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppThemeExtension.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.space6,
            right: DesignTokens.space6,
            top: DesignTokens.space6,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + DesignTokens.space6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppThemeExtension.of(context).border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.space4),
              Text(
                'Yeni görev',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      color: AppThemeExtension.of(context).textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: DesignTokens.space3),
      color: AppThemeExtension.of(context).surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        side: BorderSide(
          color: isOverdue
              ? AppThemeExtension.of(context).danger.withValues(alpha: 0.5)
              : AppThemeExtension.of(context).border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: done,
                onChanged: (_) => onToggleDone(),
                activeColor: AppThemeExtension.of(context).accent,
                fillColor: WidgetStateProperty.resolveWith((_) {
                  return done ? AppThemeExtension.of(context).accent : Colors.transparent;
                }),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: done
                            ? AppThemeExtension.of(context).textTertiary
                            : AppThemeExtension.of(context).textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (dueAt != null) ...[
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        _formatDue(dueAt!, isOverdue),
                        style: TextStyle(
                          color: isOverdue
                              ? AppThemeExtension.of(context).danger
                              : AppThemeExtension.of(context).textSecondary,
                          fontSize: 13,
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
                          style: TextStyle(
                            color: AppThemeExtension.of(context).accent,
                            fontSize: 12,
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
