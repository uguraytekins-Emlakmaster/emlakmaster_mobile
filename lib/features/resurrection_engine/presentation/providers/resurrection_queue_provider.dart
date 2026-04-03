import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/calls/domain/call_transcript_snapshot.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_ai_enrichment.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/usecases/get_resurrection_queue.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final getResurrectionQueueProvider = Provider<GetResurrectionQueue>((ref) {
  return GetResurrectionQueue();
});

/// Tüm müşterileri alıp resurrection kuyruğuna dönüştürür (7/14/30+ gün sessiz).
final resurrectionQueueProvider = StreamProvider<List<ResurrectionQueueItem>>((ref) {
  final getQueue = ref.watch(getResurrectionQueueProvider);
  return FirestoreService.customersStream().asyncMap((snap) {
    final customers = snap.docs.map((d) {
      final data = d.data();
      return CustomerEntity(
        id: d.id,
        fullName: data['fullName'] as String?,
        primaryPhone: data['primaryPhone'] as String?,
        email: data['email'] as String?,
        source: data['source'] as String?,
        assignedAdvisorId: data['assignedAgentId'] as String? ?? data['assignedAdvisorId'] as String?,
        budgetMin: (data['budgetMin'] as num?)?.toDouble(),
        budgetMax: (data['budgetMax'] as num?)?.toDouble(),
        regionPreferences: List<String>.from(data['regionPreferences'] as List? ?? []),
        leadTemperature: (data['leadTemperature'] as num?)?.toDouble(),
        lastInteractionAt: (data['lastInteractionAt'] as dynamic)?.toDate() as DateTime?,
        lastCallSummary: data['lastCallSummary'] as String?,
        nextSuggestedAction: data['lastNextStepSuggestion'] as String? ?? data['nextSuggestedAction'] as String?,
        tags: List<String>.from(data['tags'] as List? ?? []),
        callsCount: data['callsCount'] as int? ?? 0,
        visitsCount: data['visitsCount'] as int? ?? 0,
        offersCount: data['offersCount'] as int? ?? 0,
        lastCallSummarySignals:
            PostCallCrmSignals.tryFromFirestoreMap(data['lastCallSummarySignals']),
        lastCallAiEnrichment:
            PostCallAiEnrichment.tryFromFirestoreMap(data['lastCallAiEnrichment']),
        lastCallTranscript:
            CallTranscriptSnapshot.tryFromFirestoreMap(data['lastCallTranscript']),
        createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      );
    }).toList();
    return getQueue.call(customers);
  });
});
