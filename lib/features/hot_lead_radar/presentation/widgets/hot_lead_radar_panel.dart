import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/customer_models.dart';
import '../../../../shared/models/lead_temperature.dart';

/// Bugün aranması gereken en önemli müşteriler – skor >= hotLeadRadarMinScore (Signal vs Noise).
class HotLeadRadarPanel extends ConsumerWidget {
  const HotLeadRadarPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(displayRoleOrNullProvider);
    if (role == null || !FeaturePermission.canViewOpportunityRadar(role)) {
      return const SizedBox.shrink();
    }
    return const _HotLeadRadarBody();
  }
}

class _HotLeadRadarBody extends StatelessWidget {
  const _HotLeadRadarBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: DesignTokens.borderDark.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.whatshot_rounded, color: DesignTokens.warning, size: 22),
              const SizedBox(width: DesignTokens.space2),
              Text(
                'Hot Lead Radar',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: DesignTokens.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '≥%${(AppConstants.hotLeadRadarMinScore * 100).toInt()}',
                style: const TextStyle(color: DesignTokens.textTertiaryDark, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          const Text(
            'Yüksek bütçe + yüksek sıcaklık + eşleşen ilan müşterileri burada. Liste müşteri sayfasından beslenir.',
            style: TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Tek müşteri için hot lead skoru (0..1): bütçe netliği + sıcaklık + son temas.
double hotLeadScoreForCustomer(CustomerEntity c, LeadTemperatureScore temp) {
  var score = 0.0;
  if (c.budgetMin != null && c.budgetMax != null) {
    score += 0.25;
  } else if (c.budgetMin != null || c.budgetMax != null) {
    score += 0.15;
  }
  switch (temp.level) {
    case LeadTemperatureLevel.urgent: score += 0.4; break;
    case LeadTemperatureLevel.hot: score += 0.35; break;
    case LeadTemperatureLevel.warm: score += 0.2; break;
    default: score += 0.05;
  }
  final days = c.lastInteractionAt != null
      ? DateTime.now().difference(c.lastInteractionAt!).inDays
      : 999;
  if (days <= 3) {
    score += 0.2;
  } else if (days <= 7) {
    score += 0.1;
  }
  if (c.offersCount > 0 || c.visitsCount > 0) score += 0.15;
  return score.clamp(0.0, 1.0);
}
