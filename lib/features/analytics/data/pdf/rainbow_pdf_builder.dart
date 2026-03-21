import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/models/rainbow_intel_models.dart';

/// Yazdırma: beyaz zemin, yüksek kontrast. Önizleme ekranı ayrıca koyu tema ile sarılır.
abstract final class RainbowPdfBuilder {
  RainbowPdfBuilder._();

  static PdfColor get _gold => PdfColor.fromHex('#BFA071');

  static PdfColor get _ink => PdfColors.black;

  static const String _legalDisclaimer =
      'Bu belge Rainbow Gayrimenkul Yatırım İstihbaratı modülü tarafından otomatik üretilmiştir; '
      'yatırım tavsiyesi değildir. Veriler tahmini ve piyasa koşullarına göre değişebilir. '
      'Hukuki ve mali kararlar için uzman görüşü alınız.';

  static Future<Uint8List> buildPrintPdf(RainbowIntelReport report) async {
    pw.Font regular;
    pw.Font bold;
    try {
      regular = await PdfGoogleFonts.montserratRegular();
      bold = await PdfGoogleFonts.montserratBold();
    } catch (_) {
      regular = pw.Font.helvetica();
      bold = pw.Font.helveticaBold();
    }

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    final qr = Barcode.qrCode();
    final trendData = report.priceTrend12mTryPerM2.asMap().entries.map((e) {
      return pw.PointChartValue(e.key.toDouble(), e.value);
    }).toList();

    final minY = trendData.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = trendData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.1 + 1;
    final yVals = <double>[
      minY - pad,
      minY + (maxY - minY) * 0.25,
      minY + (maxY - minY) * 0.5,
      minY + (maxY - minY) * 0.75,
      maxY + pad,
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: _gold, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Rainbow Investment Intelligence',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: _gold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Rainbow Gayrimenkul',
                      style: pw.TextStyle(fontSize: 11, color: _ink),
                    ),
                  ],
                ),
                pw.Text(
                  _fmtDate(report.generatedAt),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            report.propertyTitle,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Konum: ${report.district}  |  m²: ${report.m2.toStringAsFixed(0)}  |  '
            'Liste: ${report.listingPriceTry.toStringAsFixed(0)} ₺',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 4,
                child: _gaugeDial(report.rainbowScore, regular, bold),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                flex: 5,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Skor bileşenleri',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _gold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    _metric(
                      'Getiri / amortisman',
                      report.breakdown.roiComponent,
                    ),
                    _metric(
                      'İlçe talep endeksi',
                      report.breakdown.demandComponent,
                    ),
                    _metric(
                      'm² fiyatı (mahalle)',
                      report.breakdown.pricePerM2Component,
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Tahmini amortisman: ${report.breakdown.amortizationYears.toStringAsFixed(1)} yıl',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            '12 Aylık m² Fiyat Eğilimi (tahminsel)',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _gold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.SizedBox(
            height: 160,
            child: pw.Chart(
              grid: pw.CartesianGrid(
                xAxis: pw.FixedAxis.fromStrings(
                  List<String>.generate(12, (i) => 'M${i + 1}'),
                ),
                yAxis: pw.FixedAxis<double>(yVals),
              ),
              datasets: [
                pw.LineDataSet(
                  legend: '₺/m²',
                  drawPoints: false,
                  isCurved: true,
                  color: _gold,
                  lineColor: _gold,
                  drawSurface: true,
                  surfaceColor: _gold,
                  surfaceOpacity: 0.15,
                  data: trendData,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 28),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Dijital ilan',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.BarcodeWidget(
                      barcode: qr,
                      data: report.listingUrl,
                      width: 88,
                      height: 88,
                      drawText: false,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      report.listingUrl,
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Dijital imza',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Uğur Aytekin',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.Text(
                      'Rainbow Gayrimenkul',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Yasal uyarı',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '$_legalDisclaimer Oluşturulma: ${_fmtDate(report.generatedAt)}',
                  style: const pw.TextStyle(fontSize: 8, lineSpacing: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static pw.Widget _metric(String label, double v) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.Text(
              v.toStringAsFixed(1),
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _gold,
              ),
            ),
          ],
        ),
      );

  /// Lüks saat kadranı — dairesel çerçeve + skor.
  static pw.Widget _gaugeDial(
    double score,
    pw.Font regular,
    pw.Font bold,
  ) {
    final s = score.clamp(0, 100);
    return pw.Container(
      height: 140,
      alignment: pw.Alignment.center,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.Container(
            width: 120,
            height: 120,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: PdfColors.grey400, width: 3),
            ),
          ),
          pw.Container(
            width: 108,
            height: 108,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: _gold, width: 4),
            ),
          ),
          pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'Rainbow Score',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                  font: regular,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                s.toStringAsFixed(0),
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                  color: _gold,
                  font: bold,
                ),
              ),
              pw.Text(
                '/ 100',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                  font: regular,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
