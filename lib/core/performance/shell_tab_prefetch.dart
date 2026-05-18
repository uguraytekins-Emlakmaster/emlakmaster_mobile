import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_display_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/providers/market_feed_rows_display_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/providers/owned_listing_rows_display_provider.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/providers/team_chat_providers.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_display_provider.dart';
import 'package:emlakmaster_mobile/screens/providers/consultant_dashboard_kpi_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sekme ilk kez materialize olurken Firestore aboneliklerini erken başlatır.
void prefetchShellTab(WidgetRef ref, Object? tabId) {
  if (tabId == null) return;
  final id = tabId.toString();
  final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';

  switch (id) {
    case 'summary':
      ref.read(todayCallsCountProvider);
      break;
    case 'messages':
      ref.read(teamChannelsProvider);
      break;
    case 'calls':
      ref.read(consultantCallsDisplayProvider);
      break;
    case 'customers':
      ref.read(customerListForAgentProvider);
      break;
    case 'listings':
      ref.read(ownedListingRowsDisplayProvider);
      ref.read(marketFeedRowsDisplayProvider);
      break;
    case 'follow_up':
      ref.read(resurrectionQueueProvider);
      break;
    case 'tasks':
      if (uid.isNotEmpty) {
        ref.read(advisorTasksDisplayProvider(uid));
      }
      break;
    case 'dashboard':
      ref.read(todayCallsCountProvider);
      break;
    default:
      break;
  }
}
