import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/features/crm_customers/data/customer_mapper.dart';
import 'package:emlakmaster_mobile/features/office/data/office_membership_repository.dart';
import 'package:emlakmaster_mobile/features/office/domain/membership_status.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_membership_entity.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aktif üyelerin atanmış müşterileri — `whereIn` (max 10) chunk’ları birleştirilir.
Stream<List<CustomerEntity>> officeWideCustomersStream(String officeId) {
  if (officeId.isEmpty) {
    return Stream<List<CustomerEntity>>.value(const []);
  }

  return Stream<List<CustomerEntity>>.multi((controller) {
    final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> chunkSubs = [];
    StreamSubscription<List<OfficeMembership>>? memSub;
    final Map<int, List<CustomerEntity>> chunkCaches = {};

    void emitMerged() {
      final map = <String, CustomerEntity>{};
      for (final list in chunkCaches.values) {
        for (final c in list) {
          map[c.id] = c;
        }
      }
      controller.add(map.values.toList());
    }

    void cancelChunks() {
      for (final s in chunkSubs) {
        s.cancel();
      }
      chunkSubs.clear();
      chunkCaches.clear();
    }

    void subscribeChunks(List<List<String>> chunks) {
      cancelChunks();
      if (chunks.isEmpty) {
        controller.add(const []);
        return;
      }
      for (var i = 0; i < chunks.length; i++) {
        final ci = i;
        final chunk = chunks[i];
        final sub = FirebaseFirestore.instance
            .collection(AppConstants.colCustomers)
            .where('assignedAgentId', whereIn: chunk)
            .snapshots()
            .listen(
          (snap) {
            chunkCaches[ci] = snap.docs
                .map(CustomerMapper.fromQueryDoc)
                .whereType<CustomerEntity>()
                .toList();
            emitMerged();
          },
          onError: controller.addError,
        );
        chunkSubs.add(sub);
      }
    }

    void onMemberships(List<OfficeMembership> memberships) {
      final uids = memberships
          .where((m) => m.status == MembershipStatus.active)
          .map((m) => m.userId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      if (uids.isEmpty) {
        cancelChunks();
        controller.add(const []);
        return;
      }
      final chunks = <List<String>>[];
      const maxIn = 10;
      for (var i = 0; i < uids.length; i += maxIn) {
        chunks.add(uids.sublist(i, math.min(i + maxIn, uids.length)));
      }
      subscribeChunks(chunks);
    }

    memSub = OfficeMembershipRepository.watchMembershipsForOffice(officeId).listen(
      onMemberships,
      onError: controller.addError,
    );

    controller.onCancel = () {
      memSub?.cancel();
      cancelChunks();
    };
  });
}

/// Ofis kimliği: `users/{uid}.officeId`.
final officeWideCustomerListProvider =
    StreamProvider.autoDispose.family<List<CustomerEntity>, String>((ref, officeId) {
  if (officeId.isEmpty) {
    return Stream<List<CustomerEntity>>.value(const []);
  }
  return officeWideCustomersStream(officeId);
});
