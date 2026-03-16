import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/widgets/finance_bar.dart';
import 'package:emlakmaster_mobile/widgets/master_ticker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Danışman paneli – Benim Özetim: günlük odak, takip sayısı, hızlı erişim, piyasa.
class ConsultantDashboardPage extends ConsumerWidget {
  const ConsultantDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resurrectionAsync = ref.watch(resurrectionQueueProvider);
    final user = ref.watch(currentUserProvider.select((v) => v.valueOrNull));
    final greeting = user?.email != null
        ? 'Merhaba, ${user!.email!.split('@').first}'
        : 'Merhaba';
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: DesignTokens.textSecondaryDark,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Benim Özetim',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: DesignTokens.textPrimaryDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Semantics(
                          label: 'Bildirimler',
                          button: true,
                          child: IconButton(
                            onPressed: () => context.push(AppRouter.routeNotifications),
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: DesignTokens.textSecondaryDark,
                              size: 26,
                            ),
                            tooltip: 'Bildirimler',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _TodayBriefLine(resurrectionAsync: resurrectionAsync),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space6),
                child: _QuickStatsCard(resurrectionAsync: resurrectionAsync),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.space4)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.space6),
                child: _WeeklyGoalCard(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.space4)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.space6),
                child: _PipelineChampionCard(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.space6)),
            const SliverToBoxAdapter(child: MasterTicker()),
            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.space4)),
            const SliverToBoxAdapter(child: FinanceBar()),
            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.space12)),
          ],
        ),
      ),
    );
  }
}

class _TodayBriefLine extends StatelessWidget {
  const _TodayBriefLine({required this.resurrectionAsync});
  final AsyncValue<List<dynamic>> resurrectionAsync;

  @override
  Widget build(BuildContext context) {
    final count = resurrectionAsync.valueOrNull?.length ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space3, vertical: DesignTokens.space2),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: DesignTokens.borderDark.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.today_rounded, size: 18, color: DesignTokens.primary),
          const SizedBox(width: DesignTokens.space2),
          const Text(
            'Bugün: ',
            style: TextStyle(color: DesignTokens.textSecondaryDark, fontSize: DesignTokens.fontSizeSm),
          ),
          Text(
            '$count takip',
            style: const TextStyle(
              color: DesignTokens.textPrimaryDark,
              fontWeight: FontWeight.w600,
              fontSize: DesignTokens.fontSizeSm,
            ),
          ),
          if (count > 0) ...[
            const Text(' · ', style: TextStyle(color: DesignTokens.textTertiaryDark)),
            const Text(
              'Önerilen aksiyonlar listede',
              style: TextStyle(color: DesignTokens.textTertiaryDark, fontSize: DesignTokens.fontSizeXs),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyGoalCard extends ConsumerWidget {
  const _WeeklyGoalCard();

  static const int weeklyGoal = 15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    return StreamBuilder<int>(
      stream: FirestoreService.agentWeeklyCallCountStream(uid),
      builder: (context, snap) {
        final current = snap.data ?? 0;
        final progress = weeklyGoal > 0 ? (current / weeklyGoal).clamp(0.0, 1.0) : 0.0;
        return Container(
          padding: const EdgeInsets.all(DesignTokens.space4),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceDark.withOpacity(0.6),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: DesignTokens.borderDark.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bu hafta',
                    style: TextStyle(color: DesignTokens.textSecondaryDark, fontSize: DesignTokens.fontSizeSm),
                  ),
                  Text(
                    '$current / $weeklyGoal çağrı',
                    style: const TextStyle(
                      color: DesignTokens.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: DesignTokens.fontSizeSm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space2),
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: DesignTokens.borderDark,
                  valueColor: const AlwaysStoppedAnimation<Color>(DesignTokens.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PipelineChampionCard extends StatelessWidget {
  const _PipelineChampionCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRouter.routePipeline);
        },
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.space5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
              color: DesignTokens.primary.withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.primary.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignTokens.surfaceDark,
                DesignTokens.primary.withOpacity(0.06),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: DesignTokens.gradientPrimary,
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.primary.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_tree_rounded,
                  color: Colors.black,
                  size: 26,
                ),
              ),
              const SizedBox(width: DesignTokens.space4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pipeline',
                      style: TextStyle(
                        color: DesignTokens.textPrimaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: DesignTokens.fontSizeLg,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Satış hunisi · Aşamaları yönet',
                      style: TextStyle(
                        color: DesignTokens.textSecondaryDark,
                        fontSize: DesignTokens.fontSizeSm,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: DesignTokens.primary.withOpacity(0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard({required this.resurrectionAsync});

  final AsyncValue<List<dynamic>> resurrectionAsync;

  @override
  Widget build(BuildContext context) {
    final count = resurrectionAsync.valueOrNull?.length ?? 0;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space5),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space3),
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: const Icon(
                  Icons.replay_rounded,
                  color: DesignTokens.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: DesignTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Takip listesi',
                      style: TextStyle(
                        color: DesignTokens.textPrimaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: DesignTokens.fontSizeMd,
                      ),
                    ),
                    Text(
                      count == 0
                          ? 'Şu an takip edilecek lead yok'
                          : '$count lead takip bekliyor',
                      style: const TextStyle(
                        color: DesignTokens.textSecondaryDark,
                        fontSize: DesignTokens.fontSizeSm,
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                TextButton(
                  onPressed: () {
                    // Takip sekmesine geç (index 3)
                    // Shell içinde sayfa değiştirmek için parent'tan erişim gerekir; basitçe mesaj
                  },
                  child: const Text('Görüntüle'),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.space4),
          const Text(
            'Magic Call ile aradığın müşterilerin özeti otomatik kaydedilir; '
            'takip sekmesinden sessiz kalan lead\'lere ulaşabilirsin.',
            style: TextStyle(
              color: DesignTokens.textTertiaryDark,
              fontSize: DesignTokens.fontSizeXs,
            ),
          ),
        ],
      ),
    );
  }
}
