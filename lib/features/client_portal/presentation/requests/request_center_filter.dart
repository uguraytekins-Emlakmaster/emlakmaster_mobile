import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_types.dart';

/// Saf, build-güvenli filtre. Arama önceden hesaplanmış [searchText] üzerinde;
/// pahalı yeniden hesaplama yok.
List<RequestCenterEntry> filterRequestCenterEntries(
  List<RequestCenterEntry> source, {
  String query = '',
  RequestCenterFilter filter = RequestCenterFilter.all,
}) {
  final q = query.trim().toLowerCase();

  bool matchesFilter(RequestCenterEntry e) => switch (filter) {
        RequestCenterFilter.all => true,
        RequestCenterFilter.active => e.isReady,
        RequestCenterFilter.draft => e.isPreview,
        RequestCenterFilter.message => e.isMessage,
      };

  return source
      .where((e) => matchesFilter(e) && (q.isEmpty || e.searchText.contains(q)))
      .toList(growable: false);
}
