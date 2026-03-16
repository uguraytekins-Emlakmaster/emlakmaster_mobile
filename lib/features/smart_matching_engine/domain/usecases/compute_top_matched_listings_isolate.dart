// Isolate (compute) için top-level fonksiyon — UI thread bloke edilmez (No-Lag Rule).
// Girdi: {'customer': {...}, 'listings': [...]}, çıktı: [{'listingId', 'title', 'score', ...}, ...] en fazla 6.

List<Map<String, dynamic>> computeTopMatchedListings(Map<String, dynamic> input) {
  final customerMap = input['customer'] as Map<String, dynamic>?;
  final listingsList = input['listings'] as List<dynamic>?;
  if (customerMap == null || listingsList == null) return [];
  final budgetMin = (customerMap['budgetMin'] as num?)?.toDouble();
  final budgetMax = (customerMap['budgetMax'] as num?)?.toDouble() ?? double.infinity;
  final regionPrefs = (customerMap['regionPreferences'] as List<dynamic>?)
      ?.map((e) => e.toString())
      .toList() ?? [];
  final tags = (customerMap['tags'] as List<dynamic>?)
      ?.map((e) => e.toString())
      .toList() ?? [];

  final results = <Map<String, dynamic>>[];
  for (final raw in listingsList) {
    final listing = raw as Map<String, dynamic>;
    final listingId = listing['id'] as String? ?? '';
    final title = listing['title'] as String? ?? 'İlan';
    final price = (listing['price'] as num?)?.toDouble();
    final regions = (listing['regions'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];
    final hasPool = listing['hasPool'] as bool? ?? false;

    var score = 0.0;
    var objectionPenalty = 0.0;

    if (price != null) {
      final min = budgetMin ?? 0.0;
      final max = budgetMax;
      if (price >= min && price <= max) {
        score += 35;
      } else if (price <= max * 1.2) {
        score += 15;
      }
    }

    if (regions.isNotEmpty && regionPrefs.isNotEmpty) {
      final match = regions.any((r) => regionPrefs.any((p) =>
          p.toLowerCase().contains(r.toLowerCase()) ||
          r.toLowerCase().contains(p.toLowerCase())));
      if (match) score += 30;
    }

    if (hasPool && tags.any((o) =>
        o.toLowerCase().contains('havuz') || o == 'havuz_istemiyor')) {
      objectionPenalty = 40.0;
    }

    score = (score - objectionPenalty).clamp(0.0, 100.0);
    final confidence = (score / 100).clamp(0.0, 1.0);
    String? explanation;
    if (objectionPenalty > 0) {
      explanation = 'Müşteri havuz istemediği için bu ilanın eşleşme skoru düşürüldü.';
    } else if (score > 50) {
      explanation = 'Bütçe ve bölge tercihlerine uygun.';
    }

    results.add({
      'listingId': listingId,
      'title': title,
      'score': score,
      'confidenceScore': confidence,
      'aiExplanation': explanation,
    });
  }

  results.sort((a, b) => ((b['score'] as num?) ?? 0)
      .compareTo((a['score'] as num?) ?? 0));
  return results.take(6).toList();
}
