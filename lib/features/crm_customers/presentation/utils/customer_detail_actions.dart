import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/application/start_crm_outbound_call.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_next_best_action.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_stream_provider.dart'
    show advisorTasksStreamProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Müşteri detay — önerilen aksiyon tek tık.
abstract final class CustomerDetailActions {
  CustomerDetailActions._();

  static Future<void> runNextBest(
    BuildContext context,
    WidgetRef ref, {
    required String customerId,
    required NextBestActionCode code,
  }) async {
    final entity = ref.read(customerEntityByIdProvider(customerId)).valueOrNull;
    final phone = entity?.primaryPhone?.trim() ?? '';

    switch (code) {
      case NextBestActionCode.call_now:
      case NextBestActionCode.follow_up_today:
        if (phone.isNotEmpty) {
          startCrmOutboundCall(
            context,
            phone: phone,
            customerId: customerId,
            startedFromScreen: 'customer_detail_nba',
          );
        }
        return;
      case NextBestActionCode.schedule_visit:
      case NextBestActionCode.confirm_appointment:
        context.push(
          AppRouter.routeCall,
          extra: {
            'customerId': customerId,
            'startedFromScreen': 'customer_detail_nba_visit',
          },
        );
        return;
      case NextBestActionCode.send_price_followup:
        context.push(
          AppRouter.routeCall,
          extra: {
            'customerId': customerId,
            'startedFromScreen': 'customer_detail_nba_price',
          },
        );
        return;
      case NextBestActionCode.prioritize_open_tasks:
        final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
        if (uid.isEmpty) return;
        await FirestoreService.setTask({
          'advisorId': uid,
          'customerId': customerId,
          'title': 'Müşteri takibi — ${entity?.fullName ?? customerId}',
          'dueAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 1)),
          ),
          'done': false,
        });
        ref.invalidate(advisorTasksStreamProvider(uid));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Görev eklendi.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      case NextBestActionCode.nurture_sequence:
      case NextBestActionCode.wait_and_watch:
        return;
    }
  }
}
