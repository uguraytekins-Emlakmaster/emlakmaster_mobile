import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/revenue_customer_row_badges.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/revenue_ui_formatters.dart';
import 'package:flutter/material.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../features/contact_save/presentation/widgets/save_contact_sheet.dart';
import '../../../../core/utils/last_contact_label.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';

import '../../../../shared/models/customer_models.dart';

String _avatarLetter(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return '?';
  return fullName.trim().substring(0, 1).toUpperCase();
}

/// Müşteri kartı — liste satırı [CustomerListRowSnapshot] ile beslenir (provider yok).
class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    required this.row,
    this.onTap,
    this.selectionMode = false,
    this.isSelected = false,
  });

  final CustomerEntity customer;
  final CustomerListRowSnapshot row;
  final VoidCallback? onTap;
  final bool selectionMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final crmHeat = row.crmHeat;
    final revenueSignal = row.revenueSignal;
    final syncDelayedRisk = row.syncDelayedRisk;
    final brokerAlert = row.showBrokerAlert;
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);

    return Semantics(
      label: '${customer.fullName} müşteri kartı',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space4),
            decoration: BoxDecoration(
              color: isSelected
                  ? premium.champagneGold.withValues(alpha: 0.1)
                  : premium.glassSurface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              border: Border.all(
                color: isSelected
                    ? premium.champagneGold.withValues(alpha: 0.55)
                    : premium.glassBorder.withValues(alpha: 0.32),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (selectionMode)
                      Padding(
                        padding:
                            const EdgeInsets.only(right: DesignTokens.space3),
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => onTap?.call(),
                          activeColor: premium.champagneGold,
                          fillColor: WidgetStateProperty.resolveWith((_) =>
                              isSelected
                                  ? premium.champagneGold
                                  : Colors.transparent),
                        ),
                      ),
                    CircleAvatar(
                      backgroundColor: premium.champagneGold.withValues(alpha: 0.18),
                      radius: 24,
                      child: Text(
                        _avatarLetter(customer.fullName),
                        style: TextStyle(
                          color: premium.champagneGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.fullName ?? 'İsimsiz',
                            style: AppTypography.cardHeading(context)
                                .copyWith(fontSize: DesignTokens.fontSizeMd),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (customer.primaryPhone != null)
                            Text(
                              customer.primaryPhone!,
                              style: AppTypography.meta(context).copyWith(
                                color:
                                    AppThemeExtension.of(context).textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (revenueSignal != null)
                      RevenueBandScoreChip(signal: revenueSignal)
                    else if (customer.leadTemperature != null)
                      _TemperatureChip(value: customer.leadTemperature!)
                    else
                      _CrmHeatChip(heat: crmHeat),
                    if (brokerAlert)
                      Padding(
                        padding: const EdgeInsets.only(left: DesignTokens.space2),
                        child: Tooltip(
                          message: 'Operasyon uyarısı',
                          child: Icon(
                            Icons.notifications_active_rounded,
                            size: DesignTokens.iconSm,
                            color: AppThemeExtension.of(context).danger,
                          ),
                        ),
                      ),
                    if (syncDelayedRisk)
                      Padding(
                        padding: const EdgeInsets.only(left: DesignTokens.space2),
                        child: Tooltip(
                          message: 'Veri senkronu gecikmiş olabilir',
                          child: Icon(
                            Icons.cloud_off_outlined,
                            size: DesignTokens.iconSm,
                            color: AppThemeExtension.of(context)
                                .warning
                                .withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    if (!selectionMode)
                      IconButton(
                        tooltip: 'Rehbere kaydet',
                        constraints:
                            const BoxConstraints(minWidth: 44, minHeight: 44),
                        padding: const EdgeInsets.all(10),
                        icon: const Icon(
                          Icons.contact_phone_outlined,
                          size: DesignTokens.iconMd,
                        ),
                        color: AppThemeExtension.of(context).textSecondary,
                        onPressed: () {
                          AppFeedback.lightImpact();
                          showSaveContactSheet(
                            context,
                            initialName: customer.fullName,
                            initialPhone: customer.primaryPhone,
                            initialEmail: customer.email,
                          );
                        },
                      ),
                  ],
                ),
                if (customer.lastInteractionAt != null ||
                    customer.nextSuggestedAction != null ||
                    (revenueSignal != null &&
                        !revenueSignal.recommendationSuppressed)) ...[
                  const SizedBox(height: DesignTokens.space2),
                  Row(
                    children: [
                      if (customer.lastInteractionAt != null) ...[
                        _LastContactChip(lastAt: customer.lastInteractionAt),
                        const SizedBox(width: DesignTokens.space2),
                      ],
                      if (revenueSignal != null &&
                          !revenueSignal.recommendationSuppressed)
                        Expanded(
                          child: Text(
                            revenueNextActionLine(revenueSignal),
                            style: AppTypography.meta(context).copyWith(
                              color: AppThemeExtension.of(context).accent,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else if (customer.nextSuggestedAction != null)
                        Expanded(
                          child: Text(
                            customer.nextSuggestedAction!,
                            style: AppTypography.meta(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemperatureChip extends StatelessWidget {
  const _TemperatureChip({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    Color color = AppThemeExtension.of(context).textTertiary;
    if (value >= 0.7) {
      color = AppThemeExtension.of(context).success;
    } else if (value >= 0.4) {
      color = AppThemeExtension.of(context).warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Text(
        '${(value * 100).toInt()}%',
        style: TextStyle(
          color: color,
          fontSize: DesignTokens.fontSizeXs,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// CRM sıcaklık — detay ekranı ile aynı skor motoru.
class _CrmHeatChip extends StatelessWidget {
  const _CrmHeatChip({required this.heat});

  final CustomerHeatSnapshot heat;

  static String _emoji(CustomerHeatLevel level) {
    switch (level) {
      case CustomerHeatLevel.hot:
        return '🔥';
      case CustomerHeatLevel.warm:
        return '🟡';
      case CustomerHeatLevel.cool:
        return '🔵';
      case CustomerHeatLevel.cold:
        return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final color = switch (heat.heatLevel) {
      CustomerHeatLevel.hot => ext.warning,
      CustomerHeatLevel.warm => ext.accent,
      CustomerHeatLevel.cool => ext.textSecondary,
      CustomerHeatLevel.cold => ext.textTertiary,
    };
    return Tooltip(
      message: heat.heatReasonSummary,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_emoji(heat.heatLevel), style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              '${heat.heatScore}',
              style: TextStyle(
                color: color,
                fontSize: DesignTokens.fontSizeXs,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastContactChip extends StatelessWidget {
  const _LastContactChip({required this.lastAt});

  final DateTime? lastAt;

  @override
  Widget build(BuildContext context) {
    final type = LastContactLabel.colorType(lastAt);
    Color color = AppThemeExtension.of(context).textTertiary;
    if (type == 1) {
      color = AppThemeExtension.of(context).success;
    } else if (type == 2) {
      color = AppThemeExtension.of(context).warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Text(
        LastContactLabel.label(lastAt),
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Sıcaklık skoru + emoji: 🔥92 satın almaya çok yakın, 🟡55 araştırıyor, 🔵20 sadece bakıyor.
