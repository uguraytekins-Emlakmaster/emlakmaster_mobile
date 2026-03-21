import 'package:emlakmaster_mobile/core/services/finance_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:flutter/material.dart';

class FinanceBar extends StatelessWidget {
  const FinanceBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const FinanceBarLive();
  }
}

class FinanceBarLive extends StatelessWidget {
  const FinanceBarLive({super.key});

  static String _formatChange({double? current, double? previous}) {
    if (current == null || previous == null) return '0.0';
    final diff = current - previous;
    if (diff.abs() < 0.001) return '0.0';
    final sign = diff > 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 72,
        child: StreamBuilder<FinanceRates>(
          stream: FinanceService.ratesStream,
          initialData: FinanceService.getCached(),
          builder: (context, snapshot) {
            final rates = snapshot.data;
            final prev = FinanceService.previousRates;
            final awaitingFirst =
                rates == null && snapshot.connectionState == ConnectionState.waiting;
            if (awaitingFirst) {
              return const _FinanceBarShimmer();
            }
            String fmtUsd() => (rates != null && rates.usdTry > 0)
                ? rates.usdTry.toStringAsFixed(2)
                : '—';
            String fmtEur() => (rates != null && rates.eurTry > 0)
                ? rates.eurTry.toStringAsFixed(2)
                : '—';
            final items = <_FinanceDisplayItem>[
              _FinanceDisplayItem(
                label: 'USD/TRY',
                value: fmtUsd(),
                change: _formatChange(current: rates?.usdTry, previous: prev?.usdTry),
              ),
              _FinanceDisplayItem(
                label: 'EUR/TRY',
                value: fmtEur(),
                change: _formatChange(current: rates?.eurTry, previous: prev?.eurTry),
              ),
              _FinanceDisplayItem(
                label: 'Gram Altın',
                value: rates != null && rates.gramGoldTry > 0
                    ? rates.gramGoldTry.toStringAsFixed(0)
                    : '—',
                change: _formatChange(current: rates?.gramGoldTry, previous: prev?.gramGoldTry),
              ),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(),
                    child: Text(
                      'Veriler güncelleniyor…',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                    ),
                  ),
                Expanded(
                  // Sabit genişlikli chip ×3 dar ekranda taşma yapıyordu (RenderFlex overflow).
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: i < items.length - 1 ? 8 : 0,
                            ),
                            child: FinanceChip(
                              label: items[i].label,
                              value: items[i].value,
                              change: items[i].change,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FinanceBarShimmer extends StatelessWidget {
  const _FinanceBarShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.04),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder(width: 40, height: 10,
                        borderRadius: BorderRadius.all(Radius.circular(4))),
                    SizedBox(height: 10),
                    ShimmerPlaceholder(width: 56, height: 16,
                        borderRadius: BorderRadius.all(Radius.circular(4))),
                    SizedBox(height: 8),
                    ShimmerPlaceholder(width: 36, height: 10,
                        borderRadius: BorderRadius.all(Radius.circular(4))),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FinanceDisplayItem {
  final String label;
  final String value;
  final String change;
  _FinanceDisplayItem({
    required this.label,
    required this.value,
    required this.change,
  });
}

class FinanceChip extends StatelessWidget {
  final String label;
  final String value;
  final String change;

  const FinanceChip({
    super.key,
    required this.label,
    required this.value,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = !change.startsWith('-');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: isUp ? DesignTokens.primary : Colors.redAccent,
                size: 16,
              ),
              Flexible(
                child: Text(
                  change,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUp ? DesignTokens.primary : Colors.redAccent,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
