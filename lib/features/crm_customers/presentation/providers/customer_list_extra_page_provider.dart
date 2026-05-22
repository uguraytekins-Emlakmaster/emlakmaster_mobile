import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/crm_customers/data/customer_mapper.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerListExtraPageState {
  const CustomerListExtraPageState({
    this.extraEntities = const [],
    this.loading = false,
    this.hasMore = false,
    this.lastDocument,
  });

  final List<CustomerEntity> extraEntities;
  final bool loading;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
}

/// Stream ilk sayfasından sonra yüklenen müşteriler.
class CustomerListExtraPageNotifier
    extends AutoDisposeFamilyNotifier<CustomerListExtraPageState, String> {
  @override
  CustomerListExtraPageState build(String uid) {
    ref.listen(customerListForAgentProvider, (previous, next) {
      if (next.hasValue) {
        state = const CustomerListExtraPageState();
      }
    });
    return const CustomerListExtraPageState();
  }

  Future<void> loadMore(String uid) async {
    if (uid.isEmpty || state.loading) return;
    final firstPage = ref.read(customerListForAgentProvider).valueOrNull;
    final cursor = state.lastDocument ?? firstPage?.lastDocument;
    final canLoad = state.extraEntities.isEmpty
        ? (firstPage?.hasMore ?? false)
        : state.hasMore;
    if (!canLoad || cursor == null) return;

    state = CustomerListExtraPageState(
      extraEntities: state.extraEntities,
      loading: true,
      hasMore: state.hasMore,
      lastDocument: state.lastDocument,
    );
    try {
      final snap = await FirestoreService.fetchCustomersByAssignedAgentPage(
        uid,
        startAfter: cursor,
      );
      final batch = snap.docs
          .map((d) => CustomerMapper.fromQueryDoc(d))
          .whereType<CustomerEntity>()
          .toList();
      final seen = <String>{
        for (final e in firstPage?.entities ?? const []) e.id,
        for (final e in state.extraEntities) e.id,
      };
      final merged = [
        ...state.extraEntities,
        ...batch.where((e) => !seen.contains(e.id)),
      ];
      state = CustomerListExtraPageState(
        extraEntities: merged,
        hasMore: snap.docs.length >= FirestoreService.customerListPageSize,
        lastDocument: snap.docs.isEmpty ? state.lastDocument : snap.docs.last,
      );
    } finally {
      state = CustomerListExtraPageState(
        extraEntities: state.extraEntities,
        hasMore: state.hasMore,
        lastDocument: state.lastDocument,
      );
    }
  }
}

final customerListExtraPageProvider = NotifierProvider.autoDispose
    .family<CustomerListExtraPageNotifier, CustomerListExtraPageState, String>(
  CustomerListExtraPageNotifier.new,
);

/// Stream ilk sayfa + ek sayfalar.