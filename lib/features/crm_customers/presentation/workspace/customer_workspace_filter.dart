import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_types.dart';

/// Saf, build-güvenli filtre + arama. Arama önceden hesaplanmış [searchText]
/// üzerinde; pahalı yeniden hesaplama yok. Sıralama snapshot katmanında zaten
/// dikkat-önce yapılır — burada yalnızca süzme.
List<CustomerRowView> filterCustomerWorkspaceRows(
  List<CustomerRowView> source, {
  String query = '',
  CustomerWorkspaceFilter filter = CustomerWorkspaceFilter.all,
}) {
  final q = query.trim().toLowerCase();

  bool matchesFilter(CustomerRowView r) => switch (filter) {
        CustomerWorkspaceFilter.all => true,
        CustomerWorkspaceFilter.hot => r.isHot,
        CustomerWorkspaceFilter.warm => r.isWarm,
        CustomerWorkspaceFilter.cold => r.isCold,
        CustomerWorkspaceFilter.today => r.isToday,
        CustomerWorkspaceFilter.fresh => r.isFresh,
        CustomerWorkspaceFilter.needsContact => r.needsContact,
        CustomerWorkspaceFilter.partial => r.isPartial,
      };

  return source
      .where((r) => matchesFilter(r) && (q.isEmpty || r.searchText.contains(q)))
      .toList(growable: false);
}
