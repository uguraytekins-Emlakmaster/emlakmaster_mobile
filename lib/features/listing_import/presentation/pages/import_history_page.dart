import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/listing_import/presentation/providers/listing_import_providers.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// İçe aktarma geçmişi — `listing_import_tasks` (processing / completed / failed).
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
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e', style: TextStyle(color: ext.foreground))),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        'Henüz içe aktarma yok.',
                        style: TextStyle(color: ext.foreground.withValues(alpha: 0.8)),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final t = tasks[i];
                      return Card(
                        color: ext.card,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _StatusChip(status: t.status),
                                  const SizedBox(width: 8),
                                  Text(
                                    t.sourceType,
                                    style: TextStyle(color: ext.foreground.withValues(alpha: 0.7), fontSize: 12),
                                  ),
                                  if (t.platform != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      t.platform!,
                                      style: TextStyle(color: ext.foreground.withValues(alpha: 0.7), fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                              if (t.sourceUrl != null && t.sourceUrl!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  t.sourceUrl!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: ext.foreground, fontSize: 13),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                'İçe aktarılan: ${t.countsImported} · Çift: ${t.countsDuplicates} · Hata: ${t.countsErrors}',
                                style: TextStyle(color: ext.foreground.withValues(alpha: 0.85), fontSize: 12),
                              ),
                              if (t.errorCode != null && t.errorCode!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    t.errorMessage ?? t.errorCode!,
                                    style: TextStyle(color: Colors.orangeAccent.shade100, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (status) {
      case 'completed':
        bg = Colors.green.shade800;
        break;
      case 'failed':
        bg = Colors.red.shade900;
        break;
      case 'processing':
      case 'queued':
        bg = Colors.blueGrey.shade800;
        break;
      case 'partial':
        bg = Colors.amber.shade900;
        break;
      case 'pending_approval':
        bg = Colors.purple.shade900;
        break;
      default:
        bg = Colors.grey.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
