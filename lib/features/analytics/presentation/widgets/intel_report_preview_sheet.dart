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
  final ext = AppThemeExtension.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: ext.shadowColor.withValues(alpha: isDark ? 0.52 : 0.18),
    builder: (ctx) {
      final sheetExt = AppThemeExtension.of(ctx);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: sheetExt.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusSheet),
              ),
              border: Border(
                top: BorderSide(
                  color: sheetExt.border.withValues(alpha: 0.5),
                ),
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
                        color: sheetExt.textTertiary.withValues(alpha: 0.35),
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
                              style:
                                  AppTypography.pageHeading(context).copyWith(
                                fontSize: DesignTokens.fontSizeXl,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(
                                height: DesignTokens.titleSubtitleGap),
                            Text(
                              report.propertyTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body(context).copyWith(
                                color: sheetExt.textSecondary,
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
                          color: sheetExt.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusControl),
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
                                'EmlakMaster Yatırım İçgörüsü — ${report.propertyTitle}. Puan: ${report.rainbowScore.toStringAsFixed(0)}/100. ${report.listingUrl}';
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
                            foregroundColor: sheetExt.accent,
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(
                              color: sheetExt.border.withValues(alpha: 0.7),
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
