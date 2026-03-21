import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/rainbow_intel_models.dart';

const _kHistory = 'rainbow_intel_report_history_v1';
const _maxItems = 40;

class IntelReportHistoryRepository {
  IntelReportHistoryRepository();

  final _uuid = const Uuid();

  Future<List<RainbowIntelReport>> loadAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => RainbowIntelReport.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> save(RainbowIntelReport report) async {
    final all = await loadAll();
    final next = [report, ...all.where((r) => r.id != report.id)];
    final trimmed =
        next.length > _maxItems ? next.sublist(0, _maxItems) : next;
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kHistory,
      jsonEncode(trimmed.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> remove(String id) async {
    final all = await loadAll();
    await _persist(all.where((r) => r.id != id).toList());
  }

  Future<void> _persist(List<RainbowIntelReport> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kHistory,
      jsonEncode(items.map((r) => r.toJson()).toList()),
    );
  }

  String newId() => _uuid.v4();
}
