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

  /// Tek seferlik fetch (önbelleği günceller).
  static Future<FinanceRates> fetchLiveRates() async {
    try {
      final fxResp = await http.get(Uri.parse(_fxUrl));
      if (fxResp.statusCode != 200) {
        throw Exception('FX HTTP ${fxResp.statusCode}');
      }
      final fxJson = jsonDecode(fxResp.body) as Map<String, dynamic>;
      final fxRates = fxJson['rates'] as Map<String, dynamic>;

      final usdTry = (fxRates['TRY'] as num).toDouble();
      final eurTry = (fxRates['EUR'] as num).toDouble();

      double gramGoldTry = 0;
      try {
        final goldResp = await http.get(Uri.parse(_goldUrl));
        if (goldResp.statusCode == 200) {
          final goldJson = jsonDecode(goldResp.body) as Map<String, dynamic>;
          final goldRates = goldJson['rates'] as Map<String, dynamic>;
          final xauTry = (goldRates['TRY'] as num).toDouble();
          gramGoldTry = xauTry / 31.1035;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Gold price fetch error: $e');
      }

      return FinanceRates(
        usdTry: usdTry,
        eurTry: eurTry,
        gramGoldTry: gramGoldTry > 0 ? gramGoldTry : 0,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('FinanceService.fetchLiveRates error: $e');
      rethrow;
    }
  }
}
