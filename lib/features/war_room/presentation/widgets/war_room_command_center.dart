import 'dart:ui';

import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/war_room/data/war_room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Full-screen Command Center: Lead Pulse, Top Performers, Market Ticker, Daily Target.
/// Adaptive: GridView for Web/Desktop (width >= 600), single column for mobile.
class WarRoomCommandCenter extends ConsumerWidget {
  const WarRoomCommandCenter({super.key});

  static const double _breakpointWide = 600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= _breakpointWide;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.backgroundDark,
            DesignTokens.primaryDark.withOpacity(0.4),
          ],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(recentLeadsStreamProvider);
            ref.invalidate(agentsSnapshotProvider);
            ref.invalidate(dealsCountProvider);
            ref.invalidate(officeMonthlyTargetProvider);
          },
          color: DesignTokens.brandGold,
          backgroundColor: DesignTokens.surfaceDark,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.military_tech_rounded, color: DesignTokens.brandGold, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'WAR ROOM',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: DesignTokens.brandWhite,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => context.push('/command-center'),
                        icon: const Icon(Icons.call_rounded, size: 18, color: DesignTokens.brandGold),
                        label: const Text('Çağrı Merkezi', style: TextStyle(color: DesignTokens.brandGold)),
                      ),
                    ],
                  ),
                ),
              ),
              if (isWide) _buildWideGrid(ref) else _buildNarrowColumn(ref),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideGrid(WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          mainAxisExtent: 280,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.4,
        ),
        delegate: SliverChildListDelegate([
          _LeadPulseCard(),
          _TopPerformersCard(),
          _MarketTickerCard(),
          _DailyTargetCard(),
        ]),
      ),
    );
  }

  Widget _buildNarrowColumn(WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const _LeadPulseCard(),
          const SizedBox(height: 16),
          const _TopPerformersCard(),
          const SizedBox(height: 16),
          const _MarketTickerCard(),
          const SizedBox(height: 16),
          const _DailyTargetCard(),
        ]),
      ),
    );
  }
}

class _LeadPulseCard extends ConsumerWidget {
  const _LeadPulseCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentLeadsStreamProvider);
    final liveCalls = ref.watch(liveCallsCountProvider);
    return _GlassCard(
      title: 'Lead Pulse',
      icon: Icons.favorite_rounded,
      child: async.when(
        data: (snap) {
          final docs = snap.docs;
          final count = docs.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  ...List.generate(count.clamp(0, 12), (i) => _GlowingDot(delay: i * 0.15)),
                  const SizedBox(width: 8),
                  Text(
                    '$count yeni lead',
                    style: const TextStyle(
                      color: DesignTokens.brandWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              liveCalls.when(
                data: (calls) => Text(
                  'Şu an $calls aktif çağrı',
                  style: const TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 13),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: DesignTokens.brandGold)),
        error: (e, _) => Text('Lead pulse yüklenemedi.', style: TextStyle(color: DesignTokens.danger, fontSize: 13)),
      ),
    );
  }
}

class _GlowingDot extends StatefulWidget {
  const _GlowingDot({this.delay = 0});
  final double delay;

  @override
  State<_GlowingDot> createState() => _GlowingDotState();
}

class _GlowingDotState extends State<_GlowingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(right: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DesignTokens.brandGold.withOpacity(_animation.value),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.brandGold.withOpacity(_animation.value * 0.8),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopPerformersCard extends ConsumerWidget {
  const _TopPerformersCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(agentsSnapshotProvider);
    return _GlassCard(
      title: 'Top Performers',
      icon: Icons.emoji_events_rounded,
      child: async.when(
        data: (snap) {
          final agents = snap.docs.toList();
          agents.sort((a, b) {
            final ac = a.data()['totalCalls'] as int? ?? 0;
            final bc = b.data()['totalCalls'] as int? ?? 0;
            return bc.compareTo(ac);
          });
          if (agents.isEmpty) {
            return const Center(
              child: Text('Henüz veri yok', style: TextStyle(color: DesignTokens.textSecondaryDark)),
            );
          }
          final top = agents.take(5).toList();
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: top.length,
            itemBuilder: (context, i) {
              final doc = top[i];
              final d = doc.data();
              final name = d['displayName'] as String? ?? d['fullName'] as String? ?? 'Danışman';
              final calls = d['totalCalls'] as int? ?? 0;
              final trophy = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '  ';
              return RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                  children: [
                    Text(trophy, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(color: DesignTokens.textPrimaryDark, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$calls çağrı',
                      style: const TextStyle(color: DesignTokens.brandGold, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: DesignTokens.brandGold)),
        error: (e, _) => Text('Yüklenemedi.', style: TextStyle(color: DesignTokens.danger, fontSize: 13)),
      ),
    );
  }
}

class _MarketTickerCard extends StatelessWidget {
  const _MarketTickerCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      title: 'Market Ticker',
      icon: Icons.trending_up_rounded,
      child: StreamBuilder<List<String>>(
        stream: FirestoreService.officeTickerStream,
        initialData: FirestoreService.defaultTickerItems,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <String>[];
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...items.take(4).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: DesignTokens.brandGold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e,
                            style: const TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _DailyTargetCard extends ConsumerWidget {
  const _DailyTargetCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(dealsCountProvider);
    final targetAsync = ref.watch(officeMonthlyTargetProvider);
    return _GlassCard(
      title: 'Aylık Hedef',
      icon: Icons.flag_rounded,
      child: dealsAsync.when(
        data: (deals) {
          return targetAsync.when(
            data: (target) {
              final progress = target > 0 ? (deals / target).clamp(0.0, 1.0) : 0.0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$deals / $target',
                        style: const TextStyle(
                          color: DesignTokens.brandWhite,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(color: DesignTokens.brandGold, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: DesignTokens.surfaceDarkElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(DesignTokens.brandGold),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bu ay kapanan satış',
                    style: TextStyle(color: DesignTokens.textTertiaryDark, fontSize: 11),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: DesignTokens.brandGold)),
            error: (_, __) => Text('$deals satış', style: const TextStyle(color: DesignTokens.brandWhite, fontSize: 18)),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: DesignTokens.brandGold)),
        error: (e, _) => Text('Hedef yüklenemedi.', style: TextStyle(color: DesignTokens.danger, fontSize: 13)),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.space5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            color: DesignTokens.surfaceDark.withOpacity(0.6),
            border: Border.all(color: DesignTokens.brandGold.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.brandNavy.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: DesignTokens.brandGold, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: DesignTokens.brandWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
