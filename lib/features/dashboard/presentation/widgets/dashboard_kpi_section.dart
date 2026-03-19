import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/kpi_bar.dart';
import 'package:flutter/material.dart';

/// Dashboard KPI bar'ı Firestore verisiyle besler.
/// Bugünkü çağrı, cevaplanan/kaçırılan, aktif danışman/görüşme, açık follow-up görevleri canlıdır.
class DashboardKpiSection extends StatelessWidget {
  const DashboardKpiSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: FirestoreService.todayCallsCountStream(),
      builder: (context, todayCallsSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.agentsStream(),
          builder: (context, agentsSnap) {
            return StreamBuilder<int>(
              stream: FirestoreService.openTasksCountStream(),
              builder: (context, tasksSnap) {
                final totalCalls = todayCallsSnap.data ?? 0;
                final hasCalls = todayCallsSnap.hasData;
                int missedCalls = 0;
                int activeAdvisors = 0;
                int activeCalls = 0;
                if (agentsSnap.hasData && agentsSnap.data!.docs.isNotEmpty) {
                  for (final doc in agentsSnap.data!.docs) {
                    final data = doc.data();
                    missedCalls += (data['missedCalls'] as num?)?.toInt() ?? 0;
                    activeAdvisors++;
                    final status = data['status'] as String?;
                    if (status == 'Görüşmede') activeCalls++;
                  }
                }
                final answeredCalls = totalCalls > missedCalls
                    ? totalCalls - missedCalls
                    : totalCalls;
                final followUpPending = tasksSnap.data ?? 0;
                final isLoading =
                    todayCallsSnap.connectionState == ConnectionState.waiting &&
                        !hasCalls;

                if (isLoading) {
                  return const SizedBox(
                    height: 52,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DesignTokens.antiqueGold,
                        ),
                      ),
                    ),
                  );
                }

                return KpiBar(
                  totalCalls: totalCalls,
                  answeredCalls: answeredCalls,
                  missedCalls: missedCalls,
                  followUpPending: followUpPending,
                  activeAdvisors: activeAdvisors,
                  activeCalls: activeCalls,
                );
              },
            );
          },
        );
      },
    );
  }
}
