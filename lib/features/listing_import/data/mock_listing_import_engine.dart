import 'dart:convert';
import 'dart:math';

import 'package:emlakmaster_mobile/features/listing_import/domain/duplicate_grouping.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/listing_canonical_helpers.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/listing_entity.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/listing_import_quality_gate.dart';
import 'package:uuid/uuid.dart';

/// Gerçek scraping yok — gecikme + örnek veri (AI / API entegrasyonuna hazır arayüz).
class MockListingImportEngine {
  MockListingImportEngine._();
  static final MockListingImportEngine instance = MockListingImportEngine._();

  final _uuid = const Uuid();
  final _random = Random();

  String detectPlatformId(String url) {
    final u = url.toLowerCase();
    if (u.contains('sahibinden')) return 'sahibinden';
    if (u.contains('hepsiemlak') || u.contains('hepsi')) return 'hepsiemlak';
    if (u.contains('emlakjet')) return 'emlakjet';
    return 'unknown';
  }

  Future<void> simulateWork({int progressSteps = 4}) async {
    for (var i = 0; i < progressSteps; i++) {
      await Future<void>.delayed(Duration(milliseconds: 280 + _random.nextInt(420)));
    }
  }

  Future<ListingEntity> parseUrlMock({
    required String ownerUserId,
    required String url,
    String? taskId,
  }) async {
    final platformId = detectPlatformId(url);
    if (platformId == 'unknown') {
      throw StateError(
        'URL kaynağı tanınmadı (sahibinden / hepsiemlak / emlakjet değil). '
        'Deneysel içe aktarma iptal edildi; CSV/JSON veya manuel giriş kullanın.',
      );
    }
    await simulateWork();

    final title = _titleFromUrl(url);
    final price = 3500000.0 + _random.nextDouble() * 4000000.0;
    final location = 'Diyarbakır · ${['Kayapınar', 'Bağlar', 'Yenişehir'][_random.nextInt(3)]}';
    final description =
        'Deneysel yerel içe aktarma (mock): ${title.length > 80 ? title.substring(0, 80) : title} — '
        'canlı OAuth/parse yok; üretim doğruluğu garanti edilmez.';

    final seed = url.hashCode.abs();
    final mainImage = 'https://picsum.photos/seed/$seed/800/600';

    final groupId = DuplicateGrouping.computeGroupId(
      title: title,
      price: price,
      location: location,
    );

    final now = DateTime.now();
    final sourceListingId = 'url_${url.hashCode}';
    final out = ListingEntity(
      id: _uuid.v4(),
      ownerUserId: ownerUserId,
      title: title,
      price: price,
      location: location,
      description: description,
      images: [
        mainImage,
        'https://picsum.photos/seed/${seed + 1}/800/600',
      ],
      platformId: platformId,
      createdAt: now,
      updatedAt: now,
      duplicateGroupId: groupId,
      sourceUrl: url,
      importTaskId: taskId,
      sourcePlatform: platformId,
      sourceListingId: sourceListingId,
      isOwnedByOffice: true,
      syncStatus: 'pending',
      lastSyncedAt: now,
      contentHash: computeListingContentHash(title: title, price: price, location: location),
    );
    final reject = ListingImportQualityGate.rejectReasonForUrlListing(out);
    if (reject != null) {
      throw StateError(reject);
    }
    return out;
  }

  String _titleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final seg = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (seg.isNotEmpty) {
        final fromSeg = seg.length >= 2 ? '${seg[seg.length - 2]} ${seg.last}' : seg.last;
        final raw = fromSeg.replaceAll('-', ' ').trim();
        if (raw.length >= 8) return raw;
        return 'İlan özeti: $raw · ${uri.host.split('.').first}';
      }
    } catch (_) {}
    return 'İlan içe aktarma ${url.length.clamp(8, 40)} karakter';
  }

  /// CSV / JSON satırlarını listeye çevir (basit parse; gerçek şema sonra).
  Future<List<ListingEntity>> parseFileMock({
    required String ownerUserId,
    required String fileName,
    required Map<String, String> mapping,
    required List<List<dynamic>> rows,
    String? taskId,
    String? storeSourcePlatform,
    String importChannel = 'import_file',
  }) async {
    await simulateWork(progressSteps: 2);
    if (rows.isEmpty) return [];

    final headers = rows.first.map((e) => e.toString().trim()).toList();
    final dataRows = rows.skip(1).where((r) => r.any((c) => '$c'.trim().isNotEmpty)).toList();

    int col(String key) {
      final k = mapping[key];
      if (k == null || k.isEmpty) return -1;
      return headers.indexWhere((h) => h.toLowerCase() == k.toLowerCase());
    }

    final ti = col('title');
    final pi = col('price');
    final ci = col('city');
    final di = col('district');
    final de = col('description');
    final im = col('images');
    final su = col('sourceUrl');
    final ei = col('externalListingId');

    final platformTag = storeSourcePlatform ?? importChannel;

    final out = <ListingEntity>[];
    for (final row in dataRows) {
      String cell(int i) => i >= 0 && i < row.length ? row[i].toString().trim() : '';

      final title = ti >= 0 ? cell(ti) : 'İlan ${out.length + 1}';
      final priceRaw = pi >= 0 ? cell(pi) : '${2.5 + _random.nextDouble() * 3}M';
      final price = _parsePrice(priceRaw);
      final city = ci >= 0 ? cell(ci) : 'Diyarbakır';
      final district = di >= 0 ? cell(di) : 'Merkez';
      final location = '$city · $district';
      final description = de >= 0
          ? cell(de)
          : 'Toplu dosya içe aktarma (yerel). Mağaza OAuth yok; dosya güvenilir kaynaktır.';
      final imgs = im >= 0
          ? cell(im).split(RegExp(r'[;,|]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : <String>['https://picsum.photos/seed/${_random.nextInt(999)}/800/600'];
      final sourceUrl = su >= 0 ? cell(su) : null;
      final extRaw = ei >= 0 ? cell(ei) : '';
      final sourceListingId = extRaw.isNotEmpty ? extRaw : '${platformTag}_${out.length}';

      final now = DateTime.now();
      final groupId = DuplicateGrouping.computeGroupId(
        title: title,
        price: price,
        location: location,
      );

      out.add(
        ListingEntity(
          id: _uuid.v4(),
          ownerUserId: ownerUserId,
          title: title,
          price: price,
          location: location,
          description: description,
          images: imgs.isEmpty ? ['https://picsum.photos/seed/${_random.nextInt(999)}/800/600'] : imgs,
          platformId: platformTag,
          createdAt: now,
          updatedAt: now,
          duplicateGroupId: groupId,
          sourceUrl: sourceUrl,
          importTaskId: taskId,
          sourcePlatform: platformTag,
          sourceListingId: sourceListingId,
          isOwnedByOffice: true,
          syncStatus: 'synced',
          lastSyncedAt: now,
          contentHash: computeListingContentHash(title: title, price: price, location: location),
        ),
      );
    }
    return out;
  }

  double _parsePrice(String raw) {
    final s = raw.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
    if (s.isEmpty) return 2500000;
    final v = double.tryParse(s);
      if (v != null) {
      if (v < 1000) return v * 1000000;
      return v;
    }
    return 2500000 + _random.nextDouble() * 1000000;
  }

  /// JSON dizi veya `{ "rows": [...] }`
  Future<List<ListingEntity>> parseJsonBytesMock({
    required String ownerUserId,
    required Map<String, String> mapping,
    required List<int> bytes,
    String? taskId,
    String? storeSourcePlatform,
    String importChannel = 'import_json',
  }) async {
    await simulateWork(progressSteps: 2);
    final decoded = jsonDecode(utf8.decode(bytes)) as Object?;
    List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map && decoded['rows'] is List) {
      list = decoded['rows'] as List<dynamic>;
    } else if (decoded is Map && decoded['listings'] is List) {
      list = decoded['listings'] as List<dynamic>;
    } else {
      return [];
    }

    final rows = <List<dynamic>>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        rows.add([
          item['title'] ?? '',
          item['price'] ?? '',
          item['city'] ?? '',
          item['district'] ?? '',
          item['description'] ?? '',
          item['images'] ?? '',
          item['link'] ?? item['url'] ?? '',
          item['externalListingId'] ?? item['id'] ?? item['ilan_id'] ?? '',
        ]);
      }
    }
    if (rows.isEmpty) return [];

    final headers = [
      'title',
      'price',
      'city',
      'district',
      'description',
      'images',
      'sourceUrl',
      'externalListingId',
    ];
    final table = <List<dynamic>>[headers, ...rows];
    return parseFileMock(
      ownerUserId: ownerUserId,
      fileName: 'data.json',
      mapping: mapping,
      rows: table,
      taskId: taskId,
      storeSourcePlatform: storeSourcePlatform,
      importChannel: importChannel,
    );
  }

  ListingEntity manualListing({
    required String ownerUserId,
    required String title,
    required double price,
    required String location,
    required String description,
    List<String>? images,
    String? taskId,
  }) {
    final now = DateTime.now();
    final id = _uuid.v4();
    final groupId = DuplicateGrouping.computeGroupId(
      title: title,
      price: price,
      location: location,
    );
    return ListingEntity(
      id: id,
      ownerUserId: ownerUserId,
      title: title,
      price: price,
      location: location,
      description: description,
      images: images ??
          ['https://picsum.photos/seed/${_random.nextInt(999)}/800/600'],
      platformId: 'manual',
      createdAt: now,
      updatedAt: now,
      duplicateGroupId: groupId,
      importTaskId: taskId,
      sourcePlatform: 'manual',
      sourceListingId: id,
      isOwnedByOffice: true,
      syncStatus: 'synced',
      lastSyncedAt: now,
      contentHash: computeListingContentHash(title: title, price: price, location: location),
    );
  }
}
