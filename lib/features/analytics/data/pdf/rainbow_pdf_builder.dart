import 'dart:math' as math;
import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:emlakmaster_mobile/core/branding/brand_assets.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/models/rainbow_intel_models.dart';

/// Rainbow Analytics Center — ücretsiz [pdf] motoru (HTML/React Native yok).
/// Siyah–altın, kurumsal düzen, canlı rapor verisi, QR, filigran.
abstract final class RainbowPdfBuilder {
  RainbowPdfBuilder._();

  static PdfColor get _gold => PdfColor.fromHex('#C9A227');
  static PdfColor get _goldMuted => PdfColor.fromHex('#BFA071');
  static PdfColor get _ink => PdfColors.black;

  static const String _legalDisclaimer =
      'Bu belge Rainbow Analytics Center tarafından otomatik üretilmiştir; '
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

    pw.MemoryImage? emblemPdf;
    try {
      final data = await rootBundle.load(BrandAssets.emblemMasterPng);
      emblemPdf = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      emblemPdf = null;
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
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          buildBackground: (ctx) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: PdfColors.white),
          ),
        ),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        build: (ctx) => [
          pw.Stack(
            children: [
              pw.Positioned(
                left: 20,
                top: 180,
                child: pw.Transform.rotate(
                  angle: -0.35,
                  child: pw.Opacity(
                    opacity: 0.06,
                    child: pw.Text(
                      'Rainbow Analytics Center',
                      style: pw.TextStyle(
                        fontSize: 42,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                        font: bold,
                      ),
                    ),
                  ),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _headerRow(report, bold, regular, emblemPdf),
                  pw.SizedBox(height: 18),
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
                        child: _scoreRingGauge(
                          report.rainbowScore,
                          regular,
                          bold,
                        ),
                      ),
                      pw.SizedBox(width: 14),
                      pw.Expanded(
                        flex: 5,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Bileşen skorları',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: _gold,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            _rowMiniRings(
                              report,
                              regular,
                              bold,
                            ),
                            pw.SizedBox(height: 10),
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
                  pw.SizedBox(height: 22),
                  _districtSection(report, bold, regular),
                  pw.SizedBox(height: 18),
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
                    height: 150,
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
                          surfaceOpacity: 0.12,
                          data: trendData,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 22),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'İlan QR',
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
                      pw.SizedBox(width: 20),
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
                  pw.SizedBox(height: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: _goldMuted, width: 0.5),
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
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _headerRow(
    RainbowIntelReport report,
    pw.Font bold,
    pw.Font regular,
    pw.MemoryImage? emblemImage,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _gold, width: 1.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (emblemImage != null) ...[
                  pw.Image(emblemImage, width: 28, height: 28),
                  pw.SizedBox(width: 10),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Rainbow Analytics Center',
                        style: pw.TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.6,
                          color: PdfColors.grey700,
                          font: regular,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Investment Intelligence Report',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                          font: regular,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Rainbow Gayrimenkul',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _gold,
                  font: bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _fmtDate(report.generatedAt),
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                  font: regular,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _districtSection(
    RainbowIntelReport report,
    pw.Font bold,
    pw.Font regular,
  ) {
    final rows = report.districtSnapshots.isNotEmpty
        ? report.districtSnapshots
        : const [
            DistrictSnapshotRow(
              districtName: 'Kayapınar',
              demandScore: 0.82,
              budgetSegment: '4M-6M',
              propertyTypeHint: '3+1',
            ),
            DistrictSnapshotRow(
              districtName: 'Bağlar',
              demandScore: 0.65,
              budgetSegment: '2M-4M',
              propertyTypeHint: 'arsa',
            ),
          ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'İlçe analizi — karşılaştırma',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _gold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: _goldMuted, width: 0.75),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.2),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _cell('Bölge', bold, header: true),
                _cell('Talep %', bold, header: true),
                _cell('Bütçe bandı', bold, header: true),
                _cell('Segment', bold, header: true),
              ],
            ),
            for (final r in rows)
              pw.TableRow(
                children: [
                  _cell(r.districtName, regular),
                  _cell(
                    (r.demandScore * 100).toStringAsFixed(0),
                    regular,
                  ),
                  _cell(r.budgetSegment, regular),
                  _cell(r.propertyTypeHint ?? '—', regular),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _cell(
    String text,
    pw.Font font, {
    bool header = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: header ? 9 : 9,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: header ? _ink : PdfColors.grey900,
          font: font,
        ),
      ),
    );
  }

  static pw.Widget _rowMiniRings(
    RainbowIntelReport report,
    pw.Font regular,
    pw.Font bold,
  ) {
    final roi =
        (report.breakdown.roiComponent / 35.0 * 100).clamp(0.0, 100.0).toDouble();
    final dem =
        (report.breakdown.demandComponent / 35.0 * 100).clamp(0.0, 100.0).toDouble();
    final px =
        (report.breakdown.pricePerM2Component / 30.0 * 100).clamp(0.0, 100.0).toDouble();
    return pw.Row(
      children: [
        pw.Expanded(
          child: _miniRing('ROI', roi, regular, bold),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _miniRing('Talep', dem, regular, bold),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _miniRing('m²', px, regular, bold),
        ),
      ],
    );
  }

  static pw.Widget _miniRing(
    String label,
    double pct0to100,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Column(
      children: [
        pw.SizedBox(
          width: 44,
          height: 44,
          child: pw.CustomPaint(
            size: const PdfPoint(44, 44),
            painter: (PdfGraphics canvas, PdfPoint size) {
              _paintArcProgress(
                canvas,
                size,
                pct0to100,
                _gold,
                PdfColors.grey300,
                stroke: 2.5,
              );
            },
            child: pw.Center(
              child: pw.Text(
                pct0to100.toStringAsFixed(0),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _gold,
                  font: bold,
                ),
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700, font: regular),
        ),
      ],
    );
  }

  static pw.Widget _scoreRingGauge(
    double score,
    pw.Font regular,
    pw.Font bold,
  ) {
    final s = score.clamp(0.0, 100.0).toDouble();
    return pw.SizedBox(
      height: 150,
      width: 140,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.CustomPaint(
            size: const PdfPoint(140, 140),
            painter: (PdfGraphics canvas, PdfPoint size) {
              _paintArcProgress(
                canvas,
                size,
                s,
                _gold,
                PdfColors.grey300,
                stroke: 3.5,
              );
            },
          ),
          pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'Investment Score',
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
                  fontSize: 34,
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

  /// İnce dairesel ilerleme (çokgen yaklaşımı — PDF’de ücretsiz, vektörel).
  static void _paintArcProgress(
    PdfGraphics canvas,
    PdfPoint size,
    double score0to100,
    PdfColor gold,
    PdfColor track,
    {required double stroke,
  }) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = math.min(size.x, size.y) / 2 - stroke / 2;
    canvas.setLineWidth(stroke);
    canvas.setStrokeColor(track);
    canvas.setLineCap(PdfLineCap.round);
    canvas.drawEllipse(cx, cy, r, r);
    canvas.strokePath(close: true);

    final sweep = 2 * math.pi * (score0to100.clamp(0, 100) / 100.0);
    if (sweep <= 0) return;

    canvas.setStrokeColor(gold);
    canvas.setLineWidth(stroke);
    canvas.setLineCap(PdfLineCap.round);
    const start = -math.pi / 2;
    const segments = 64;
    for (var i = 0; i <= segments; i++) {
      final t = start + sweep * i / segments;
      final x = cx + r * math.cos(t);
      final y = cy + r * math.sin(t);
      if (i == 0) {
        canvas.moveTo(x, y);
      } else {
        canvas.lineTo(x, y);
      }
    }
    canvas.strokePath();
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
}
