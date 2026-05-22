import 'dart:async';

import 'package:emlakmaster_mobile/core/config/dev_mode_config.dart';
import 'package:emlakmaster_mobile/core/data/crm_dev_demo_customers.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/data/customer_mapper.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_list_page_data.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter/foundation.dart' show debugPrint, kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Giriş yapan danışmana atanmış müşteriler (ilk sayfa, canlı). Release’te asla demo.
final customerListForAgentProvider =
    StreamProvider.autoDispose<CustomerListPageData>((ref) {
  final uid = ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
  if (uid.isEmpty) {
    return Stream<CustomerListPageData>.value(CustomerListPageData.empty);
  }

  final controller = StreamController<CustomerListPageData>.broadcast();
  late final StreamSubscription sub;
  sub = FirestoreService.customersByAssignedAgentStream(uid).listen(
    (snap) {
      final list = snap.docs
          .map((d) => CustomerMapper.fromQueryDoc(d))
          .whereType<CustomerEntity>()
          .toList();
      final page = CustomerListPageData(
        entities: list,
        hasMore: snap.docs.length >= FirestoreService.customerListPageSize,
        lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
      );
      if (FirestoreService.isFirestoreReady) {
        controller.add(page);
      } else if (!kReleaseMode && isDevMode && list.isEmpty) {
        controller.add(
          CustomerListPageData(
            entities: List<CustomerEntity>.from(crmDevDemoCustomers),
          ),
        );
      } else {
        controller.add(page);
      }
    },
    onError: (Object e, StackTrace st) {
      debugPrint('[customerListForAgentProvider] $e');
      if (!kReleaseMode && isDevMode) {
        controller.add(
          CustomerListPageData(
            entities: List<CustomerEntity>.from(crmDevDemoCustomers),
          ),
        );
      } else {
        controller.add(CustomerListPageData.empty);
      }
    },
  );

  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });

  return controller.stream;
});

/// Geriye uyumluluk: yalnızca entity listesi.
final customerListEntitiesProvider =
    Provider.autoDispose<List<CustomerEntity>>((ref) {
  return ref.watch(customerListForAgentProvider).valueOrNull?.entities ??
      const [];
});
