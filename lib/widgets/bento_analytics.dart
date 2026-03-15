import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter/material.dart';

class BentoPowerAnalytics extends StatelessWidget {
  const BentoPowerAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
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

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white.withOpacity(0.04),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Power Analytics',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: const Color(0xFF00FF41).withOpacity(0.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00FF41),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Canlı',
                                  style: TextStyle(
                                    color: Color(0xFF00FF41),
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
                      const Text(
                        'Çağrı & işlem sayıları (calls / deals)',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      DonutChartsRow(
                        callTrafficValue: '$callsCount',
                        callTrafficSub: 'Çağrı (calls)',
                        missedValue: '$missed',
                        missedSub: 'Geri dönülmeyen',
                        dealValue: '$dealsCount',
                        dealSub: 'İşlem (deals)',
                      ),
                    ],
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.04),
      ),
      padding: const EdgeInsets.all(20),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8),
          CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
          SizedBox(height: 12),
          Text(
            'Yükleniyor...',
            style: TextStyle(color: Colors.white70, fontSize: 12),
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
    final borderColor = isAlert ? Colors.redAccent : const Color(0xFF00FF41);
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
                color: Colors.transparent,
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
            child: Column(
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 9),
                ),
              ],
            ),
          ),
          if (isAlert)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
