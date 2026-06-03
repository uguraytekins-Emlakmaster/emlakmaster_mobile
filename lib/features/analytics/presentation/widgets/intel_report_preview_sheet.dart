import 'dart:typed_data';

import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/analytics/domain/models/rainbow_intel_models.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

/// Koyu tema önizleme + PDF aksiyonları.
Future<void> showIntelReportPreviewSheet({
  required BuildContext context,
  required RainbowIntelReport report,
  required Uint8List pdfBytes,
}) {
  return showPremiumDraggableBottomSheet<void>(
    context: context,
    initialChildSize: 0.92,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    builder: (context, _) {
      final sheetExt = AppThemeExtension.of(context);
      return Column(
        children: [
          const PremiumBottomSheetHandle(),
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
                      backgroundColor: sheetExt.accent,
                      foregroundColor: sheetExt.onBrand,
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
                          'Portivo CRM Yatırım İçgörüsü — ${report.propertyTitle}. Puan: ${report.rainbowScore.toStringAsFixed(0)}/100. ${report.listingUrl}';
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
                      color: sheetExt.accent,
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
      );
    },
  );
}
