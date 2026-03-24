import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'dart:typed_data';

import 'package:emlakmaster_mobile/features/analytics/domain/models/rainbow_intel_models.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
/// Koyu tema önizleme + PDF aksiyonları.
Future<void> showIntelReportPreviewSheet({
  required BuildContext context,
  required RainbowIntelReport report,
  required Uint8List pdfBytes,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0D1117),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Önizleme',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: PdfPreview(
                      build: (format) async => pdfBytes,
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                      canDebug: false,
                      maxPageWidth: MediaQuery.of(context).size.width - 32,
                      pdfFileName: 'rainbow_intel_${report.id}.pdf',
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: () async {
                            await Printing.sharePdf(
                              bytes: pdfBytes,
                              filename: 'rainbow_intel_${report.id}.pdf',
                            );
                          },
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('PDF indir / paylaş'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppThemeExtension.of(context).accent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final t =
                                'Rainbow Investment Intelligence — ${report.propertyTitle}. Skor: ${report.rainbowScore.toStringAsFixed(0)}/100. ${report.listingUrl}';
                            final uri = Uri.parse(
                              'https://wa.me/?text=${Uri.encodeComponent(t)}',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: Icon(Icons.chat_rounded, color: AppThemeExtension.of(context).accent),
                          label: const Text('WhatsApp ile gönder'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppThemeExtension.of(context).accent,
                            side: BorderSide(color: AppThemeExtension.of(context).accent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
