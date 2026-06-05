import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/consultant_customers_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_types.dart';
import 'package:flutter/material.dart';

Color customerToneColor(AppThemeExtension ext, CustomerTone tone) {
  return switch (tone) {
    CustomerTone.hot => ext.danger,
    CustomerTone.warm => ext.warning,
    CustomerTone.cool => ext.info,
    CustomerTone.cold => ext.textTertiary,
    CustomerTone.attention => ext.warning,
    CustomerTone.partial => ext.textTertiary,
    CustomerTone.fresh => ext.success,
    CustomerTone.neutral => ext.textTertiary,
  };
}

/// Executive müşteri başlığı — amblem + başlık + altyazı + dürüstlük notu.
class CustomerWorkspaceHeader extends StatelessWidget {
  const CustomerWorkspaceHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.coverageNote,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final String? coverageNote;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantCustomersTokens.horizontal,
        ConsultantCustomersTokens.topInset + 4,
        ConsultantCustomersTokens.horizontal,
        ConsultantCustomersTokens.headerBottomGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandEmblem(
                variant: BrandEmblemVariant.mini,
                size: ConsultantCustomersTokens.headerEmblemSize,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontSize: ConsultantCustomersTokens.headerTitleSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textSecondary.withValues(alpha: 0.88),
                        fontSize: ConsultantCustomersTokens.headerSubtitleSize,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
          if (coverageNote != null && coverageNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _HonestyNote(message: coverageNote!),
          ],
        ],
      ),
    );
  }
}

class _HonestyNote extends StatelessWidget {
  const _HonestyNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: ext.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.border.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: ext.textTertiary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: ext.textSecondary,
                fontSize: 10.5,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Müşteri özet şeridi — yalnızca gerçek sayımlar.
class CustomerWorkspaceSummaryStrip extends StatelessWidget {
  const CustomerWorkspaceSummaryStrip({super.key, required this.summary});

  final CustomerWorkspaceSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final cells = <(String, String, Color)>[
      ('${summary.active}', 'Aktif', ext.accent),
      ('${summary.hot}', 'Sıcak', ext.danger),
      ('${summary.needsContact}', 'Temas', ext.warning),
      ('${summary.partial}', 'Kısmi', ext.textTertiary),
      ('${summary.today}', 'Bugün', ext.success),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantCustomersTokens.horizontal,
        ConsultantCustomersTokens.chromeGap / 2,
        ConsultantCustomersTokens.horizontal,
        ConsultantCustomersTokens.chromeGap,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.surface.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ext.border.withValues(alpha: 0.32)),
        ),
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 26,
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
                          fontSize: 14,
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

/// Yatay filtre şeridi — CustomerWorkspaceFilter (390/430 güvenli, kaydırmalı).
class CustomerWorkspaceFilterStrip extends StatelessWidget {
  const CustomerWorkspaceFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CustomerWorkspaceFilter selected;
  final ValueChanged<CustomerWorkspaceFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: ConsultantCustomersTokens.horizontal,
        ),
        itemCount: CustomerWorkspaceFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final filter = CustomerWorkspaceFilter.values[index];
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

/// Bölüm başlığı (section rhythm).
class CustomerWorkspaceSectionHeader extends StatelessWidget {
  const CustomerWorkspaceSectionHeader({
    super.key,
    required this.label,
    this.secondary,
  });

  final String label;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantCustomersTokens.horizontal,
        ConsultantCustomersTokens.chromeGap,
        ConsultantCustomersTokens.horizontal,
        ConsultantCustomersTokens.chromeGap,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ext.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (secondary != null)
            Text(
              secondary!,
              style: TextStyle(
                color: ext.textTertiary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/// Bölüm içi dürüst boş / kapsam notu kutusu.
class CustomerWorkspaceInlineNote extends StatelessWidget {
  const CustomerWorkspaceInlineNote({
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
        ConsultantCustomersTokens.horizontal,
        0,
        ConsultantCustomersTokens.horizontal,
        ConsultantCustomersTokens.chromeGap,
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
