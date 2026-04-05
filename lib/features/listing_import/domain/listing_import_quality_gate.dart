import 'package:emlakmaster_mobile/features/listing_import/domain/listing_entity.dart';

/// Yerel URL içe aktarma — üretim listesine düşmeden önce minimum güven eşiği.
abstract final class ListingImportQualityGate {
  static const _placeholderTitle = <String>{
    'ilan',
    'listing',
    'detail',
    'undefined',
    'n/a',
    'null',
  };

  /// [ListingEntity] mock veya gerçek parse sonrası doğrulanır.
  static String? rejectReasonForUrlListing(ListingEntity l) {
    final pid = l.platformId.trim().toLowerCase();
    if (pid.isEmpty || pid == 'unknown') {
      return 'Kaynak platform güvenilir şekilde tespit edilemedi. CSV/JSON veya manuel giriş deneyin.';
    }
    final t = l.title.trim();
    if (t.length < 8) {
      return 'Başlık güvenilir değil (çok kısa). Sayfa çözümlenemedi veya deneysel motor yetersiz kaldı.';
    }
    final low = t.toLowerCase();
    if (_placeholderTitle.contains(low) || RegExp(r'^İlan\s*\(').hasMatch(t)) {
      return 'Başlık yer tutucu veya anlamsız görünüyor. İnceleme gerekli — otomatik kayıt yapılmadı.';
    }
    if (l.price <= 0) {
      return 'Fiyat çıkarılamadı veya geçersiz. İçe aktarma iptal edildi.';
    }
    final loc = l.location.trim();
    if (loc.isEmpty || loc == '—') {
      return 'Konum bilgisi yok. Güvenilir içe aktarma için konum gereklidir.';
    }
    if (l.images.isEmpty) {
      return 'Görsel bulunamadı. URL içe aktarma bu kaynak için güvenilir sonuç vermedi.';
    }
    return null;
  }
}
