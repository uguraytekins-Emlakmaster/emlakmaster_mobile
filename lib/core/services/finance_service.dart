import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FinanceRates {
  final double usdTry;
  final double eurTry;
  final double gramGoldTry;
  final DateTime updatedAt;

  const FinanceRates({
    required this.usdTry,
    required this.eurTry,
    required this.gramGoldTry,
    required this.updatedAt,
  });
}

/// Cache-first finans servisi: önce önbellek döner (milisaniye), arka planda güncelleme.
class FinanceService {
  static const String _fxUrl =
      'https://api.exchangerate.host/latest?base=USD&symbols=TRY,EUR';
  static const String _goldUrl =
      'https://api.exchangerate.host/latest?base=XAU&symbols=TRY';

  static FinanceRates? _cache;
  static FinanceRates? _previousRates;
  static const Duration _refreshInterval = Duration(minutes: 5);

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
        yield r;
      } catch (e) {
        if (kDebugMode) debugPrint('FinanceService stream error: $e');
        if (_cache != null) yield _cache!;
      }
      await Future<void>.delayed(_refreshInterval);
    }
  }

  /// Tek seferlik fetch (önbelleği günceller). API yanıtı boş/hatalıysa güvenli varsayılan döner.
  static Future<FinanceRates> fetchLiveRates() async {
    try {
      final fxResp = await http.get(Uri.parse(_fxUrl));
      if (fxResp.statusCode != 200) {
        throw Exception('FX HTTP ${fxResp.statusCode}');
      }
      final fxBody = jsonDecode(fxResp.body);
      final fxJson = fxBody is Map<String, dynamic> ? fxBody : null;
      final fxRates = fxJson?['rates'];
      if (fxRates is! Map<String, dynamic>) {
        throw Exception('FX rates format invalid');
      }

      final usdTry = (fxRates['TRY'] is num)
          ? (fxRates['TRY'] as num).toDouble()
          : (_cache?.usdTry ?? 0.0);
      final eurTry = (fxRates['EUR'] is num)
          ? (fxRates['EUR'] as num).toDouble()
          : (_cache?.eurTry ?? 0.0);

      double gramGoldTry = 0;
      try {
        final goldResp = await http.get(Uri.parse(_goldUrl));
        if (goldResp.statusCode == 200) {
          final goldBody = jsonDecode(goldResp.body);
          final goldJson = goldBody is Map<String, dynamic> ? goldBody : null;
          final goldRates = goldJson?['rates'];
          if (goldRates is Map<String, dynamic> && goldRates['TRY'] is num) {
            final xauTry = (goldRates['TRY'] as num).toDouble();
            gramGoldTry = xauTry / 31.1035;
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Gold price fetch error: $e');
      }

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
