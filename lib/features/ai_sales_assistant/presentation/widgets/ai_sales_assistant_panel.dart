import 'dart:ui';

import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/features/lead_temperature_engine/presentation/providers/lead_temperature_provider.dart';
import 'package:emlakmaster_mobile/features/smart_matching_engine/presentation/providers/portfolio_match_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Çağrı ekranında gösterilen AI Satış Asistanı paneli.
/// "Bu müşteri %78 satın alma ihtimali taşıyor" + bütçe, son ilan, uygun portföy, önerilen cümle.
class AiSalesAssistantPanel extends ConsumerWidget {
  const AiSalesAssistantPanel({super.key, required this.customerId});

  final String? customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (customerId == null || customerId!.isEmpty) {
      return _GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AI Satış Asistanı',
              style: _titleStyle(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Müşteri seçildiğinde satın alma ihtimali ve öneriler burada görünür.',
              style: _bodyStyle(context),
            ),
          ],
        ),
      );
    }

    final customerAsync = ref.watch(customerEntityByIdProvider(customerId!));
    return customerAsync.when(
      data: (customer) {
        if (customer == null) {
          return _GlassPanel(
            child: Text('Müşteri yükleniyor...', style: _bodyStyle(context)),
          );
        }
        final temperature = ref.watch(leadTemperatureForCustomerProvider(customer));
        final matchedAsync = ref.watch(topMatchedListingsForCustomerProvider(customerId!));
        final purchaseProbability = temperature.score.round().clamp(0, 100);
        final budgetText = _budgetText(customer);
        final lastViewedText = customer.nextSuggestedAction ?? '—';
        final suggestedSentence = _suggestedSentence(customer);

        return _GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('AI Satış Asistanı', style: _titleStyle(context)),
                  const Spacer(),
                  _ProbabilityChip(probability: purchaseProbability),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Bu müşteri %$purchaseProbability satın alma ihtimali taşıyor.',
                style: _bodyStyle(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _InfoChip(label: 'Bütçe analizi', value: budgetText),
              const SizedBox(height: 8),
              _InfoChip(label: 'Son görüntülenen / not', value: lastViewedText),
              matchedAsync.when(
                data: (list) {
                  if (list.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'En uygun portföy (${list.length} ilan)',
                        style: _labelStyle(context),
                      ),
                      const SizedBox(height: 4),
                      ...list.take(3).map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${e.title} — %${e.score.round()} uyum',
                              style: _bodyStyle(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              if (suggestedSentence.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF00FF41).withOpacity(0.12),
                    border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: Color(0xFF00FF41), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Önerilen cümle: $suggestedSentence',
                          style: _bodyStyle(context).copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => _GlassPanel(
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00FF41)),
            ),
            const SizedBox(width: 12),
            Text('Müşteri verisi yükleniyor...', style: _bodyStyle(context)),
          ],
        ),
      ),
      error: (e, _) => _GlassPanel(
        child: Text('Veri alınamadı: $e', style: _bodyStyle(context)),
      ),
    );
  }

  static String _budgetText(dynamic customer) {
    final min = customer.budgetMin;
    final max = customer.budgetMax;
    if (min != null && max != null) return '${(min / 1e6).toStringAsFixed(1)}M - ${(max / 1e6).toStringAsFixed(1)}M TL';
    if (min != null) return 'Min ${(min / 1e6).toStringAsFixed(1)}M TL';
    if (max != null) return 'Max ${(max / 1e6).toStringAsFixed(1)}M TL';
    return 'Belirtilmemiş';
  }

  static String _suggestedSentence(dynamic customer) {
    final regions = customer.regionPreferences;
    final regionStr = regions.isNotEmpty ? regions.take(2).join(', ') : 'bölge';
    return 'Müşteri $regionStr bölgesinde; bütçe ${_budgetText(customer)}. Uygun ilanları öner.';
  }

  static TextStyle _titleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        );
  }

  static TextStyle _bodyStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Colors.white70,
          height: 1.4,
        );
  }

  static TextStyle _labelStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
          color: Colors.white60,
          letterSpacing: 0.5,
        );
  }
}

class _ProbabilityChip extends StatelessWidget {
  const _ProbabilityChip({required this.probability});
  final int probability;

  @override
  Widget build(BuildContext context) {
    Color color = DesignTokens.textTertiaryDark;
    if (probability >= 70) {
      color = DesignTokens.success;
    } else if (probability >= 40) {
      color = DesignTokens.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Text(
        '%$probability',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.06),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall!.copyWith(
              color: Colors.white60,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.bodySmall!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
