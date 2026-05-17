import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_timeline_row.dart';
import 'package:emlakmaster_mobile/features/customer_timeline/domain/entities/timeline_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşteri zaman çizelgesi — dört Firestore akışı tek provider'da birleşir.
final customerTimelineRowsProvider = StreamProvider.autoDispose
    .family<List<CustomerTimelineRow>, String>((ref, customerId) {
  if (customerId.isEmpty) return Stream.value(const []);

  final controller = StreamController<List<CustomerTimelineRow>>.broadcast();
  QuerySnapshot<Map<String, dynamic>>? calls;
  QuerySnapshot<Map<String, dynamic>>? notes;
  QuerySnapshot<Map<String, dynamic>>? visits;
  QuerySnapshot<Map<String, dynamic>>? offers;

  void emitMerged() {
    if (controller.isClosed) return;
    final items = <CustomerTimelineRow>[];

    for (final d in calls?.docs ?? const []) {
      final d2 = d.data();
      final at =
          (d2['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      items.add(CustomerTimelineRow(
        id: d.id,
        type: TimelineItemType.callSummary,
        title: 'Çağrı özeti',
        subtitle: d2['customerIntent'] as String? ?? '—',
        at: at,
      ));
    }
    for (final d in notes?.docs ?? const []) {
      final d2 = d.data();
      final at =
          (d2['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      items.add(CustomerTimelineRow(
        id: d.id,
        type: TimelineItemType.note,
        title: 'Not',
        subtitle: d2['content'] as String? ?? '—',
        at: at,
      ));
    }
    for (final d in visits?.docs ?? const []) {
      final d2 = d.data();
      final at = (d2['scheduledAt'] as Timestamp?)?.toDate() ??
          (d2['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now();
      items.add(CustomerTimelineRow(
        id: d.id,
        type: TimelineItemType.visit,
        title: 'Ziyaret',
        subtitle: d2['notes'] as String? ?? '—',
        at: at,
      ));
    }
    for (final d in offers?.docs ?? const []) {
      final d2 = d.data();
      final amount = d2['amount'] ?? d2['price'];
      final at =
          (d2['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      items.add(CustomerTimelineRow(
        id: d.id,
        type: TimelineItemType.offer,
        title: 'Teklif',
        subtitle: amount != null ? '$amount' : '—',
        at: at,
      ));
    }
    items.sort((a, b) => b.at.compareTo(a.at));
    controller.add(items);
  }

  final subs = <StreamSubscription<dynamic>>[
    FirestoreService.callSummariesByCustomerStream(customerId)
        .listen((s) {
      calls = s;
      emitMerged();
    }),
    FirestoreService.notesByCustomerStream(customerId).listen((s) {
      notes = s;
      emitMerged();
    }),
    FirestoreService.visitsByCustomerStream(customerId).listen((s) {
      visits = s;
      emitMerged();
    }),
    FirestoreService.offersByCustomerStream(customerId).listen((s) {
      offers = s;
      emitMerged();
    }),
  ];

  ref.onDispose(() async {
    for (final s in subs) {
      await s.cancel();
    }
    await controller.close();
  });

  return controller.stream;
});
