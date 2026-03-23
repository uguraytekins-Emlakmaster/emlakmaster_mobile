import 'dart:async';
import 'dart:convert';

import 'package:emlakmaster_mobile/core/services/finance_rates_math.dart';
import 'package:emlakmaster_mobile/core/services/tcmb_public_rates.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FinanceRates {
  final double usdTry;
  final double eurTry;
  final double gramGoldTry;
  final DateTime updatedAt;

  /// `yahoo-node` (mini Node servisi), `TCMB` (resmi XML) veya `exchangerate.host` yedek.
  final String dataSource;

  const FinanceRates({
    required this.usdTry,
    required this.eurTry,
    required this.gramGoldTry,
    required this.updatedAt,
    this.dataSource = 'exchangerate.host',
  });
}

/// Cache-first finans servisi: önce önbellek döner (milisaniye), arka planda güncelleme.
class FinanceService {
  static const String _fxUrl =
      'https://api.exchangerate.host/latest?base=USD&symbols=TRY,EUR';
  static const String _goldUrl =
      'https://api.exchangerate.host/latest?base=XAU&symbols=TRY';

  /// `tools/yahoo_finance_service` — Node + yahoo-finance2 mini API.
  /// Boşsa bu kaynak atlanır.
  static const String _yahooNodeServiceUrl =
      String.fromEnvironment('YAHOO_FINANCE_SERVICE_URL');
  static const String _yahooNodeApiKey =
      String.fromEnvironment('YAHOO_FINANCE_SERVICE_API_KEY');

  static FinanceRates? _cache;
  static FinanceRates? _previousRates;
  static const Duration _refreshInterval = Duration(minutes: 5);

  /// Son güncellemelerden biriken fiyat serisi (sparkline / volatilite görünümü için).
  static const int _maxHistoryPoints = 48;
  static final List<double> _historyUsdTry = <double>[];
  static final List<double> _historyEurTry = <double>[];
  static final List<double> _historyGramGoldTry = <double>[];

  static void _appendHistory(FinanceRates r) {
    if (r.usdTry > 0) {
      _historyUsdTry.add(r.usdTry);
      while (_historyUsdTry.length > _maxHistoryPoints) {
        _historyUsdTry.removeAt(0);
      }
    }
    if (r.eurTry > 0) {
      _historyEurTry.add(r.eurTry);
      while (_historyEurTry.length > _maxHistoryPoints) {
        _historyEurTry.removeAt(0);
      }
    }
    if (r.gramGoldTry > 0) {
      _historyGramGoldTry.add(r.gramGoldTry);
      while (_historyGramGoldTry.length > _maxHistoryPoints) {
        _historyGramGoldTry.removeAt(0);
      }
    }
  }

  /// Sparkline için normalize edilmemiş fiyat noktaları (en az 2 nokta).
  static List<double> sparklineUsdTry(double fallback) =>
      _seriesForSparkline(_historyUsdTry, fallback);

  static List<double> sparklineEurTry(double fallback) =>
      _seriesForSparkline(_historyEurTry, fallback);

  static List<double> sparklineGramGoldTry(double fallback) =>
      _seriesForSparkline(_historyGramGoldTry, fallback);

  static List<double> _seriesForSparkline(List<double> h, double fallback) {
    if (h.length >= 2) return List<double>.from(h);
    if (h.length == 1) {
      final v = h[0];
      return <double>[v * 0.9985, v * 1.0004, v];
    }
    if (fallback > 0) {
      return List<double>.generate(
        12,
        (i) => fallback * (1 + (i - 5.5) * 0.00035),
      );
    }
    return <double>[1, 1.001];
  }

  /// Son seri penceresine göre yüzde değişim (sparkline penceresi ≈ oturum içi birikim).
  static double pctChangeFromHistory(List<double> series) {
    if (series.length < 2) return 0;
    final a = series.first;
    final b = series.last;
    if (a <= 0) return 0;
    return (b - a) / a * 100;
  }

  /// Önceki örnekle anlık tick değişimi (seri kısaysa).
  static double pctChangeTick({
    required double current,
    required double? previous,
  }) {
    if (previous == null || previous <= 0) return 0;
    return (current - previous) / previous * 100;
  }

  /// Az sayıda örnek noktayı çizim için daha sık noktalara yayar (mikro grafik akıcılığı).
  static List<double> densifySeries(List<double> h, {int targetPoints = 28}) {
    if (h.length >= targetPoints) return h.sublist(h.length - targetPoints);
    if (h.length < 2) return h;
    final out = <double>[];
    final max = targetPoints;
    final seg = h.length - 1;
    for (var i = 0; i < max; i++) {
      final t = seg > 0 ? i / (max - 1) * seg : 0.0;
      final i0 = t.floor().clamp(0, h.length - 2);
      final f = t - i0;
      out.add(h[i0] * (1 - f) + h[i0 + 1] * f);
    }
    return out;
  }

  /// Önbellekte varsa anında döner; yoksa null (UI placeholder gösterir).
  /// Önbellekte varsa anında döner (milisaniye).
  static FinanceRates? getCached() => _cache;

  static FinanceRates? get previousRates => _previousRates;

  static Stream<FinanceRates>? _ratesStream;

  /// Cache-first stream (tek örnek, broadcast): birden fazla dinleyici güvenle bağlanabilir.
  static Stream<FinanceRates> get ratesStream {
    _ratesStream ??= _createRatesStream().asBroadcastStream();
    return _ratesStream!;
  }

  static Stream<FinanceRates> _createRatesStream() async* {
    if (_cache != null) {
      yield _cache!;
    }
    while (true) {
      try {
        final r = await fetchLiveRates();
        _previousRates = _cache;
        _cache = r;
        _appendHistory(r);
        yield r;
      } catch (e) {
        if (kDebugMode) debugPrint('FinanceService stream error: $e');
        if (_cache != null) yield _cache!;
      }
      await Future<void>.delayed(_refreshInterval);
    }
  }

  /// Öncelik: **Yahoo Node servisi** (`YAHOO_FINANCE_SERVICE_URL` tanımlıysa) → **TCMB** → **exchangerate.host**.
  static Future<FinanceRates> fetchLiveRates() async {
    final yahoo = await _fetchFromYahooNodeService();
    if (yahoo != null) return yahoo;

    try {
      final tcmb = await TcmbPublicRates.fetchToday();
      if (tcmb != null && tcmb.usdTry > 0 && tcmb.eurTry > 0) {
        var gram = tcmb.gramGoldTry;
        if (gram == null || gram <= 0) {
          gram = await _fetchGramGoldExchangerate();
        }
        return FinanceRates(
          usdTry: tcmb.usdTry,
          eurTry: tcmb.eurTry,
          gramGoldTry: gram > 0 ? gram : (_cache?.gramGoldTry ?? 0),
          updatedAt: DateTime.now(),
          dataSource: 'TCMB',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('FinanceService TCMB: $e');
    }
    return _fetchFromExchangerateHost();
  }

  /// Node `yahoo-finance2` mini-servisi (`GET /rates`).
  static Future<FinanceRates?> _fetchFromYahooNodeService() async {
    final base = _yahooNodeServiceUrl.trim();
    if (base.isEmpty) return null;
    try {
      final normalized = base.endsWith('/') ? base : '$base/';
      final uri = Uri.parse('${normalized}rates');
      final headers = <String, String>{
        'Accept': 'application/json',
        if (_yahooNodeApiKey.trim().isNotEmpty)
          'X-API-Key': _yahooNodeApiKey.trim(),
      };
      final resp = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return null;
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['ok'] != true) return null;
      final usd = decoded['usdTry'];
      final eur = decoded['eurTry'];
      final gram = decoded['gramGoldTry'];
      if (usd is! num || eur is! num) return null;
      final u = usd.toDouble();
      final e = eur.toDouble();
      if (u <= 0 || e <= 0) return null;
      final g = gram is num ? gram.toDouble() : 0.0;
      var updatedAt = DateTime.now();
      final ts = decoded['updatedAt'];
      if (ts is String) {
        try {
          updatedAt = DateTime.parse(ts);
        } catch (_) {}
      }
      return FinanceRates(
        usdTry: u,
        eurTry: e,
        gramGoldTry: g > 0 ? g : (_cache?.gramGoldTry ?? 0),
        updatedAt: updatedAt,
        dataSource: 'yahoo-node',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('FinanceService yahoo-node: $e');
      return null;
    }
  }

  static Future<double> _fetchGramGoldExchangerate() async {
    try {
      final goldResp = await http.get(Uri.parse(_goldUrl));
      if (goldResp.statusCode != 200) return 0;
      final goldBody = jsonDecode(goldResp.body);
      final goldJson = goldBody is Map<String, dynamic> ? goldBody : null;
      if (goldJson?['success'] == false) return 0;
      final goldRaw = goldJson?['rates'];
      final goldRates =
          goldRaw is Map ? Map<String, dynamic>.from(goldRaw) : null;
      if (goldRates != null && goldRates['TRY'] is num) {
        final xauTry = (goldRates['TRY'] as num).toDouble();
        return xauTry / 31.1035;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Gold price fetch error: $e');
    }
    return 0;
  }

  /// Ücretsiz exchangerate.host (yalnızca TCMB başarısız veya eksikse).
  ///
  /// Not: `base=USD` iken `rates['EUR']` = EUR başına USD değil; **EUR/TRY** = TRY/USD ÷ EUR/USD.
  static Future<FinanceRates> _fetchFromExchangerateHost() async {
    try {
      final fxResp = await http.get(Uri.parse(_fxUrl));
      if (fxResp.statusCode != 200) {
        throw Exception('FX HTTP ${fxResp.statusCode}');
      }
      final fxBody = jsonDecode(fxResp.body);
      final fxJson = fxBody is Map<String, dynamic> ? fxBody : null;
      final success = fxJson?['success'];
      if (success == false) {
        final err = fxJson?['error'];
        throw Exception('FX API error: $err');
      }
      final rawRates = fxJson?['rates'];
      final fxRates =
          rawRates is Map ? Map<String, dynamic>.from(rawRates) : null;
      if (fxRates == null || fxRates.isEmpty) {
        if (kDebugMode) {
          final snippet = fxResp.body.length > 400
              ? '${fxResp.body.substring(0, 400)}…'
              : fxResp.body;
          debugPrint('FinanceService: FX body (snippet): $snippet');
        }
        throw Exception('FX rates format invalid');
      }

      final tryPerUsd = fxRates['TRY'] is num ? (fxRates['TRY'] as num).toDouble() : null;
      final eurPerUsd = fxRates['EUR'] is num ? (fxRates['EUR'] as num).toDouble() : null;

      final usdTry = tryPerUsd ?? _cache?.usdTry ?? 0.0;
      final eurTry = (tryPerUsd != null && eurPerUsd != null)
          ? eurTryFromUsdBaseRates(tryPerUsd, eurPerUsd)
          : (_cache?.eurTry ?? 0.0);

      final gramGoldTry = await _fetchGramGoldExchangerate();

      return FinanceRates(
        usdTry: usdTry,
        eurTry: eurTry,
        gramGoldTry: gramGoldTry > 0 ? gramGoldTry : (_cache?.gramGoldTry ?? 0),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('FinanceService.fetchLiveRates error: $e');
      if (_cache != null) return _cache!;
      return FinanceRates(
        usdTry: _cache?.usdTry ?? 0,
        eurTry: _cache?.eurTry ?? 0,
        gramGoldTry: _cache?.gramGoldTry ?? 0,
        updatedAt: DateTime.now(),
      );
    }
  }
}
