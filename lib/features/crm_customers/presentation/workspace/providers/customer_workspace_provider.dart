import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_list_page_data.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_extra_page_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_filtered_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_row_snapshots_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/utils/customer_list_heat_filter.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_types.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşterilerim workspace — tek türetilmiş snapshot.
/// Mevcut veri katmanını YENİDEN KULLANIR (yeni backend yok): tam liste +
/// sayfalama + kural tabanlı sıcaklık satır snapshot'ı. Arama/filtre yüzeyde
/// bellek içi yapıldığından bu snapshot tuş başına yeniden hesaplanmaz (boş
/// sorgu ile tam portföy). Yükleme/hata, asıl müşteri akışından yüzeye taşınır.
final customerWorkspaceSnapshotProvider =
    Provider.autoDispose<AsyncValue<CustomerWorkspaceSnapshot>>((ref) {
  final pageAsync = ref.watch(customerListForAgentProvider);

  if (pageAsync.isLoading && !pageAsync.hasValue) {
    return const AsyncValue.loading();
  }
  if (pageAsync.hasError && !pageAsync.hasValue) {
    return AsyncValue.error(
      pageAsync.error!,
      pageAsync.stackTrace ?? StackTrace.current,
    );
  }

  final page = pageAsync.valueOrNull ?? CustomerListPageData.empty;
  final uid =
      ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));

  // Boş sorgu = tüm portföy (sağlayıcı sync-risk/güncellik sıralı döndürür).
  final entities = ref.watch(customerListFilteredProvider(''));
  final rows = ref.watch(customerListRowSnapshotsProvider(''));

  final extra =
      uid.isEmpty ? null : ref.watch(customerListExtraPageProvider(uid));
  final hasMore = page.hasMore || (extra?.hasMore ?? false);

  final inputs = <CustomerWorkspaceInput>[
    for (final e in entities) _inputFor(e, rows[e.id]),
  ];

  final snapshot = computeCustomerWorkspaceSnapshot(inputs, now: DateTime.now());
  return AsyncValue.data(snapshot.copyWith(hasMore: hasMore, uid: uid));
});

bool _isDemo(String id) => id.startsWith('__dev_demo_');

CustomerWorkspaceInput _inputFor(CustomerEntity e, CustomerListRowSnapshot? row) {
  final phone = e.primaryPhone?.trim() ?? '';
  final isDemo = _isDemo(e.id);
  final callable = !isDemo &&
      phone.isNotEmpty &&
      OutboundPhoneDial.isLikelyCallablePhone(phone);

  final heatLevel =
      row != null ? resolveCustomerHeatBand(e, row) : _fallbackBand(e);

  return CustomerWorkspaceInput(
    id: e.id,
    name: e.fullName,
    phone: e.primaryPhone,
    email: e.email,
    heatLevel: heatLevel,
    heatScore: row?.crmHeat.heatScore ?? 0,
    heatReason: row?.crmHeat.heatReasonSummary ?? '',
    lastInteractionAt: e.lastInteractionAt,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
    nextSuggestedAction: e.nextSuggestedAction,
    callablePhone: callable,
    syncRisk: row?.syncDelayedRisk ?? false,
    isDemo: isDemo,
  );
}

// row==null güvenli yedeği (snapshot eksikse) — leadTemperature'a göre dürüst.
CustomerHeatLevel _fallbackBand(CustomerEntity e) {
  final t = e.leadTemperature;
  if (t == null) return CustomerHeatLevel.cold;
  if (t >= 0.7) return CustomerHeatLevel.hot;
  if (t >= 0.4) return CustomerHeatLevel.warm;
  if (t >= 0.2) return CustomerHeatLevel.cool;
  return CustomerHeatLevel.cold;
}
