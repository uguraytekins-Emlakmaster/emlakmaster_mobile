import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/consultant_customers_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/utils/customer_list_heat_filter.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';

/// Müşterilerim — kompakt executive başlık (Çağrılarım ile aynı dil).
class PremiumCustomersPageHeader extends StatelessWidget {
  const PremiumCustomersPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.compact = true,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tight = compact;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ConsultantCustomersTokens.horizontal,
        tight ? ConsultantCustomersTokens.topInset + 4 : DesignTokens.space3,
        ConsultantCustomersTokens.horizontal,
        tight
            ? ConsultantCustomersTokens.headerBottomGap
            : ConsultantCustomersTokens.chromeGap,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!tight)
            const Padding(
              padding: EdgeInsets.only(right: DesignTokens.space2),
              child: PremiumNavLeading(),
            ),
          BrandEmblem(
            variant: BrandEmblemVariant.mini,
            size: tight
                ? ConsultantCustomersTokens.headerEmblemSize
                : 40,
          ),
          SizedBox(width: tight ? 8 : DesignTokens.space2 + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.pageHeading(context).copyWith(
                    fontSize: tight
                        ? ConsultantCustomersTokens.headerTitleSize
                        : DesignTokens.fontSize2xl,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.05,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: tight ? 2 : 4),
                Text(
                  subtitle,
                  style: AppTypography.meta(context).copyWith(
                    color: ext.textSecondary.withValues(alpha: 0.88),
                    fontSize: tight
                        ? ConsultantCustomersTokens.headerSubtitleSize
                        : DesignTokens.fontSizeMd,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class PremiumCustomerSearchRow extends StatelessWidget {
  const PremiumCustomerSearchRow({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantCustomersTokens.horizontal,
        ConsultantCustomersTokens.chromeGap,
        ConsultantCustomersTokens.horizontal,
        ConsultantCustomersTokens.chromeGap / 2,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.75,
        padding: EdgeInsets.fromLTRB(
          ConsultantCustomersTokens.searchSurfacePaddingH,
          ConsultantCustomersTokens.searchSurfacePaddingV,
          ConsultantCustomersTokens.searchSurfacePaddingH,
          ConsultantCustomersTokens.searchSurfacePaddingV,
        ),
        child: SizedBox(
          height: ConsultantCustomersTokens.searchBarHeight,
          child: PremiumSearchBar(
            controller: controller,
            hintText: hintText,
            showMic: false,
            compact: true,
          ),
        ),
      ),
    );
  }
}

/// Sıcaklık filtresi — mevcut satır snapshot verisine göre istemci tarafı.
class PremiumCustomerHeatFilterStrip extends StatelessWidget {
  const PremiumCustomerHeatFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CustomerListHeatFilter selected;
  final ValueChanged<CustomerListHeatFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ConsultantCustomersTokens.horizontal,
        vertical: ConsultantCustomersTokens.chromeGap / 2,
      ),
      child: ConsultantDashboardExecutiveSurface(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: SizedBox(
          height: ConsultantCustomersTokens.filterStripHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: CustomerListHeatFilter.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final filter = CustomerListHeatFilter.values[i];
              return PremiumFilterChip(
                label: filter.labelTr,
                selected: selected == filter,
                onTap: () => onSelected(filter),
                dense: true,
              );
            },
          ),
        ),
      ),
    );
  }
}
