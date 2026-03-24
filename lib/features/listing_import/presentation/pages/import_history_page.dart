import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/listing_import/data/listing_import_service.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/import_source_type.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/import_task_status.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/listing_import_task_entity.dart';
import 'package:emlakmaster_mobile/features/listing_import/presentation/providers/listing_import_providers.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// İçe aktarma geçmişi — görev durumu, ilerleme, ilanlara git.
class ImportHistoryPage extends ConsumerWidget {
  const ImportHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final async = ref.watch(listingImportTasksProvider);
    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  const AppBackButton(),
                  Expanded(
                    child: Text(
                      'İçe aktarma geçmişi',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: ext.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRouter.routeMyListings),
                    child: const Text('İlanlarım'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e', style: TextStyle(color: ext.foreground))),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    final l10n = AppLocalizations.of(context);
                    return EmptyState(
                      premiumVisual: true,
                      icon: Icons.history_rounded,
                      title: l10n.t('empty_import_history_title'),
                      subtitle: l10n.t('empty_import_history_sub'),
                      actionLabel: l10n.t('empty_import_history_cta'),
                      onAction: () => context.push(AppRouter.routeImportHub),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final t = tasks[i];
                      return _TaskCard(
                        task: t,
                        ext: ext,
                        onOpenListings: () => context.push(
                          AppRouter.routeMyListings,
                          extra: <String, dynamic>{'importTaskId': t.id},
                        ),
                        onReimport: t.sourceUrl != null && t.sourceUrl!.startsWith('http')
                            ? () async {
                                final uid = ref.read(currentUserProvider).valueOrNull?.uid;
                                if (uid == null) return;
                                await ListingImportService.instance.reimportUrl(
                                  uid: uid,
                                  officeId: '',
                                  url: t.sourceUrl!,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Yeniden içe aktarma başlatıldı.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.ext,
    required this.onOpenListings,
    this.onReimport,
  });

  final ListingImportTaskEntity task;
  final AppThemeExtension ext;
  final VoidCallback onOpenListings;
  final VoidCallback? onReimport;

  @override
  Widget build(BuildContext context) {
    final p = (task.progress.clamp(0, 100)) / 100.0;
    return Material(
      color: ext.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpenListings,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusChip(status: task.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.sourceType.wireValue,
                      style: TextStyle(color: ext.foreground.withValues(alpha: 0.75), fontSize: 12),
                    ),
                  ),
                  if (task.platform != null)
                    Text(
                      task.platform!,
                      style: TextStyle(color: ext.foreground.withValues(alpha: 0.75), fontSize: 12),
                    ),
                ],
              ),
              if (task.sourceUrl != null && task.sourceUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.sourceUrl!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ext.foreground, fontSize: 13),
                ),
              ],
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: switch (task.status) {
                    ImportTaskStatus.pending => null,
                    ImportTaskStatus.processing => p,
                    ImportTaskStatus.success => 1,
                    ImportTaskStatus.failed => 1,
                  },
                  minHeight: 6,
                  backgroundColor: Colors.black26,
                  color: _progressColor(task.status),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '%${task.progress} · İçe aktarılan: ${task.countsImported} · Çift: ${task.countsDuplicates} · Hata: ${task.countsErrors}',
                style: TextStyle(color: ext.foreground.withValues(alpha: 0.85), fontSize: 12),
              ),
              if (task.errorMessage != null && task.errorMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      task.errorMessage!,
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                    ),
                  ),
                ),
              if (onReimport != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onReimport,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Yeniden içe aktar'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _progressColor(ImportTaskStatus s) {
    switch (s) {
      case ImportTaskStatus.success:
        return Colors.green.shade700;
      case ImportTaskStatus.failed:
        return Colors.red.shade700;
      case ImportTaskStatus.processing:
      case ImportTaskStatus.pending:
        return Colors.blueGrey.shade600;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final ImportTaskStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (status) {
      case ImportTaskStatus.pending:
        bg = Colors.grey.shade800;
        label = 'Bekliyor';
        break;
      case ImportTaskStatus.processing:
        bg = Colors.blueGrey.shade800;
        label = 'İşleniyor';
        break;
      case ImportTaskStatus.success:
        bg = Colors.green.shade800;
        label = 'Tamam';
        break;
      case ImportTaskStatus.failed:
        bg = Colors.red.shade900;
        label = 'Hata';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
