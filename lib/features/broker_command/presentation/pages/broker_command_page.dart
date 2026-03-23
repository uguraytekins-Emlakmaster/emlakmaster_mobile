import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/daily_brief/presentation/widgets/daily_brief_panel.dart';
import 'package:emlakmaster_mobile/features/deal_discovery/presentation/widgets/discovery_panel.dart';
import 'package:emlakmaster_mobile/features/market_heatmap/presentation/widgets/market_pulse_panel.dart';
import 'package:emlakmaster_mobile/features/missed_opportunities/presentation/widgets/missed_opportunities_panel.dart';
import 'package:emlakmaster_mobile/features/region_demand_map/presentation/widgets/region_demand_map_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/unauthorized_screen.dart';

/// Broker Command Intelligence: tek panel – riskli fırsatlar, kapanmaya yakın, sıcak müşteriler, ekip, piyasa.
class BrokerCommandPage extends ConsumerWidget {
  const BrokerCommandPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(displayRoleProvider);
    return roleAsync.when(
      loading: () => const Scaffold(
        backgroundColor: DesignTokens.scaffoldDark,
        body: Center(child: CircularProgressIndicator(color: DesignTokens.primary)),
      ),
      error: (_, __) => const UnauthorizedScreen(message: 'Rol yüklenemedi.'),
      data: (role) {
        if (!FeaturePermission.canViewWarRoom(role)) {
          return const UnauthorizedScreen(
            message: 'Broker Command ekranına sadece yönetici ve operasyon erişebilir.',
          );
        }
        return _BrokerCommandBody();
      },
    );
  }
}

class _BrokerCommandBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: emlakAppBar(
        context,
        title: const Text('Broker Command'),
        backgroundColor: DesignTokens.backgroundDark,
        foregroundColor: DesignTokens.textPrimaryDark,
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        color: DesignTokens.primary,
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.space4),
          children: const [
            _SectionTitle(title: 'Piyasa sinyalleri'),
            MarketPulsePanel(),
            SizedBox(height: 16),
            _SectionTitle(title: 'Bölge talep haritası'),
            RegionDemandMapPanel(),
            SizedBox(height: 16),
            _SectionTitle(title: 'Bugün keşfedilen fırsatlar'),
            DiscoveryPanel(),
            SizedBox(height: 16),
            _SectionTitle(title: 'Bugünün özeti'),
            DailyBriefPanel(),
            SizedBox(height: 16),
            _SectionTitle(title: 'Kaçırılan fırsatlar'),
            MissedOpportunitiesPanel(),
            SizedBox(height: 24),
            _SectionTitle(title: 'Ekip performansı'),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Çağrı yoğunluğu ve satış metrikleri burada listelenecek.',
                style: TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: DesignTokens.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
