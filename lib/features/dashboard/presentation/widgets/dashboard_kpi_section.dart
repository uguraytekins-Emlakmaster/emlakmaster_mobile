import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/kpi_bar.dart';
import 'package:flutter/material.dart';

/// Dashboard KPI bar'ı Firestore verisiyle besler. Loading'de skeleton, hata/boşta güvenli değerler.
class DashboardKpiSection extends StatelessWidget {
  const DashboardKpiSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: FirestoreService.callsCountStream(),
      builder: (context, callsSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.agentsStream(),
          builder: (context, agentsSnap) {
            final totalCalls = callsSnap.data ?? 0;
            final hasCalls = callsSnap.hasData;
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
            final isLoading =
                callsSnap.connectionState == ConnectionState.waiting &&
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
                      color: Color(0xFF00FF41),
                    ),
                  ),
                ),
              );
            }

            return KpiBar(
              totalCalls: totalCalls,
              answeredCalls: answeredCalls,
              missedCalls: missedCalls,
              activeAdvisors: activeAdvisors,
              activeCalls: activeCalls,
            );
          },
        );
      },
    );
  }
}
