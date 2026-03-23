/// Harici / özel şema URI'lerini GoRouter yolu `/region-insight/:regionId` biçimine çevirir.
///
/// Desteklenen örnekler:
/// - `emlakmaster:///region-insight/kayapinar`
/// - `emlakmaster://app/region-insight/kayapinar`
/// - `emlakmaster://region-insight/kayapinar` (host + path)
/// - `https://example.com/region-insight/kayapinar` (path ile)
String? regionInsightPathFromUri(Uri uri) {
  final path = uri.path;
  if (path.startsWith('/region-insight')) {
    return path.isEmpty ? null : path;
  }
  // emlakmaster://region-insight/kayapinar → host=region-insight, path=/kayapinar
  if (uri.host == 'region-insight') {
    final tail = uri.pathSegments.where((s) => s.isNotEmpty).join('/');
    if (tail.isEmpty) return null;
    return '/region-insight/$tail';
  }
  return null;
}
