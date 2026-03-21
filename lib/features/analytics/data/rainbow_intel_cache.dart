import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Mahalle / ilçe ortalama m² fiyatları — API yokken yerel önbellek.
abstract final class RainbowIntelCache {
  RainbowIntelCache._();

  static const _keyDistrictAvg = 'rainbow_intel_district_avg_m2';

  static Future<Map<String, double>> _readMap() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_keyDistrictAvg);
    if (raw == null || raw.isEmpty) return _defaults();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return _defaults();
    }
  }

  static Map<String, double> _defaults() => {
        'Bağlar': 42000,
        'Kayapınar': 48000,
        'Sur': 45000,
        'Yenişehir': 52000,
        'Bismil': 28000,
        'Çınar': 26000,
        'Ergani': 30000,
        'Silvan': 24000,
        'Kocaköy': 22000,
        'Çüngüş': 20000,
        'Genel': 40000,
      };

  static Future<double> avgPricePerM2ForDistrict(String district) async {
    final map = await _readMap();
    final key = district.trim().isEmpty ? 'Genel' : district.trim();
    return map[key] ?? map['Genel'] ?? 40000;
  }

  static Future<void> mergeDistrictAvg(Map<String, double> partial) async {
    final cur = await _readMap();
    cur.addAll(partial);
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _keyDistrictAvg,
      jsonEncode(cur.map((k, v) => MapEntry(k, v))),
    );
  }
}
