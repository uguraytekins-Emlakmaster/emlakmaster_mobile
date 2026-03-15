import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/market_heatmap/presentation/widgets/market_pulse_panel.dart';
import 'package:emlakmaster_mobile/widgets/finance_bar.dart';
import 'package:emlakmaster_mobile/widgets/master_ticker.dart';
import 'package:flutter/material.dart';

/// Yönetici paneli – Ekonomi & Piyasa: kur, altın, piyasa nabzı, ticker.
class AdminEconomyPage extends StatelessWidget {
  const AdminEconomyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        foregroundColor: DesignTokens.textPrimaryDark,
        title: const Text('Ekonomi & Piyasa'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.space6),
        children: const [
          MasterTicker(),
          SizedBox(height: DesignTokens.space6),
          FinanceBar(),
          SizedBox(height: DesignTokens.space6),
          MarketPulsePanel(),
          SizedBox(height: DesignTokens.space6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.space2),
            child: Text(
              'Döviz, faiz ve emlak piyasası verileri anlık güncellenir. '
              'Raporlar sekmesinden detaylı analizlere ulaşabilirsiniz.',
              style: TextStyle(
                color: DesignTokens.textSecondaryDark,
                fontSize: DesignTokens.fontSizeSm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yönetici paneli – Raporlar & Ekip: performans, ekip özeti, audit.
class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        foregroundColor: DesignTokens.textPrimaryDark,
        title: const Text('Raporlar & Ekip'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.space6),
        children: const [
          _SectionCard(
            icon: Icons.analytics_rounded,
            title: 'Performans özeti',
            subtitle: 'Aylık/heftalık çağrı, görüşme ve kapanış metrikleri',
          ),
          SizedBox(height: DesignTokens.space4),
          _SectionCard(
            icon: Icons.groups_rounded,
            title: 'Ekip performansı',
            subtitle: 'Danışman bazlı aktivite ve hedef takibi',
          ),
          SizedBox(height: DesignTokens.space4),
          _SectionCard(
            icon: Icons.history_rounded,
            title: 'Audit log',
            subtitle: 'Sistem ve kullanıcı işlem geçmişi',
          ),
          SizedBox(height: DesignTokens.space4),
          _SectionCard(
            icon: Icons.pie_chart_rounded,
            title: 'Pipeline raporları',
            subtitle: 'Huni analizi, oranlar ve tahminler',
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space5),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space3),
            decoration: BoxDecoration(
              color: DesignTokens.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: Icon(icon, color: DesignTokens.primary, size: 28),
          ),
          const SizedBox(width: DesignTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: DesignTokens.textPrimaryDark,
                    fontWeight: FontWeight.w600,
                    fontSize: DesignTokens.fontSizeMd,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: DesignTokens.textSecondaryDark,
                    fontSize: DesignTokens.fontSizeSm,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: DesignTokens.textTertiaryDark,
          ),
        ],
      ),
    );
  }
}
