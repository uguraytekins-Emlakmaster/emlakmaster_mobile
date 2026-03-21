import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/analytics/data/pdf/rainbow_pdf_builder.dart';
import 'package:emlakmaster_mobile/features/analytics/presentation/providers/rainbow_intel_providers.dart';
import 'package:emlakmaster_mobile/features/analytics/presentation/widgets/intel_report_preview_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

class IntelReportHistoryPage extends ConsumerWidget {
  const IntelReportHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(intelReportHistoryListProvider);

    return Scaffold(
      backgroundColor: DesignTokens.scaffoldDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.scaffoldDark,
        foregroundColor: Colors.white,
        title: const Text('Rapor geçmişi'),
      ),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              color: DesignTokens.antiqueGold,
              onRefresh: () async => ref.invalidate(intelReportHistoryListProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Text(
                      'Henüz kayıtlı rapor yok.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: DesignTokens.antiqueGold,
            onRefresh: () async => ref.invalidate(intelReportHistoryListProvider),
            child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(DesignTokens.space4),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = items[i];
              return Material(
                color: DesignTokens.surfaceDarkCard,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                child: InkWell(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  onTap: () async {
                    final bytes = await RainbowPdfBuilder.buildPrintPdf(r);
                    if (!context.mounted) return;
                    await showIntelReportPreviewSheet(
                      context: context,
                      report: r,
                      pdfBytes: bytes,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.space4),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: DesignTokens.antiqueGold.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            r.rainbowScore.toStringAsFixed(0),
                            style: const TextStyle(
                              color: DesignTokens.antiqueGold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.propertyTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${r.district} · ${_fmtDateTime(r.generatedAt)}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Paylaş',
                          onPressed: () async {
                            final bytes = await RainbowPdfBuilder.buildPrintPdf(r);
                            await Printing.sharePdf(
                              bytes: bytes,
                              filename: 'rainbow_intel_${r.id}.pdf',
                            );
                          },
                          icon: Icon(
                            Icons.ios_share_rounded,
                            color: DesignTokens.antiqueGold.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.antiqueGold),
        ),
        error: (e, _) => Center(
          child: Text('Yüklenemedi: $e', style: const TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }

}

String _fmtDateTime(DateTime d) =>
    '${d.day}.${d.month}.${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
