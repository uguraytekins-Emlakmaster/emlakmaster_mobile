import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/broker_customer_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../features/contact_save/presentation/widgets/save_contact_sheet.dart';
import '../../../../core/utils/last_contact_label.dart';
import '../../../../features/lead_temperature_engine/presentation/providers/lead_temperature_provider.dart';
import '../../../../shared/models/customer_models.dart';
import '../../../../shared/models/lead_temperature.dart';
String _avatarLetter(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return '?';
  return fullName.trim().substring(0, 1).toUpperCase();
}

/// Müşteri kartı: isim, telefon, sıcaklık (stored veya Lead Temperature Engine), son aksiyon.
class CustomerCard extends ConsumerWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    this.onTap,
    this.selectionMode = false,
    this.isSelected = false,
  });

  final CustomerEntity customer;
  final VoidCallback? onTap;
  final bool selectionMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temperatureScore = ref.watch(leadTemperatureForCustomerProvider(customer));
    final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
    final brokerAlert =
        role.isManagerTier && brokerAlertsActiveForCustomer(customer);
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
            color: isSelected ? AppThemeExtension.of(context).accent.withValues(alpha: 0.08) : AppThemeExtension.of(context).surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
              color: isSelected ? AppThemeExtension.of(context).accent.withValues(alpha: 0.5) : AppThemeExtension.of(context).border.withValues(alpha: 0.5),
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
                      padding: const EdgeInsets.only(right: DesignTokens.space3),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => onTap?.call(),
                        activeColor: AppThemeExtension.of(context).accent,
                        fillColor: WidgetStateProperty.resolveWith((_) =>
                            isSelected ? AppThemeExtension.of(context).accent : Colors.transparent),
                      ),
                    ),
                  CircleAvatar(
                    backgroundColor: AppThemeExtension.of(context).accent.withValues(alpha: 0.2),
                    radius: 24,
                    child: Text(
                      _avatarLetter(customer.fullName),
                      style: TextStyle(
                        color: AppThemeExtension.of(context).accent,
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
                          style: TextStyle(
                            color: AppThemeExtension.of(context).textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: DesignTokens.fontSizeMd,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (customer.primaryPhone != null)
                          Text(
                            customer.primaryPhone!,
                            style: TextStyle(
                              color: AppThemeExtension.of(context).textSecondary,
                              fontSize: DesignTokens.fontSizeSm,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (customer.leadTemperature != null)
                    _TemperatureChip(value: customer.leadTemperature!)
                  else
                    _LeadScoreChip(score: temperatureScore.score, level: temperatureScore.level),
                  if (brokerAlert)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Tooltip(
                        message: 'Operasyon uyarısı',
                        child: Icon(
                          Icons.notifications_active_rounded,
                          size: 18,
                          color: AppThemeExtension.of(context).danger,
                        ),
                      ),
                    ),
                  if (!selectionMode)
                    IconButton(
                      tooltip: 'Rehbere kaydet',
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      padding: const EdgeInsets.all(10),
                      icon: const Icon(Icons.contact_phone_outlined, size: 22),
                      color: AppThemeExtension.of(context).textSecondary,
                      onPressed: () {
                        HapticFeedback.lightImpact();
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
              if (customer.lastInteractionAt != null || customer.nextSuggestedAction != null) ...[
                const SizedBox(height: DesignTokens.space2),
                Row(
                  children: [
                    if (customer.lastInteractionAt != null) ...[
                      _LastContactChip(lastAt: customer.lastInteractionAt),
                      const SizedBox(width: DesignTokens.space2),
                    ],
                    if (customer.nextSuggestedAction != null)
                      Expanded(
                        child: Text(
                          customer.nextSuggestedAction!,
                          style: TextStyle(
                            color: AppThemeExtension.of(context).textTertiary,
                            fontSize: DesignTokens.fontSizeXs,
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
        style: TextStyle(color: color, fontSize: DesignTokens.fontSizeXs, fontWeight: FontWeight.w600),
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
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Sıcaklık skoru + emoji: 🔥92 satın almaya çok yakın, 🟡55 araştırıyor, 🔵20 sadece bakıyor.
class _LeadScoreChip extends StatelessWidget {
  const _LeadScoreChip({required this.score, required this.level});

  final double score;
  final LeadTemperatureLevel level;

  static String _emoji(LeadTemperatureLevel level) {
    switch (level) {
      case LeadTemperatureLevel.urgent:
      case LeadTemperatureLevel.hot:
        return '🔥';
      case LeadTemperatureLevel.warm:
      case LeadTemperatureLevel.reactivationCandidate:
        return '🟡';
      default:
        return '🔵';
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color = AppThemeExtension.of(context).textTertiary;
    switch (level) {
      case LeadTemperatureLevel.urgent:
        color = AppThemeExtension.of(context).danger;
        break;
      case LeadTemperatureLevel.hot:
        color = AppThemeExtension.of(context).success;
        break;
      case LeadTemperatureLevel.warm:
      case LeadTemperatureLevel.reactivationCandidate:
        color = AppThemeExtension.of(context).warning;
        break;
      default:
        color = AppThemeExtension.of(context).info;
    }
    final emoji = _emoji(level);
    final scoreInt = score.round().clamp(0, 100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$scoreInt',
            style: TextStyle(color: color, fontSize: DesignTokens.fontSizeXs, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
