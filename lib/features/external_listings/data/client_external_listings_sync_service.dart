import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:emlakmaster_mobile/features/external_listings/data/external_listings_sync_outcome.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

/// Blaze / Cloud Functions olmadan Market Pulse: cihazdan HTML çekilir, Firestore’a yazılır.
/// Flutter Web’de hedef siteler CORS nedeniyle genelde çalışmaz — mobil / masaüstü kullanın.
///
/// **Not:** Sahibinden / Hepsi Emlak sık sık **Cloudflare** ile korunur; Emlakjet sayfası **Next.js**
/// ile istemci tarafında doldurulur — basit HTTP ile çoğu zaman **0 ilan** normaldir.
abstract final class ClientExternalListingsSyncService {
  /// Sahibinden vb. “bot” UA’larını sık sık bloklar; gerçek tarayıcı dizesi kullan.
  static const _uaChrome =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';
  /// Uzun beklemeyi önle; canlı çekim çoğunlukla yine de boş döner (Cloudflare).
  static const _timeout = Duration(seconds: 10);

  /// Üç kaynağın tamamı için üst süre; sonra doğrudan örnek listeye düşülür.
  static const _fetchAllBudget = Duration(seconds: 12);

  /// Cloudflare / bot sayfası (ham HTML’de ilan yok).
  static bool _isCloudflareChallenge(String html) {
    final h = html.toLowerCase();
    return h.contains('just a moment') ||
        h.contains('_cf_chl_opt') ||
        h.contains('cf-challenge') ||
        h.contains('challenge-platform') ||
        h.contains('enable javascript and cookies');
  }

  /// Harici sitelerden çekme + Firestore yazımı. Çoğu üretim ortamında 0 ilan dönebilir (Cloudflare / SPA).
  static Future<ExternalListingsSyncOutcome> syncNow() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Harici ilan çekme tarayıcıda (CORS) desteklenmiyor. '
        'iOS, Android veya macOS uygulamasını kullanın.',
      );
    }
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase başlatılmadı.');
    }
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('Oturum gerekli.');
    }
    await FirestoreService.ensureInitialized();

    final settings = await _loadSettings();
    final cityCode = settings.$1;
    final cityName = settings.$2;
    final districtName = settings.$3;

    final results = await Future.wait([
      _fetchSahibinden(cityCode, cityName, districtName),
      _fetchEmlakjet(cityCode, cityName, districtName),
      _fetchHepsiEmlak(cityCode, cityName, districtName),
    ]).timeout(
      _fetchAllBudget,
      onTimeout: () => <List<_ParsedRow>>[
        <_ParsedRow>[],
        <_ParsedRow>[],
        <_ParsedRow>[],
      ],
    );

    final merged = <String, Map<String, dynamic>>{};
    for (final list in results) {
      for (final row in list) {
        merged[row.docId] = row.toFirestoreMap();
      }
    }

    if (merged.isNotEmpty) {
      final col = FirebaseFirestore.instance.collection(AppConstants.colExternalListings);
      var written = 0;
      final entries = merged.entries.toList();
      const chunk = 400;
      for (var i = 0; i < entries.length; i += chunk) {
        final batch = FirebaseFirestore.instance.batch();
        final slice = entries.skip(i).take(chunk).toList();
        for (final e in slice) {
          batch.set(col.doc(e.key), e.value, SetOptions(merge: true));
          written++;
        }
        await batch.commit();
      }
      return ExternalListingsSyncOutcome(
        written: written,
        liveWritten: written,
        demoWritten: 0,
        usedDemoFallback: false,
      );
    }

    // Canlı çekim boş: Market Pulse’un boş kalmaması için aynı akışta örnek ilan yaz.
    final demoN = await seedDemoListings();
    return ExternalListingsSyncOutcome(
      written: demoN,
      liveWritten: 0,
      demoWritten: demoN,
      usedDemoFallback: true,
    );
  }

  /// Cloudflare yüzünden liste boş kaldığında Market Pulse’u göstermek için örnek kayıtlar (kaynak: `demo`).
  static Future<int> seedDemoListings() async {
    if (kIsWeb) {
      throw UnsupportedError('Örnek yükleme web’de desteklenmiyor.');
    }
    if (Firebase.apps.isEmpty) throw StateError('Firebase başlatılmadı.');
    if (FirebaseAuth.instance.currentUser == null) throw StateError('Oturum gerekli.');
    await FirestoreService.ensureInitialized();

    final settings = await _loadSettings();
    final cityCode = settings.$1;
    final cityName = settings.$2;
    final districtName = settings.$3;

    final col = FirebaseFirestore.instance.collection(AppConstants.colExternalListings);
    final batch = FirebaseFirestore.instance.batch();
    final samples = <Map<String, dynamic>>[
      {
        'source': 'sahibinden',
        'title': 'Geniş Cepheli Satılık Daire',
        'propertyType': 'Konut',
        'district': districtName ?? 'Merkez',
        'price': '4.250.000 ₺',
        'link': 'https://www.sahibinden.com',
      },
      {
        'source': 'emlakjet',
        'title': 'Merkezi Konum 2+1 Daire',
        'propertyType': 'Konut',
        'district': districtName ?? 'Merkez',
        'price': '22.000 ₺',
        'link': 'https://www.emlakjet.com',
      },
      {
        'source': 'hepsiEmlak',
        'title': 'Bahçeli Müstakil Villa',
        'propertyType': 'Villa',
        'district': districtName ?? 'Merkez',
        'price': '12.900.000 ₺',
        'link': 'https://www.hepsiemlak.com',
      },
      {
        'source': 'sahibinden',
        'title': 'Konumlu İmarlı Arsa',
        'propertyType': 'Arsa',
        'district': districtName ?? 'Merkez',
        'price': '3.100.000 ₺',
        'link': 'https://www.sahibinden.com',
      },
      {
        'source': 'hepsiEmlak',
        'title': 'Caddeye Cephe Ticari Ünite',
        'propertyType': 'İşyeri',
        'district': districtName ?? 'Merkez',
        'price': '8.750.000 ₺',
        'link': 'https://www.hepsiemlak.com',
      },
    ];

    var n = 0;
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      final externalId = 'demo_seed_$i';
      final src = (s['source'] as String?)?.trim() ?? 'demo';
      final id = _makeDocId(src, externalId);
      batch.set(
        col.doc(id),
        {
          'source': src,
          'externalId': externalId,
          'title': s['title'],
          'propertyType': s['propertyType'],
          'priceText': s['price'],
          'priceValue': null,
          'cityCode': cityCode,
          'cityName': cityName,
          'districtName': s['district'],
          'link': s['link'],
          'imageUrl': null,
          'postedAt': Timestamp.fromDate(DateTime.now()),
          'roomCount': null,
          'sqm': null,
          'clientFetched': true,
          'clientFetchedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      n++;
    }
    await batch.commit();
    return n;
  }

  static Future<(String, String, String?)> _loadSettings() async {
    final snap = await FirebaseFirestore.instance
        .collection(AppConstants.colAppSettings)
        .doc('listing_display_settings')
        .get();
    final d = snap.data() ?? {};
    final code = _asCityCode(d['cityCode']);
    final name = (d['cityName'] as String?)?.trim().isNotEmpty == true
        ? (d['cityName'] as String).trim()
        : 'Diyarbakır';
    final rawDist = d['districtName'];
    String? district;
    if (rawDist is String && rawDist.trim().isNotEmpty) {
      district = rawDist.trim();
    }
    return (code, name, district);
  }

  /// Firestore’da cityCode bazen sayı (34) olarak tutulur; URL’de string olmalı.
  static String _asCityCode(dynamic v) {
    if (v == null) return '21';
    if (v is int) return v.toString();
    if (v is double) return v.round().toString();
    if (v is num) return v.round().toString();
    final s = v.toString().trim();
    if (s.isEmpty) return '21';
    return s;
  }

  static double? _parsePrice(String? text) {
    if (text == null || text.isEmpty) return null;
    final cleaned = text.replaceAll(RegExp(r'[^\d,.]'), '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  static String _slug(String cityName) {
    var s = cityName.toLowerCase().trim();
    const tr = {
      'ğ': 'g',
      'ü': 'u',
      'ş': 's',
      'ı': 'i',
      'ö': 'o',
      'ç': 'c',
    };
    for (final e in tr.entries) {
      s = s.replaceAll(e.key, e.value);
    }
    return s.replaceAll(RegExp(r'\s+'), '-');
  }

  static String _makeDocId(String source, String externalId) {
    return '${source}_$externalId'.replaceAll(RegExp(r'[/.#]'), '_');
  }

  static Future<String> _getHtml(String url, {String? referer}) async {
    final uri = Uri.parse(url);
    final host = uri.host;
    final res = await http
        .get(
          uri,
          headers: {
            'User-Agent': _uaChrome,
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
            'Cache-Control': 'no-cache',
            'Upgrade-Insecure-Requests': '1',
            'Referer': referer ?? 'https://$host/',
          },
        )
        .timeout(_timeout);
    final body = res.body;
    if (kDebugMode && _isCloudflareChallenge(body)) {
      debugPrint('ClientExternalListingsSync: Cloudflare sayfası — $url');
    }
    if (res.statusCode >= 400) {
      throw Exception('HTTP ${res.statusCode}');
    }
    if (body.length < 800 && kDebugMode) {
      debugPrint(
        'ClientExternalListingsSync: kısa yanıt (${body.length} bayt) — $url',
      );
    }
    return body;
  }

  /// DOM seçicileri değişince: ham HTML’deki ilan URL’lerini topla.
  static List<_ParsedRow> _sahibindenRegexRows(
    String html,
    String cityCode,
    String cityName,
    String? districtName, {
    required int maxItems,
  }) {
    final seen = <String>{};
    final out = <_ParsedRow>[];
    final abs = RegExp(
      r'https?://www\.sahibinden\.com/ilan/[^"\s<>\?]+',
      caseSensitive: false,
    );
    final hrefRel = RegExp(
      r'''href=["']([^"']*?/ilan/[^"']+)["']''',
      caseSensitive: false,
    );
    void addFromUrl(String raw) {
      var u = raw.trim();
      if (u.startsWith('//')) u = 'https:$u';
      if (u.startsWith('/')) u = 'https://www.sahibinden.com$u';
      if (!u.contains('sahibinden.com/ilan/')) return;
      if (!seen.add(u)) return;
      final idMatch = RegExp(r'/ilan/([^/?]+)').firstMatch(u);
      final externalId = idMatch?.group(1) ?? 'sb-${u.hashCode}';
      final title = _titleFromSahibindenSlug(externalId);
      out.add(
        _ParsedRow(
          docId: _makeDocId('sahibinden', externalId),
          source: 'sahibinden',
          externalId: externalId,
          title: title,
          cityCode: cityCode,
          cityName: cityName,
          districtName: districtName,
          link: u,
          postedAt: DateTime.now(),
        ),
      );
    }

    for (final m in abs.allMatches(html)) {
      addFromUrl(m.group(0)!);
      if (out.length >= maxItems) return out;
    }
    for (final m in hrefRel.allMatches(html)) {
      final g = m.group(1);
      if (g != null) addFromUrl(g);
      if (out.length >= maxItems) return out;
    }
    return out;
  }

  static String _titleFromSahibindenSlug(String slug) {
    if (slug.length < 4) return 'İlan';
    final spaced = slug.replaceAll('-', ' ');
    if (spaced.length <= 200) return spaced;
    return '${spaced.substring(0, 197)}…';
  }

  static List<_ParsedRow> _genericRegexRows({
    required String html,
    required String source,
    required RegExp absolutePattern,
    required String cityCode,
    required String cityName,
    String? districtName,
    required int maxItems,
  }) {
    final seen = <String>{};
    final out = <_ParsedRow>[];
    for (final m in absolutePattern.allMatches(html)) {
      final u = m.group(0)!.trim();
      if (!seen.add(u)) continue;
      final parts = u.split('/').where((s) => s.isNotEmpty).toList();
      final externalId =
          parts.isNotEmpty ? parts.last : 'x-${u.hashCode.abs()}';
      out.add(
        _ParsedRow(
          docId: _makeDocId(source, externalId),
          source: source,
          externalId: externalId,
          title: 'İlan',
          cityCode: cityCode,
          cityName: cityName,
          districtName: districtName,
          link: u,
          postedAt: DateTime.now(),
        ),
      );
      if (out.length >= maxItems) break;
    }
    return out;
  }

  static Future<List<_ParsedRow>> _fetchSahibinden(
    String cityCode,
    String cityName,
    String? districtName,
  ) async {
    final out = <_ParsedRow>[];
    try {
      final url =
          'https://www.sahibinden.com/emlak-konut?a24=$cityCode&p=1';
      final html = await _getHtml(url, referer: 'https://www.sahibinden.com/');
      final doc = html_parser.parse(html);

      for (final el in doc.querySelectorAll(
        '.searchResultsItem, .searchResultsItemClassified, [data-id]',
      )) {
        final linkEl = el.querySelector("a[href*='/ilan/']");
        final href = linkEl?.attributes['href'];
        if (href == null || href.isEmpty) continue;
        final fullLink = href.startsWith('http')
            ? href
            : 'https://www.sahibinden.com$href';
        final title = (linkEl!.text.trim().isNotEmpty)
            ? linkEl.text.trim()
            : (el.querySelector('.classifiedTitle')?.text.trim() ?? 'İlan');
        final priceText = el
                .querySelector('.classifiedsPrice, .searchResultsPriceValue')
                ?.text
                .trim() ??
            '';
        final idMatch = RegExp(r'/ilan/([^/?]+)').firstMatch(fullLink);
        final externalId =
            idMatch?.group(1) ?? 'sb-${DateTime.now().millisecondsSinceEpoch}';
        final imgEl = el.querySelector('img[data-src]') ?? el.querySelector('img');
        var img = imgEl?.attributes['data-src'] ?? imgEl?.attributes['src'];
        if (img != null && !img.startsWith('http')) img = null;
        String? district;
        for (final loc in el.querySelectorAll(
          '.searchResultsLocationValue, .classifiedLocation',
        )) {
          final t = loc.text.trim();
          if (t.isNotEmpty && t.length < 30) district = t;
        }
        if (districtName != null &&
            district != null &&
            !_districtContains(district, districtName)) {
          continue;
        }
        out.add(
          _ParsedRow(
            docId: _makeDocId('sahibinden', externalId),
            source: 'sahibinden',
            externalId: externalId,
            title: title.length > 200 ? title.substring(0, 200) : title,
            priceText: priceText.isEmpty ? null : priceText,
            priceValue: _parsePrice(priceText),
            cityCode: cityCode,
            cityName: cityName,
            districtName: district ?? districtName,
            link: fullLink,
            imageUrl: img,
            postedAt: DateTime.now(),
          ),
        );
      }

      if (out.isEmpty) {
        for (final el in doc.querySelectorAll('tr[data-id]')) {
          final dataId = el.attributes['data-id'];
          final linkEl = el.querySelector("a[href*='/ilan/']");
          final href = linkEl?.attributes['href'];
          if (dataId == null || href == null) continue;
          final fullLink = href.startsWith('http')
              ? href
              : 'https://www.sahibinden.com$href';
          final title = linkEl!.text.trim().isEmpty
              ? 'İlan'
              : linkEl.text.trim();
          final priceText =
              el.querySelector('.searchResultsPriceValue')?.text.trim() ?? '';
          out.add(
            _ParsedRow(
              docId: _makeDocId('sahibinden', dataId),
              source: 'sahibinden',
              externalId: dataId,
              title: title.length > 200 ? title.substring(0, 200) : title,
              priceText: priceText.isEmpty ? null : priceText,
              priceValue: _parsePrice(priceText),
              cityCode: cityCode,
              cityName: cityName,
              districtName: districtName,
              link: fullLink,
              postedAt: DateTime.now(),
            ),
          );
        }
      }
      if (out.isEmpty) {
        out.addAll(
          _sahibindenRegexRows(
            html,
            cityCode,
            cityName,
            districtName,
            maxItems: 30,
          ),
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ClientExternalListingsSync sahibinden: $e\n$st');
      }
    }
    return out.length > 30 ? out.sublist(0, 30) : out;
  }

  /// İlçe filtresi: büyük/küçük harf; basit Türkçe harf eşlemesi.
  static bool _districtContains(String text, String needle) {
    final a = text.toLowerCase();
    final b = needle.toLowerCase();
    if (a.contains(b)) return true;
    return a.replaceAll('ı', 'i').contains(b.replaceAll('ı', 'i'));
  }

  static Future<List<_ParsedRow>> _fetchEmlakjet(
    String cityCode,
    String cityName,
    String? districtName,
  ) async {
    final out = <_ParsedRow>[];
    try {
      final slug = _slug(cityName);
      final url = 'https://www.emlakjet.com/satilik-konut/$slug/';
      final html = await _getHtml(url, referer: 'https://www.emlakjet.com/');
      final doc = html_parser.parse(html);
      for (final el in doc.querySelectorAll(
        "[data-listings] a[href*='/ilan/'], .listing-card a, .property-card a",
      )) {
        final href = el.attributes['href'];
        if (href == null) continue;
        final fullLink = href.startsWith('http')
            ? href
            : 'https://www.emlakjet.com$href';
        var title = el.querySelector('h2, h3, .title, .listing-title')?.text.trim();
        title ??= el.text.trim();
        if (title.length > 200) title = title.substring(0, 200);
        final priceText =
            el.querySelector('.price, .listing-price')?.text.trim() ?? '';
        final parts = fullLink.split('/').where((s) => s.isNotEmpty).toList();
        final externalId = parts.isNotEmpty ? parts.last : 'ej-${DateTime.now().millisecondsSinceEpoch}';
        final img = el.querySelector('img')?.attributes['src'];
        out.add(
          _ParsedRow(
            docId: _makeDocId('emlakjet', externalId),
            source: 'emlakjet',
            externalId: externalId,
            title: title,
            priceText: priceText.isEmpty ? null : priceText,
            priceValue: _parsePrice(priceText),
            cityCode: cityCode,
            cityName: cityName,
            districtName: districtName,
            link: fullLink,
            imageUrl: img,
            postedAt: DateTime.now(),
          ),
        );
      }
      if (out.isEmpty) {
        out.addAll(
          _genericRegexRows(
            html: html,
            source: 'emlakjet',
            absolutePattern: RegExp(
              r'https?://(?:www\.)?emlakjet\.com[^"\s<>]*ilan[^"\s<>]+',
              caseSensitive: false,
            ),
            cityCode: cityCode,
            cityName: cityName,
            districtName: districtName,
            maxItems: 30,
          ),
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ClientExternalListingsSync emlakjet: $e\n$st');
      }
    }
    return out.length > 30 ? out.sublist(0, 30) : out;
  }

  static Future<List<_ParsedRow>> _fetchHepsiEmlak(
    String cityCode,
    String cityName,
    String? districtName,
  ) async {
    final out = <_ParsedRow>[];
    try {
      const baseUrl = 'https://www.hepsiemlak.com';
      final slug = _slug(cityName);
      final url = '$baseUrl/satilik/$slug';
      final html = await _getHtml(url, referer: '$baseUrl/');
      final doc = html_parser.parse(html);
      for (final el in doc.querySelectorAll("a[href*='/ilan/'], .listing a, .card a")) {
        final href = el.attributes['href'];
        if (href == null) continue;
        final fullLink =
            href.startsWith('http') ? href : '$baseUrl$href';
        var title = el.querySelector('h2, h3, .title')?.text.trim();
        title ??= el.text.trim();
        if (title.length > 200) title = title.substring(0, 200);
        final priceText = el.querySelector('.price')?.text.trim() ?? '';
        final parts = fullLink.split('/').where((s) => s.isNotEmpty).toList();
        final externalId = parts.isNotEmpty ? parts.last : 'he-${DateTime.now().millisecondsSinceEpoch}';
        final img = el.querySelector('img')?.attributes['src'];
        out.add(
          _ParsedRow(
            docId: _makeDocId('hepsiEmlak', externalId),
            source: 'hepsiEmlak',
            externalId: externalId,
            title: title,
            priceText: priceText.isEmpty ? null : priceText,
            priceValue: _parsePrice(priceText),
            cityCode: cityCode,
            cityName: cityName,
            districtName: districtName,
            link: fullLink,
            imageUrl: img,
            postedAt: DateTime.now(),
          ),
        );
      }
      if (out.isEmpty) {
        out.addAll(
          _genericRegexRows(
            html: html,
            source: 'hepsiEmlak',
            absolutePattern: RegExp(
              r'https?://(?:www\.)?hepsiemlak\.com[^"\s<>]*ilan[^"\s<>]+',
              caseSensitive: false,
            ),
            cityCode: cityCode,
            cityName: cityName,
            districtName: districtName,
            maxItems: 20,
          ),
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ClientExternalListingsSync hepsiEmlak: $e\n$st');
      }
    }
    return out.length > 20 ? out.sublist(0, 20) : out;
  }
}

class _ParsedRow {
  _ParsedRow({
    required this.docId,
    required this.source,
    required this.externalId,
    required this.title,
    required this.cityCode,
    required this.cityName,
    this.districtName,
    this.priceText,
    this.priceValue,
    required this.link,
    this.imageUrl,
    required this.postedAt,
  });

  final String docId;
  final String source;
  final String externalId;
  final String title;
  final String cityCode;
  final String cityName;
  final String? districtName;
  final String? priceText;
  final double? priceValue;
  final String link;
  final String? imageUrl;
  final DateTime postedAt;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'source': source,
      'externalId': externalId,
      'title': title,
      'priceText': priceText,
      'priceValue': priceValue,
      'cityCode': cityCode,
      'cityName': cityName,
      'districtName': districtName,
      'link': link,
      'imageUrl': imageUrl,
      'postedAt': Timestamp.fromDate(postedAt),
      'roomCount': null,
      'sqm': null,
      'clientFetched': true,
      'clientFetchedAt': FieldValue.serverTimestamp(),
    };
  }
}
