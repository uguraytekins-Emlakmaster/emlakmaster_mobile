import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/client_portal_tokens.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/client_engagement_types.dart';
import 'package:flutter/material.dart';

Color engagementToneColor(AppThemeExtension ext, EngagementTone tone) {
  return switch (tone) {
    EngagementTone.accent => ext.accent,
    EngagementTone.info => ext.info,
    EngagementTone.success => ext.success,
    EngagementTone.warning => ext.warning,
    EngagementTone.neutral => ext.textTertiary,
  };
}

/// Etkileşim özet şeridi — yalnızca gerçek değerler; uydurma KPI yok.
class ClientEngagementSummaryStrip extends StatelessWidget {
  const ClientEngagementSummaryStrip({super.key, required this.summary});

  final ClientEngagementSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final cells = <(String, String, Color)>[
      if (summary.previewPortfolio > 0)
        (summary.previewPortfolio.toString(), 'Önizleme', ext.info),
      (summary.activeChannels.toString(), 'Kanal', ext.accent),
      (summary.messageReady ? 'Hazır' : '—', 'Mesaj', ext.success),
      (summary.requestPreview ? 'Yakında' : '0', 'Talep', ext.warning),
      (
        summary.profileReady ? 'Hazır' : '—',
        'Profil',
        summary.profileReady ? ext.success : ext.textTertiary,
      ),
    ].take(5).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalTokens.horizontal,
        ClientPortalTokens.chromeGap / 2,
        ClientPortalTokens.horizontal,
        ClientPortalTokens.chromeGap,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.surface.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ext.border.withValues(alpha: 0.32)),
        ),
        child: SizedBox(
          height: ClientPortalTokens.summaryStripHeight,
          child: Row(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 28,
                    color: ext.border.withValues(alpha: 0.28),
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cells[i].$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cells[i].$3,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cells[i].$2,
                        style: TextStyle(
                          color: ext.textTertiary,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Yatay filtre şeridi — EngagementFilter (390/430 güvenli, yatay kaydırma).
class ClientEngagementFilterStrip extends StatelessWidget {
  const ClientEngagementFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final EngagementFilter selected;
  final ValueChanged<EngagementFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return SizedBox(
      height: ClientPortalTokens.filterStripHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: ClientPortalTokens.horizontal,
        ),
        itemCount: EngagementFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final filter = EngagementFilter.values[index];
          final isSelected = filter == selected;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(filter),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ext.accent.withValues(alpha: 0.16)
                      : ext.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? ext.accent.withValues(alpha: 0.45)
                        : ext.border.withValues(alpha: 0.32),
                  ),
                ),
                child: Text(
                  filter.label,
                  style: TextStyle(
                    color: isSelected ? ext.accent : ext.textSecondary,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bölüm içi dürüst boş/ kapsam notu kutusu.
class ClientEngagementInlineNote extends StatelessWidget {
  const ClientEngagementInlineNote({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalTokens.horizontal,
        0,
        ClientPortalTokens.horizontal,
        ClientPortalTokens.chromeGap,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: ext.surface.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ext.border.withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: ext.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
