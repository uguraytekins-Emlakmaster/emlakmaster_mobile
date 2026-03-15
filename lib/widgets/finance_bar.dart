import 'package:emlakmaster_mobile/core/services/finance_service.dart';
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
            final items = <_FinanceDisplayItem>[
              _FinanceDisplayItem(
                label: 'USD/TRY',
                value: rates != null ? rates.usdTry.toStringAsFixed(2) : '—',
                change: _formatChange(current: rates?.usdTry, previous: prev?.usdTry),
              ),
              _FinanceDisplayItem(
                label: 'EUR/TRY',
                value: rates != null ? rates.eurTry.toStringAsFixed(2) : '—',
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
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return FinanceChip(
                        label: item.label,
                        value: item.value,
                        change: item.change,
                      );
                    },
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
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: isUp ? const Color(0xFF00FF41) : Colors.redAccent,
                size: 18,
              ),
              Text(
                change,
                style: TextStyle(
                  color: isUp ? const Color(0xFF00FF41) : Colors.redAccent,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
