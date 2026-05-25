import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/consultant_customers_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_list_row_quick_actions.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/revenue_customer_row_badges.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/revenue_ui_formatters.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter/material.dart';
import 'package:emlakmaster_mobile/core/utils/last_contact_label.dart';

String _avatarLetter(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return '?';
  return fullName.trim().substring(0, 1).toUpperCase();
}

/// Yüksek yoğunluklu müşteri listesi satırı — provider yok.
class CustomerListPremiumTile extends StatelessWidget {
  const CustomerListPremiumTile({
    super.key,
    required this.customer,
    required this.row,
    this.onTap,
    this.onCall,
    this.onMessage,
    this.onWhatsApp,
    this.onOpenDetail,
    this.selectionMode = false,
    this.isSelected = false,
  });

  final CustomerEntity customer;
  final CustomerListRowSnapshot row;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onOpenDetail;
  final bool selectionMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final revenueSignal = row.revenueSignal;
    final syncDelayedRisk = row.syncDelayedRisk;
    final brokerAlert = row.showBrokerAlert;
    final crmHeat = row.crmHeat;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantCustomersTokens.rowPaddingH,
        ConsultantCustomersTokens.rowPaddingV,
        ConsultantCustomersTokens.rowPaddingH,
        ConsultantCustomersTokens.rowPaddingV,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectionMode) ...[
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap?.call(),
                    activeColor: premium.champagneGold,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: DesignTokens.space2),
              ],
              _Avatar(letter: _avatarLetter(customer.fullName)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.fullName ?? 'İsimsiz',
                            style: TextStyle(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: ConsultantCustomersTokens.rowTitleSize,
                              letterSpacing: -0.2,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (revenueSignal != null)
                          RevenueBandScoreChip(signal: revenueSignal)
                        else if (customer.leadTemperature != null)
                          _TemperatureChip(value: customer.leadTemperature!)
                        else
                          _CrmHeatChip(heat: crmHeat),
                        if (brokerAlert) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.notifications_active_rounded,
                            size: 16,
                            color: ext.danger,
                          ),
                        ],
                        if (syncDelayedRisk) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 16,
                            color: ext.warning.withValues(alpha: 0.9),
                          ),
                        ],
                      ],
                    ),
                    if (customer.primaryPhone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        customer.primaryPhone!,
                        style: TextStyle(
                          color: ext.textSecondary,
                          fontSize: ConsultantCustomersTokens.rowMetaSize,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (!selectionMode &&
              (onCall != null ||
                  onMessage != null ||
                  onWhatsApp != null ||
                  onOpenDetail != null)) ...[
            const SizedBox(height: 4),
            CustomerListRowQuickActions(
              onCall: onCall,
              onMessage: onMessage,
              onWhatsApp: onWhatsApp,
              onOpenDetail: onOpenDetail,
            ),
          ],
          if (customer.lastInteractionAt != null ||
              customer.nextSuggestedAction != null ||
              (revenueSignal != null &&
                  !revenueSignal.recommendationSuppressed)) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (customer.lastInteractionAt != null) ...[
                  _LastContactChip(lastAt: customer.lastInteractionAt),
                  const SizedBox(width: 6),
                ],
                if (revenueSignal != null &&
                    !revenueSignal.recommendationSuppressed)
                  Expanded(
                    child: Text(
                      revenueNextActionLine(revenueSignal),
                      style: TextStyle(
                        color: ext.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else if (customer.nextSuggestedAction != null)
                  Expanded(
                    child: Text(
                      customer.nextSuggestedAction!,
                      style: TextStyle(
                        color: ext.textTertiary,
                        fontSize: 9.5,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    final premium = PremiumThemeExtension.of(context);
    const size = ConsultantCustomersTokens.rowAvatarSize;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: premium.champagneGold.withValues(alpha: 0.14),
        border: Border.all(
          color: premium.champagneGold.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: premium.champagneGold,
          fontWeight: FontWeight.w700,
          fontSize: 13,
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
    final ext = AppThemeExtension.of(context);
    Color color = ext.textTertiary;
    if (value >= 0.7) {
      color = ext.success;
    } else if (value >= 0.4) {
      color = ext.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      ),
      child: Text(
        '${(value * 100).toInt()}%',
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _CrmHeatChip extends StatelessWidget {
  const _CrmHeatChip({required this.heat});

  final CustomerHeatSnapshot heat;

  static String _emoji(CustomerHeatLevel level) {
    return switch (level) {
      CustomerHeatLevel.hot => '🔥',
      CustomerHeatLevel.warm => '🟡',
      CustomerHeatLevel.cool => '🔵',
      CustomerHeatLevel.cold => '⚪',
    };
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_emoji(heat.heatLevel), style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 3),
            Text(
              '${heat.heatScore}',
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                height: 1,
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
    final ext = AppThemeExtension.of(context);
    final type = LastContactLabel.colorType(lastAt);
    Color color = ext.textTertiary;
    if (type == 1) {
      color = ext.success;
    } else if (type == 2) {
      color = ext.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      ),
      child: Text(
        LastContactLabel.label(lastAt),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
