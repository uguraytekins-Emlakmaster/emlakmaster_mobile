import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.space6),
          children: [
            PremiumPageHeader(
              title: 'Yatırım İçgörü Merkezi',
              showBack: true,
              trailing: [
                TextButton.icon(
                  onPressed: () =>
                      context.push(AppRouter.routeRainbowIntelHistory),
                  icon: Icon(Icons.history_rounded, color: ext.accent, size: 20),
                  label: Text('Geçmiş', style: TextStyle(color: ext.accent)),
                ),
              ],
            ),
            PremiumInfoBanner(
              message: widget.prefillListingId != null
                  ? 'İlan için analiz hazırlanıyor veya aşağıdan manuel devam edin.'
                  : 'İlan seçili değil — manuel veri ile off-market senaryosu oluşturabilirsiniz.',
            ),
            const SizedBox(height: DesignTokens.space6),
            PremiumSurfaceCard(
              goldBorder: true,
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
                  IgnorePointer(
                    ignoring: _busy,
                    child: Opacity(
                      opacity: _busy ? 0.55 : 1,
                      child: PremiumCtaButton(
                        label: 'İçgörü raporu oluştur',
                        icon: Icons.insights_rounded,
                        onPressed: _runCustom,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space6),
            Row(
              children: [
                Expanded(
                  child: PremiumSurfaceCard(
                    padding: const EdgeInsets.all(DesignTokens.space4),
                    child: Column(
                      children: [
                        Icon(Icons.verified_rounded, color: ext.accent),
                        const SizedBox(height: 8),
                        Text('Doğru veri',
                            style: TextStyle(
                                color: ext.textPrimary,
                                fontWeight: FontWeight.w700)),
                        Text('Kaynak doğrulama',
                            style: TextStyle(
                                color: ext.textTertiary, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PremiumSurfaceCard(
                    padding: const EdgeInsets.all(DesignTokens.space4),
                    child: Column(
                      children: [
                        Icon(Icons.analytics_outlined, color: ext.accent),
                        const SizedBox(height: 8),
                        Text('Doğru analiz',
                            style: TextStyle(
                                color: ext.textPrimary,
                                fontWeight: FontWeight.w700)),
                        Text('Rainbow motoru',
                            style: TextStyle(
                                color: ext.textTertiary, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PremiumSurfaceCard(
                    padding: const EdgeInsets.all(DesignTokens.space4),
                    child: Column(
                      children: [
                        Icon(Icons.lock_outline_rounded, color: ext.accent),
                        const SizedBox(height: 8),
                        Text('Güvenli & gizli',
                            style: TextStyle(
                                color: ext.textPrimary,
                                fontWeight: FontWeight.w700)),
                        Text('Ofis içi rapor',
                            style: TextStyle(
                                color: ext.textTertiary, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          hintStyle: TextStyle(color: ext.textPassive),
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
