import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/axion_agent_models.dart';
import '../providers/axion_agent_providers.dart';
import 'axion_agent_card.dart';
import 'axion_agent_honesty_note.dart';
import 'axion_agent_urgency_chip.dart';

/// Broker/Admin "Operasyon özeti" kartı — yalnızca gerçek sayımlar.
///
/// Sahte trend / tahmin yok. Veri yoksa kart hiç çizilmez (ölü UI yok).
class AxionAgentBrokerBriefCard extends ConsumerWidget {
  const AxionAgentBrokerBriefCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brief = ref.watch(axionBrokerBriefProvider).valueOrNull;
    if (brief == null) return const SizedBox.shrink();

    final t = AppThemeExtension.of(context);
    final counts = brief.realCounts;
    final stats = <({String label, int value})>[
      (label: 'Geciken görev', value: counts.overdueTasks),
      (label: 'Dönüşsüz cevapsız', value: counts.missedCallsWithoutCallback),
      (label: 'Takipsiz müşteri', value: counts.customersWithoutFollowUp),
      (label: 'Bekleyen sıcak müşteri', value: counts.hotCustomersWaiting),
      (label: 'Eksik müşteri kaydı', value: counts.incompleteCustomerRecords),
      (label: 'Bugün vadesi gelen', value: counts.tasksDueToday),
    ].where((s) => s.value > 0).toList(growable: false);

    final attention = brief.attentionAreas.take(3).toList(growable: false);
    if (stats.isEmpty && attention.isEmpty) return const SizedBox.shrink();

    return AxionAgentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 16, color: t.accent),
              const SizedBox(width: DesignTokens.space2),
              Text(
                'Operasyon özeti',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBase,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              Text(
                'Axion Agent · kural tabanlı',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXs,
                  color: t.textPassive,
                ),
              ),
            ],
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.space3),
            Wrap(
              spacing: DesignTokens.space2,
              runSpacing: DesignTokens.space2,
              children: [
                for (final s in stats) _StatChip(label: s.label, value: s.value),
              ],
            ),
          ],
          if (attention.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.space3),
            for (final a in attention) _AttentionRow(suggestion: a),
          ],
          if (brief.honestyNote != null) ...[
            const SizedBox(height: DesignTokens.space2),
            AxionAgentHonestyNote(note: brief.honestyNote!),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space3,
        vertical: DesignTokens.space2,
      ),
      decoration: BoxDecoration(
        color: t.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: t.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBase,
              fontWeight: FontWeight.w700,
              color: t.accent,
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          Text(
            label,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXs,
              color: t.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.suggestion});

  final AxionAgentSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AxionAgentUrgencyChip(urgency: suggestion.urgency),
          const SizedBox(width: DesignTokens.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSm,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
                Text(
                  suggestion.description,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXs,
                    color: t.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
