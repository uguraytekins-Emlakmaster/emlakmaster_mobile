import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_filter.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_types.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2024, 6, 15, 12);

CustomerWorkspaceInput _input({
  String id = 'c1',
  String? name = 'Ada Yılmaz',
  String? phone = '+90 555 111 22 33',
  String? email,
  CustomerHeatLevel heat = CustomerHeatLevel.hot,
  int score = 80,
  String reason = 'Yüksek ilgi',
  DateTime? lastInteractionAt,
  DateTime? createdAt,
  DateTime? updatedAt,
  String? nextAction,
  bool callable = true,
  bool syncRisk = false,
}) =>
    CustomerWorkspaceInput(
      id: id,
      name: name,
      phone: phone,
      email: email,
      heatLevel: heat,
      heatScore: score,
      heatReason: reason,
      lastInteractionAt: lastInteractionAt ?? _now.subtract(const Duration(days: 1)),
      createdAt: createdAt ?? DateTime(2024, 6, 10),
      updatedAt: updatedAt ?? _now.subtract(const Duration(days: 1)),
      nextSuggestedAction: nextAction,
      callablePhone: callable,
      syncRisk: syncRisk,
      isDemo: false,
    );

CustomerRowView _rowById(CustomerWorkspaceSnapshot s, String id) =>
    s.rows.firstWhere((r) => r.id == id);

void main() {
  group('computeCustomerWorkspaceSnapshot — gerçek CRM sinyalleri', () {
    test('summary yalnızca gerçek sayımları döndürür', () {
      final snap = computeCustomerWorkspaceSnapshot(
        [
          _input(id: 'hot1', heat: CustomerHeatLevel.hot),
          _input(
            id: 'stale1',
            heat: CustomerHeatLevel.cold,
            score: 10,
            lastInteractionAt: _now.subtract(const Duration(days: 20)),
            updatedAt: _now.subtract(const Duration(days: 20)),
          ),
          _input(
            id: 'partial1',
            name: '',
            phone: null,
            email: null,
            callable: false,
            heat: CustomerHeatLevel.cold,
            score: 5,
          ),
        ],
        now: _now,
      );
      expect(snap.summary.active, 3);
      expect(snap.summary.hot, 1);
      expect(snap.summary.needsContact, 1);
      expect(snap.summary.partial, 1);
    });

    test('sıcaklık etiketi kural tabanlı (LLM değil) — coverageNote dürüst', () {
      final snap = computeCustomerWorkspaceSnapshot([_input()], now: _now);
      expect(_rowById(snap, 'c1').heatLabel, 'Sıcak');
      expect(snap.coverageNote, contains('yapay zekâ değil'));
      expect(snap.coverageNote, contains('SLA'));
    });

    test('eksik alan uydurulmaz — kısmi işaretlenir', () {
      final snap = computeCustomerWorkspaceSnapshot(
        [_input(name: '', phone: null, email: null, callable: false)],
        now: _now,
      );
      final row = _rowById(snap, 'c1');
      expect(row.name, 'İsimsiz kayıt');
      expect(row.contactLine, 'İletişim bilgisi eksik');
      expect(row.isPartial, isTrue);
      expect(row.partialNote, contains('ad'));
    });

    test('needsContact ≥14 gün aktivite yoksa (dürüst proxy)', () {
      final snap = computeCustomerWorkspaceSnapshot(
        [
          _input(
            id: 'old',
            lastInteractionAt: _now.subtract(const Duration(days: 15)),
            updatedAt: _now.subtract(const Duration(days: 15)),
          ),
        ],
        now: _now,
      );
      expect(_rowById(snap, 'old').needsContact, isTrue);
    });

    test('isToday bugünkü aktivite', () {
      final snap = computeCustomerWorkspaceSnapshot(
        [_input(lastInteractionAt: _now)],
        now: _now,
      );
      expect(_rowById(snap, 'c1').isToday, isTrue);
      expect(snap.summary.today, 1);
    });

    test('syncRisk öncelik sıralamasında üstte', () {
      final snap = computeCustomerWorkspaceSnapshot(
        [
          _input(id: 'warm', heat: CustomerHeatLevel.warm, score: 50),
          _input(id: 'risk', syncRisk: true, heat: CustomerHeatLevel.cold),
        ],
        now: _now,
      );
      expect(snap.rows.first.id, 'risk');
    });
  });

  group('filterCustomerWorkspaceRows', () {
    late CustomerWorkspaceSnapshot snap;

    setUp(() {
      snap = computeCustomerWorkspaceSnapshot(
        [
          _input(id: 'hot', heat: CustomerHeatLevel.hot),
          _input(id: 'warm', heat: CustomerHeatLevel.warm, score: 55),
          _input(
            id: 'cold',
            heat: CustomerHeatLevel.cold,
            lastInteractionAt: _now.subtract(const Duration(days: 30)),
            updatedAt: _now.subtract(const Duration(days: 30)),
          ),
          _input(
            id: 'today',
            heat: CustomerHeatLevel.warm,
            score: 50,
            lastInteractionAt: _now,
            updatedAt: _now,
          ),
          _input(
            id: 'fresh',
            heat: CustomerHeatLevel.cool,
            score: 30,
            createdAt: _now.subtract(const Duration(days: 2)),
          ),
          _input(
            id: 'partial',
            name: '',
            phone: null,
            callable: false,
            heat: CustomerHeatLevel.cold,
            score: 5,
          ),
        ],
        now: _now,
      );
    });

    test('Tümü tüm satırları döndürür', () {
      expect(filterCustomerWorkspaceRows(snap.rows).length, snap.rows.length);
    });

    test('Sıcak yalnızca hot band', () {
      final hot = filterCustomerWorkspaceRows(
        snap.rows,
        filter: CustomerWorkspaceFilter.hot,
      );
      expect(hot.map((r) => r.id), ['hot']);
    });

    test('Temas gerekli yalnızca stale kayıtlar', () {
      final stale = filterCustomerWorkspaceRows(
        snap.rows,
        filter: CustomerWorkspaceFilter.needsContact,
      );
      expect(stale.every((r) => r.needsContact), isTrue);
      expect(stale.map((r) => r.id), contains('cold'));
    });

    test('Kısmi yalnızca eksik kayıtlar', () {
      final partial = filterCustomerWorkspaceRows(
        snap.rows,
        filter: CustomerWorkspaceFilter.partial,
      );
      expect(partial.map((r) => r.id), ['partial']);
    });

    test('arama searchText üzerinde çalışır', () {
      final found = filterCustomerWorkspaceRows(
        snap.rows,
        query: 'ada',
      );
      expect(found, isNotEmpty);
      expect(found.every((r) => r.searchText.contains('ada')), isTrue);
    });
  });
}
