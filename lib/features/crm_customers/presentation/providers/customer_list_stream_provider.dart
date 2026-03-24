import 'dart:async';

import 'package:emlakmaster_mobile/core/config/dev_mode_config.dart';
import 'package:emlakmaster_mobile/core/data/crm_dev_demo_customers.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/data/customer_mapper.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Giriş yapan danışmana atanmış müşteriler. Hata durumunda çökmez; dev’de boşsa demo satırlar.
final customerListForAgentProvider =
    StreamProvider.autoDispose<List<CustomerEntity>>((ref) {
  final uid = ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
  if (uid.isEmpty) {
    return Stream<List<CustomerEntity>>.value(const []);
  }

  final controller = StreamController<List<CustomerEntity>>.broadcast();
  late final StreamSubscription sub;
  sub = FirestoreService.customersByAssignedAgentStream(uid).listen(
    (snap) {
      final list = snap.docs
          .map((d) => CustomerMapper.fromQueryDoc(d))
          .whereType<CustomerEntity>()
          .toList();
      if (isDevMode && list.isEmpty) {
        controller.add(List<CustomerEntity>.from(crmDevDemoCustomers));
      } else {
        controller.add(list);
      }
    },
    onError: (Object e, StackTrace st) {
      debugPrint('[customerListForAgentProvider] $e');
      if (isDevMode) {
        controller.add(List<CustomerEntity>.from(crmDevDemoCustomers));
      } else {
        controller.add(const <CustomerEntity>[]);
      }
    },
  );

  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });

  return controller.stream;
});
