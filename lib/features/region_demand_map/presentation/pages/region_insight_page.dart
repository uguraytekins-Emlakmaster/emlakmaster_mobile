import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
/// Market Pulse bölge kartından açılan: harita + özet metrikler (finansal dashboard dili).
class RegionInsightPage extends StatelessWidget {
  const RegionInsightPage({super.key, required this.region});

  final RegionHeatmapScore region;

  Future<void> _openInMaps(BuildContext context) async {
    final q = '${region.regionName} Diyarbakır';
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harita açılamadı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppThemeExtension.of(context).background : AppThemeExtension.of(context).background;
    final textPrimary = isDark ? AppThemeExtension.of(context).textPrimary : AppThemeExtension.of(context).textPrimary;
    final textSecondary = isDark ? AppThemeExtension.of(context).textSecondary : AppThemeExtension.of(context).textSecondary;
    final pct = (region.demandScore * 100).round().clamp(0, 100);
    final range = region.budgetSegment ?? '—';
    final hint = region.propertyTypeHint;

    return Scaffold(
      backgroundColor: bg,
      appBar: emlakAppBar(
        context,
        title: Text(
          region.regionName,
          style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        ),
        backgroundColor: isDark ? AppThemeExtension.of(context).surface : AppThemeExtension.of(context).surface,
        foregroundColor: textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bölge özeti',
              style: theme.textTheme.titleMedium?.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Talep, fiyat bandı ve konum — yatırım istihbaratı',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            const SizedBox(height: DesignTokens.space4),
            _MapPreviewCard(
              regionName: region.regionName,
              onOpenMap: () => _openInMaps(context),
            ),
            const SizedBox(height: DesignTokens.space4),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Talep skoru',
                    value: '%$pct',
                    subtitle: pct >= 70 ? 'Yüksek' : pct >= 50 ? 'Orta' : 'İzlemede',
                    accent: pct >= 70 ? const Color(0xFF66BB6A) : AppThemeExtension.of(context).accent,
                  ),
                ),
                const SizedBox(width: DesignTokens.space2),
                Expanded(
                  child: _MetricTile(
                    label: 'Fiyat bandı',
                    value: range,
                    subtitle: 'Segment',
                    accent: AppThemeExtension.of(context).accent,
                  ),
                ),
              ],
            ),
            if (hint != null && hint.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.space3),
              Container(
                padding: const EdgeInsets.all(DesignTokens.space3),
                decoration: BoxDecoration(
                  color: isDark ? AppThemeExtension.of(context).card : AppThemeExtension.of(context).surfaceElevated,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(
                    color: AppThemeExtension.of(context).border.withValues(alpha: isDark ? 0.5 : 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category_outlined, color: AppThemeExtension.of(context).accent, size: 22),
                    const SizedBox(width: DesignTokens.space2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Öne çıkan tip',
                            style: TextStyle(color: textSecondary, fontSize: 11),
                          ),
                          Text(
                            hint,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.space6),
            Text(
              'Not: Harita Google Haritalar’da açılır; bölge merkezine göre arama yapılır.',
              style: TextStyle(color: textSecondary, fontSize: 11, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({
    required this.regionName,
    required this.onOpenMap,
  });

  final String regionName;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenMap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Ink(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A237E).withValues(alpha: isDark ? 0.55 : 0.35),
                AppThemeExtension.of(context).card.withValues(alpha: 0.95),
                const Color(0xFF0D47A1).withValues(alpha: isDark ? 0.4 : 0.25),
              ],
            ),
            border: Border.all(color: AppThemeExtension.of(context).border.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridMapPainter(
                    lineColor: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_rounded,
                      size: 56,
                      color: AppThemeExtension.of(context).accent.withValues(alpha: 0.95),
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        regionName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppThemeExtension.of(context).textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space3),
                    FilledButton.icon(
                      onPressed: onOpenMap,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Haritada aç'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppThemeExtension.of(context).accent,
                        foregroundColor: AppThemeExtension.of(context).onBrand,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridMapPainter extends CustomPainter {
  _GridMapPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const step = 24.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridMapPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppThemeExtension.of(context).textPrimary : AppThemeExtension.of(context).textPrimary;
    final textSecondary = isDark ? AppThemeExtension.of(context).textSecondary : AppThemeExtension.of(context).textSecondary;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space3),
      decoration: BoxDecoration(
        color: isDark ? AppThemeExtension.of(context).card : AppThemeExtension.of(context).surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppThemeExtension.of(context).border.withValues(alpha: isDark ? 0.45 : 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: textSecondary, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: textPrimary.withValues(alpha: 0.75), fontSize: 10)),
        ],
      ),
    );
  }
}
