import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/client_portal_tokens.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/utils/client_portal_filter.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:flutter/material.dart';

class PremiumClientPortalHeader extends StatelessWidget {
  const PremiumClientPortalHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalTokens.horizontal,
        ClientPortalTokens.topInset,
        ClientPortalTokens.horizontal,
        ClientPortalTokens.headerBottomGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ext.surfaceElevated.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ext.accent.withValues(alpha: 0.22)),
                ),
                child: const BrandEmblem(
                  variant: BrandEmblemVariant.mini,
                  size: ClientPortalTokens.headerEmblemSize,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.pageHeading(context).copyWith(
                        fontSize: ClientPortalTokens.headerTitleSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.35,
                        height: 1.04,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTypography.meta(context).copyWith(
                        color: ext.textSecondary.withValues(alpha: 0.92),
                        fontSize: ClientPortalTokens.headerSubtitleSize,
                        fontWeight: FontWeight.w600,
                        height: 1.18,
                      ),
                    ),
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...actions,
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: ext.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ext.info.withValues(alpha: 0.28)),
            ),
            child: Text(
              'Doğrulama notu: önizleme portföy gösterilir; favori, mesaj ve randevu durumları gerçek backend ile eşleşir.',
              style: TextStyle(
                color: ext.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumClientSummaryStrip extends StatelessWidget {
  const PremiumClientSummaryStrip({super.key, required this.summary});

  final ClientPortalSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final cells = <(String, String, Color)>[
      (summary.favoriteCount.toString(), 'Favori', ext.accent),
      (summary.portfolioPreviewCount.toString(), 'Önizleme', ext.info),
      (
        summary.messageState == ClientPortalMessageState.preview ? '—' : '0',
        'Mesaj',
        ext.warning,
      ),
      (
        summary.appointmentState == ClientPortalAppointmentState.preview
            ? 'Yakında'
            : '0',
        'Randevu',
        ext.textSecondary,
      ),
      (
        summary.profileReady ? 'Hazır' : '—',
        'Profil',
        summary.profileReady ? ext.success : ext.textTertiary,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalTokens.horizontal,
        ClientPortalTokens.chromeGap / 2,
        ClientPortalTokens.horizontal,
        ClientPortalTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.68,
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

class PremiumClientPortalSearchRow extends StatelessWidget {
  const PremiumClientPortalSearchRow({
    super.key,
    required this.controller,
    this.hintText = 'Konum, oda sayısı veya bütçe ara',
  });

  final TextEditingController controller;
  final String hintText;

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
      child: SizedBox(
        height: ClientPortalTokens.searchBarHeight,
        child: TextField(
          controller: controller,
          style: TextStyle(color: ext.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: ext.textTertiary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: ext.textSecondary, size: 20),
            filled: true,
            fillColor: ext.surface.withValues(alpha: 0.55),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ext.border.withValues(alpha: 0.35)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ext.border.withValues(alpha: 0.35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ext.accent.withValues(alpha: 0.55)),
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumClientPortalFilterStrip extends StatelessWidget {
  const PremiumClientPortalFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ClientPortalFilter selected;
  final ValueChanged<ClientPortalFilter> onSelected;

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
        itemCount: ClientPortalFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final filter = ClientPortalFilter.values[index];
          final isSelected = filter == selected;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(filter),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

class PremiumClientSectionLabel extends StatelessWidget {
  const PremiumClientSectionLabel({super.key, required this.label, this.secondary});

  final String label;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalTokens.horizontal,
        ClientPortalTokens.sectionGap,
        ClientPortalTokens.horizontal,
        ClientPortalTokens.chromeGap,
      ),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.55,
            ),
          ),
          if (secondary != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                secondary!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.meta(context).copyWith(
                  color: ext.textTertiary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
