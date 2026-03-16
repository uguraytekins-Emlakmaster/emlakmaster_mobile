/// Eşleştirme motoru için ilan özeti (Firestore listing doc'tan parse edilir).
class ListingForMatch {
  const ListingForMatch({
    required this.id,
    required this.title,
    this.price,
    this.regions = const [],
    this.propertyType,
    this.hasPool = false,
  });

  final String id;
  final String title;
  final double? price;
  final List<String> regions;
  final String? propertyType;
  final bool hasPool;

  /// Isolate'e gönderilmek için Map (compute sendable).
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'price': price,
        'regions': regions,
        'propertyType': propertyType,
        'hasPool': hasPool,
      };

  /// Firestore listing dokümanından parse (esnek alan adları).
  static ListingForMatch fromMap(String id, Map<String, dynamic> data) {
    final price = (data['price'] as num?)?.toDouble() ??
        (data['listingPrice'] as num?)?.toDouble() ??
        (data['amount'] as num?)?.toDouble();
    final title = data['title'] as String? ??
        data['listingTitle'] as String? ??
        data['description'] as String? ??
        'İlan';
    final regionRaw = data['region'] ?? data['district'] ?? data['regionPreferences'] ?? data['regions'];
    final List<String> regions = regionRaw is List
        ? regionRaw.map((e) => e.toString()).toList()
        : regionRaw != null
            ? [regionRaw.toString()]
            : [];
    final propertyType = data['propertyType'] as String? ??
        data['type'] as String? ??
        data['roomType'] as String?;
    final features = data['features'] as List? ?? data['amenities'] as List? ?? [];
    final hasPool = features.any((e) =>
        e.toString().toLowerCase().contains('havuz') || e.toString().toLowerCase().contains('pool'));
    return ListingForMatch(
      id: id,
      title: title,
      price: price,
      regions: regions,
      propertyType: propertyType,
      hasPool: hasPool,
    );
  }
}
