import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
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
    final temperatureLevel = ref.watch(leadTemperatureLevelProvider(customer));
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
            color: isSelected ? DesignTokens.primary.withOpacity(0.08) : DesignTokens.surfaceDark.withOpacity(0.6),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
              color: isSelected ? DesignTokens.primary.withOpacity(0.5) : DesignTokens.borderDark.withOpacity(0.5),
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
                        activeColor: DesignTokens.primary,
                        fillColor: WidgetStateProperty.resolveWith((_) =>
                            isSelected ? DesignTokens.primary : Colors.transparent),
                      ),
                    ),
                  CircleAvatar(
                    backgroundColor: DesignTokens.primary.withOpacity(0.2),
                    radius: 24,
                    child: Text(
                      _avatarLetter(customer.fullName),
                      style: const TextStyle(
                        color: DesignTokens.primary,
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
                          style: const TextStyle(
                            color: DesignTokens.textPrimaryDark,
                            fontWeight: FontWeight.w600,
                            fontSize: DesignTokens.fontSizeMd,
                          ),
                        ),
                        if (customer.primaryPhone != null)
                          Text(
                            customer.primaryPhone!,
                            style: const TextStyle(
                              color: DesignTokens.textSecondaryDark,
                              fontSize: DesignTokens.fontSizeSm,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (customer.leadTemperature != null)
                    _TemperatureChip(value: customer.leadTemperature!)
                  else
                    _LeadLevelChip(level: temperatureLevel),
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
                          style: const TextStyle(
                            color: DesignTokens.textTertiaryDark,
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
    Color color = DesignTokens.textTertiaryDark;
    if (value >= 0.7) {
      color = DesignTokens.success;
    } else if (value >= 0.4) {
      color = DesignTokens.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
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
    Color color = DesignTokens.textTertiaryDark;
    if (type == 1) {
      color = DesignTokens.success;
    } else if (type == 2) {
      color = DesignTokens.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Text(
        LastContactLabel.label(lastAt),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _LeadLevelChip extends StatelessWidget {
  const _LeadLevelChip({required this.level});

  final LeadTemperatureLevel level;

  @override
  Widget build(BuildContext context) {
    Color color = DesignTokens.textTertiaryDark;
    switch (level) {
      case LeadTemperatureLevel.urgent:
        color = DesignTokens.danger;
        break;
      case LeadTemperatureLevel.hot:
        color = DesignTokens.success;
        break;
      case LeadTemperatureLevel.warm:
        color = DesignTokens.warning;
        break;
      case LeadTemperatureLevel.reactivationCandidate:
        color = DesignTokens.info;
        break;
      default:
        color = DesignTokens.textTertiaryDark;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Text(
        level.label,
        style: TextStyle(color: color, fontSize: DesignTokens.fontSizeXs, fontWeight: FontWeight.w600),
      ),
    );
  }
}
