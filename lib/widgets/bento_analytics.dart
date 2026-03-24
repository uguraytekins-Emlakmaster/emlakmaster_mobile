import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter/material.dart';

class BentoPowerAnalytics extends StatelessWidget {
  const BentoPowerAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return StreamBuilder<int>(
      stream: FirestoreService.callsCountStream(),
      builder: (context, callsSnapshot) {
        return StreamBuilder<int>(
          stream: FirestoreService.dealsCountStream(),
          builder: (context, dealsSnapshot) {
            final callsCount = callsSnapshot.data ?? 0;
            final dealsCount = dealsSnapshot.data ?? 0;
            final isLoading =
                callsSnapshot.connectionState == ConnectionState.waiting &&
                    !callsSnapshot.hasData;

            if (isLoading && !callsSnapshot.hasData) {
              return _AnalyticsLoading();
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.agentsStream(),
              builder: (context, agentsSnapshot) {
                int missed = 0;
                if (agentsSnapshot.hasData && agentsSnapshot.data!.docs.isNotEmpty) {
                  for (final doc in agentsSnapshot.data!.docs) {
                    missed += (doc.data()['missedCalls'] as num?)?.toInt() ?? 0;
                  }
                }

                return RepaintBoundary(
                  child: Container(
                  decoration: ext.surfaceCardDecoration(
                    surfaceColor: Color.alphaBlend(
                      ext.foreground.withValues(alpha: 0.04),
                      ext.surface,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Power Analytics',
                            style: TextStyle(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: ext.accent.withValues(alpha: 0.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: ext.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Canlı',
                                  style: TextStyle(
                                    color: ext.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Çağrı & işlem sayıları (calls / deals)',
                        style: TextStyle(color: ext.textTertiary, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        child: DonutChartsRow(
                          callTrafficValue: '$callsCount',
                          callTrafficSub: 'Çağrı (calls)',
                          missedValue: '$missed',
                          missedSub: 'Geri dönülmeyen',
                          dealValue: '$dealsCount',
                          dealSub: 'İşlem (deals)',
                        ),
                      ),
                    ],
                  ),
                ),
              );
              },
            );
          },
        );
      },
    );
  }
}

class _AnalyticsLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      decoration: ext.surfaceCardDecoration(
        surfaceColor: Color.alphaBlend(
          ext.foreground.withValues(alpha: 0.04),
          ext.surface,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          CircularProgressIndicator(strokeWidth: 2, color: ext.accent),
          const SizedBox(height: 12),
          Text(
            'Yükleniyor...',
            style: TextStyle(color: ext.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class DonutChartsRow extends StatelessWidget {
  const DonutChartsRow({
    super.key,
    required this.callTrafficValue,
    required this.callTrafficSub,
    required this.missedValue,
    required this.missedSub,
    required this.dealValue,
    required this.dealSub,
  });

  final String callTrafficValue;
  final String callTrafficSub;
  final String missedValue;
  final String missedSub;
  final String dealValue;
  final String dealSub;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Row(
        children: [
          Expanded(
            child: _AnimatedDonut(
              label: 'Call Traffic',
              value: callTrafficValue,
              sub: callTrafficSub,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AnimatedDonut(
              label: 'Missed\nOpportunities',
              value: missedValue,
              sub: missedSub,
              isAlert: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AnimatedDonut(
              label: 'Deal Volume',
              value: dealValue,
              sub: dealSub,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDonut extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool isAlert;

  const _AnimatedDonut({
    required this.label,
    required this.value,
    required this.sub,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final borderColor = isAlert ? ext.danger : ext.accent;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, anim, child) {
        return Opacity(
          opacity: anim,
          child: Transform.scale(
            scale: anim,
            child: child,
          ),
        );
      },
      child: Stack(
        children: [
          Align(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
                color: ext.surface.withValues(alpha: 0),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    value,
                    key: ValueKey<String>(value),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: borderColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 80),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(color: ext.textTertiary, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isAlert)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: ext.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
