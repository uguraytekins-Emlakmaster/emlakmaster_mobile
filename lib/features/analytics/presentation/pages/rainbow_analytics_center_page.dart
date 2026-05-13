import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:emlakmaster_mobile/features/analytics/data/pdf/rainbow_pdf_builder.dart';
import 'package:emlakmaster_mobile/features/analytics/domain/models/rainbow_intel_models.dart';
import 'package:emlakmaster_mobile/features/analytics/presentation/providers/rainbow_intel_providers.dart';
import 'package:emlakmaster_mobile/features/analytics/presentation/widgets/analyzing_intel_overlay.dart';
import 'package:emlakmaster_mobile/features/analytics/presentation/widgets/intel_report_preview_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Komuta merkezi — analiz başlatma ve geçmişe gidiş.
class RainbowAnalyticsCenterPage extends ConsumerStatefulWidget {
  const RainbowAnalyticsCenterPage({
    super.key,
    this.prefillListingId,
  });

  final String? prefillListingId;

  @override
  ConsumerState<RainbowAnalyticsCenterPage> createState() =>
      _RainbowAnalyticsCenterPageState();
}

class _RainbowAnalyticsCenterPageState
    extends ConsumerState<RainbowAnalyticsCenterPage> {
  final _titleCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _m2Ctrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.prefillListingId != null &&
          widget.prefillListingId!.isNotEmpty) {
        _runWithListing(widget.prefillListingId!);
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _districtCtrl.dispose();
    _priceCtrl.dispose();
    _m2Ctrl.dispose();
    _rentCtrl.dispose();
    super.dispose();
  }

  String _listingUrl(String? id) {
    if (id == null || id.isEmpty) {
      return 'https://rainbowgayrimenkul.com';
    }
    return 'https://rainbowgayrimenkul.com/listing/$id';
  }

  Future<void> _runWithListing(String listingId) async {
    if (_busy) return;
    setState(() => _busy = true);
    final nav = Navigator.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => const AnalyzingIntelOverlay());
    nav.overlay?.insert(entry);

    try {
      final svc = ref.read(rainbowIntelServiceProvider);
      final payload = await svc.buildPayloadFromListing(listingId: listingId);
      final score = await svc.computeInIsolate(payload);
      final meta = await _loadListingMeta(listingId);
      final report = await svc.buildFullReport(
        payload: payload,
        score: score,
        propertyTitle: meta.$1,
        district: meta.$2,
        listingUrl: _listingUrl(listingId),
        listingId: listingId,
        imageUrl: meta.$3,
      );
      await svc.persistReport(report);
      final bytes = await RainbowPdfBuilder.buildPrintPdf(report);
      if (!mounted) return;
      entry.remove();
      setState(() => _busy = false);
      ref.invalidate(intelReportHistoryListProvider);
      await showIntelReportPreviewSheet(
        context: context,
        report: report,
        pdfBytes: bytes,
      );
    } catch (e) {
      entry.remove();
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analiz başarısız: $e')),
        );
      }
    }
  }

  Future<void> _runCustom() async {
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    final m2 = double.tryParse(_m2Ctrl.text.replaceAll(',', '.')) ?? 0;
    if (price <= 0 || m2 <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli fiyat ve m² girin.')),
      );
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    final nav = Navigator.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => const AnalyzingIntelOverlay());
    nav.overlay?.insert(entry);

    try {
      final svc = ref.read(rainbowIntelServiceProvider);
      final rent = double.tryParse(_rentCtrl.text.replaceAll(',', '.'));
      final input = CustomIntelInput(
        title: _titleCtrl.text.trim().isEmpty
            ? 'Özel portföy'
            : _titleCtrl.text.trim(),
        district: _districtCtrl.text.trim().isEmpty
            ? 'Genel'
            : _districtCtrl.text.trim(),
        priceTry: price,
        m2: m2,
        monthlyRentTry: rent != null && rent > 0 ? rent : null,
      );
      final payload = await svc.buildPayloadCustom(input);
      final score = await svc.computeInIsolate(payload);
      final report = await svc.buildFullReport(
        payload: payload,
        score: score,
        propertyTitle: input.title,
        district: input.district,
        listingUrl: _listingUrl(null),
      );
      await svc.persistReport(report);
      final bytes = await RainbowPdfBuilder.buildPrintPdf(report);
      entry.remove();
      if (!mounted) return;
      setState(() => _busy = false);
      ref.invalidate(intelReportHistoryListProvider);
      await showIntelReportPreviewSheet(
        context: context,
        report: report,
        pdfBytes: bytes,
      );
    } catch (e) {
      entry.remove();
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: ext.background,
      appBar: emlakAppBar(
        context,
        backgroundColor: ext.background,
        foregroundColor: ext.textPrimary,
        title: const Text('Yatırım İçgörü Merkezi'),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRouter.routeRainbowIntelHistory),
            child: Text(
              'Geçmiş',
              style: TextStyle(color: ext.accent),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.space6),
        children: [
          Text(
            widget.prefillListingId != null
                ? 'İlan için analiz hazırlanıyor veya aşağıdan manuel devam edin.'
                : 'İlan seçili değil — manuel veri ile off-market senaryosu oluşturabilirsiniz.',
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: DesignTokens.fontSizeSm,
              height: 1.45,
            ),
          ),
          const SizedBox(height: DesignTokens.space6),
          Container(
            padding: const EdgeInsets.all(DesignTokens.space5),
            decoration: BoxDecoration(
              color: ext.surfaceElevated,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              border: Border.all(color: ext.border.withValues(alpha: 0.58)),
              boxShadow: [
                BoxShadow(
                  color: ext.shadowColor.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manuel giriş (off-market)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: ext.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DesignTokens.space2),
                Text(
                  'Portföy bilgilerini girin; sistem aynı premium analiz akışıyla rapor üretsin.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ext.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),
                _field(context, 'Başlık', _titleCtrl, 'Örn. Nişantaşı 3+1'),
                _field(context, 'İlçe', _districtCtrl, 'Kayapınar'),
                _field(
                  context,
                  'Fiyat (₺)',
                  _priceCtrl,
                  '12500000',
                  keyboard: TextInputType.number,
                ),
                _field(
                  context,
                  'm²',
                  _m2Ctrl,
                  '145',
                  keyboard: TextInputType.number,
                ),
                _field(
                  context,
                  'Aylık kira (opsiyonel)',
                  _rentCtrl,
                  '45000',
                  keyboard: TextInputType.number,
                ),
                const SizedBox(height: DesignTokens.space4),
                FilledButton.icon(
                  onPressed: _busy ? null : _runCustom,
                  icon: const Icon(Icons.insights_rounded),
                  label: const Text('İçgörü raporu oluştur'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ext.accent,
                    foregroundColor: ext.onBrand,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    BuildContext context,
    String label,
    TextEditingController c,
    String hint, {
    TextInputType keyboard = TextInputType.text,
  }) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        style: TextStyle(color: ext.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: ext.textSecondary),
          hintStyle: TextStyle(color: ext.textTertiary),
          fillColor: ext.inputBackground,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ext.border.withValues(alpha: 0.7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ext.accent),
          ),
        ),
      ),
    );
  }
}

Future<(String, String, String?)> _loadListingMeta(String listingId) async {
  try {
    await FirestoreService.ensureInitialized();
    final doc = await FirebaseFirestore.instance
        .collection('listings')
        .doc(listingId)
        .get();
    final d = doc.data() ?? {};
    final title = d['title'] as String? ?? 'İlan';
    final district =
        d['district'] as String? ?? d['location'] as String? ?? 'Genel';
    final imageUrl = d['imageUrl'] as String?;
    return (title, district, imageUrl);
  } catch (_) {
    return ('İlan', 'Genel', null);
  }
}
