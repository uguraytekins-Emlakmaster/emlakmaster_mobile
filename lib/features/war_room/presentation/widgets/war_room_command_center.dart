import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'dart:ui';

import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/features/war_room/data/war_room_providers.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
/// Full-screen Command Center: Lead Pulse, Top Performers, Market Ticker, Daily Target.
/// Adaptive: GridView for Web/Desktop (width >= 600), single column for mobile.
class WarRoomCommandCenter extends ConsumerWidget {
  const WarRoomCommandCenter({super.key});

  static const double _breakpointWide = 600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppThemeExtension.of(context).surface : AppThemeExtension.of(context).surface;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= _breakpointWide;
    final gradientColors = isDark
        ? [AppThemeExtension.of(context).background, AppThemeExtension.of(context).background.withValues(alpha: 0.4)]
        : [AppThemeExtension.of(context).background, AppThemeExtension.of(context).background];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
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
          color: AppThemeExtension.of(context).accent,
          backgroundColor: surface,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      if (context.canPop()) ...[
                        const AppBackButton(),
                        const SizedBox(width: 4),
                      ],
                      Icon(Icons.military_tech_rounded, color: AppThemeExtension.of(context).accent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'WAR ROOM',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: isDark ? AppThemeExtension.of(context).onAccentLight : AppThemeExtension.of(context).textPrimary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _WarRoomTeamFilter(),
                              TextButton.icon(
                                onPressed: () => context.push(AppRouter.routeCommandCenter),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: Icon(Icons.call_rounded, size: 18, color: AppThemeExtension.of(context).accent),
                                label: Text(
                                  'Çağrı Merkezi',
                                  style: TextStyle(color: AppThemeExtension.of(context).accent, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
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
          const _LeadPulseCard(),
          const _TopPerformersCard(),
          const _MarketTickerCard(),
          const _DailyTargetCard(),
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
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(count.clamp(0, 12), (i) => _GlowingDot(delay: i * 0.15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '$count yeni lead',
                      style: TextStyle(
                        color: AppThemeExtension.of(context).onAccentLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              liveCalls.when(
                data: (calls) => Text(
                  'Şu an $calls aktif çağrı',
                  style: TextStyle(color: AppThemeExtension.of(context).textSecondary, fontSize: 13),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: AppThemeExtension.of(context).accent)),
        error: (e, _) => Text('Lead pulse yüklenemedi.', style: TextStyle(color: AppThemeExtension.of(context).danger, fontSize: 13)),
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

  void _onPowerChange() {
    if (!mounted) return;
    if (AppLifecyclePowerService.shouldReduceMotion) {
      _controller.stop();
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (!AppLifecyclePowerService.shouldReduceMotion) {
      _controller.repeat(reverse: true);
    }
    AppLifecyclePowerService.isInBackground.addListener(_onPowerChange);
  }

  @override
  void dispose() {
    AppLifecyclePowerService.isInBackground.removeListener(_onPowerChange);
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
            color: AppThemeExtension.of(context).accent.withValues(alpha: _animation.value),
            boxShadow: [
              BoxShadow(
                color: AppThemeExtension.of(context).accent.withValues(alpha: _animation.value * 0.8),
                blurRadius: 6,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WarRoomTeamFilter extends ConsumerWidget {
  const _WarRoomTeamFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedId = ref.watch(warRoomSelectedTeamIdProvider);
    return StreamBuilder<List<TeamDoc>>(
      stream: FirestoreService.teamsStream(),
      builder: (context, snap) {
        final teams = snap.data ?? [];
        if (teams.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedId,
              isDense: true,
              hint: Text(l10n.t('label_team'), style: TextStyle(color: AppThemeExtension.of(context).accent, fontSize: 12)),
              dropdownColor: AppThemeExtension.of(context).surface,
              items: [
                DropdownMenuItem<String?>(child: Text(l10n.t('filter_all_teams'), style: TextStyle(color: AppThemeExtension.of(context).textPrimary, fontSize: 12))),
                ...teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name, style: TextStyle(color: AppThemeExtension.of(context).textPrimary, fontSize: 12), overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) => ref.read(warRoomSelectedTeamIdProvider.notifier).state = v,
            ),
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
    final teamMemberIds = ref.watch(warRoomTeamMemberIdsProvider).valueOrNull;
    return _GlassCard(
      title: 'Top Performers',
      icon: Icons.emoji_events_rounded,
      child: async.when(
        data: (snap) {
          var agents = snap.docs.toList();
          if (teamMemberIds != null && teamMemberIds.isNotEmpty) {
            agents = agents.where((d) => teamMemberIds.contains(d.id)).toList();
          }
          agents.sort((a, b) {
            final ac = a.data()['totalCalls'] as int? ?? 0;
            final bc = b.data()['totalCalls'] as int? ?? 0;
            return bc.compareTo(ac);
          });
          if (agents.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insights_outlined, size: 36, color: AppThemeExtension.of(context).accent),
                  const SizedBox(height: 8),
                  Text(
                    'Sıralama için veri bekleniyor',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppThemeExtension.of(context).textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Çağrı metrikleri oluştuğunda danışmanlar burada listelenir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppThemeExtension.of(context).textSecondary, fontSize: 12, height: 1.35),
                  ),
                ],
              ),
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
                        style: TextStyle(color: AppThemeExtension.of(context).textPrimary, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$calls çağrı',
                      style: TextStyle(color: AppThemeExtension.of(context).accent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: AppThemeExtension.of(context).accent)),
        error: (e, _) => Text('Yüklenemedi.', style: TextStyle(color: AppThemeExtension.of(context).danger, fontSize: 13)),
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
                        Icon(Icons.circle, size: 6, color: AppThemeExtension.of(context).accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e,
                            style: TextStyle(color: AppThemeExtension.of(context).textSecondary, fontSize: 12),
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
                        style: TextStyle(
                          color: AppThemeExtension.of(context).onAccentLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(color: AppThemeExtension.of(context).accent, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppThemeExtension.of(context).surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(AppThemeExtension.of(context).accent),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bu ay kapanan satış',
                    style: TextStyle(color: AppThemeExtension.of(context).textTertiary, fontSize: 11),
                  ),
                ],
              );
            },
            loading: () => Center(child: CircularProgressIndicator(color: AppThemeExtension.of(context).accent)),
            error: (_, __) => Text('$deals satış', style: TextStyle(color: AppThemeExtension.of(context).onAccentLight, fontSize: 18)),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: AppThemeExtension.of(context).accent)),
        error: (e, _) => Text('Hedef yüklenemedi.', style: TextStyle(color: AppThemeExtension.of(context).danger, fontSize: 13)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppThemeExtension.of(context).surface : AppThemeExtension.of(context).surface;
    final titleColor = isDark ? AppThemeExtension.of(context).onAccentLight : AppThemeExtension.of(context).textPrimary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.cardPaddingStandard),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            color: surface.withValues(alpha: isDark ? 0.6 : 0.95),
            border: Border.all(color: AppThemeExtension.of(context).accent.withValues(alpha: 0.25)),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: AppThemeExtension.of(context).brandNavy.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppThemeExtension.of(context).accent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
