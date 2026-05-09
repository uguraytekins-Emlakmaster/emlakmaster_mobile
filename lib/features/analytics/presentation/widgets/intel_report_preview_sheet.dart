import 'dart:typed_data';

import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
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
    barrierColor: Colors.black.withValues(alpha: 0.52),
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
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusSheet),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: DesignTokens.space3,
                    bottom: DesignTokens.space3,
                  ),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.space5,
                    DesignTokens.space2,
                    DesignTokens.space5,
                    DesignTokens.space3,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Önizleme',
                              style: AppTypography.pageHeading(context).copyWith(
                                color: Colors.white,
                                fontSize: DesignTokens.fontSizeXl,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.titleSubtitleGap),
                            Text(
                              report.propertyTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body(context).copyWith(
                                color: Colors.white.withValues(alpha: 0.62),
                                fontSize: DesignTokens.fontSizeSm,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kapat',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          size: DesignTokens.iconMd,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
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
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.space5,
                      DesignTokens.space3,
                      DesignTokens.space5,
                      DesignTokens.space5,
                    ),
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
                          icon: const Icon(
                            Icons.download_rounded,
                            size: DesignTokens.iconMd,
                          ),
                          label: const Text('PDF indir'),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                AppThemeExtension.of(context).accent,
                            foregroundColor:
                                AppThemeExtension.of(context).onBrand,
                            minimumSize: const Size(double.infinity, 48),
                            padding: const EdgeInsets.symmetric(
                              vertical: DesignTokens.space3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusControl,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space3),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final t =
                                'Rainbow Investment Intelligence — ${report.propertyTitle}. Skor: ${report.rainbowScore.toStringAsFixed(0)}/100. ${report.listingUrl}';
                            final uri = Uri.parse(
                              'https://wa.me/?text=${Uri.encodeComponent(t)}',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: Icon(
                            Icons.chat_rounded,
                            size: DesignTokens.iconMd,
                            color: AppThemeExtension.of(context).accent,
                          ),
                          label: const Text("WhatsApp'ta paylaş"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                AppThemeExtension.of(context).accent,
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusControl,
                              ),
                            ),
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
