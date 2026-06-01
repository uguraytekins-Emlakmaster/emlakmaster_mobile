import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_types.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2024, 6, 15, 12);

CustomerEntity _entity({
  String id = 'c1',
  String? name,
  String? phone,
  String? email,
  DateTime? lastInteractionAt,
  int callsCount = 0,
}) {
  return CustomerEntity(
    id: id,
    fullName: name ?? 'Ahmet Yılmaz',
    primaryPhone: phone ?? '+905551111111',
    email: email,
    lastInteractionAt: lastInteractionAt,
    callsCount: callsCount,
    createdAt: _now.subtract(const Duration(days: 30)),
    updatedAt: _now,
  );
}

CustomerDetailWorkspaceInput _input({
  CustomerEntity? entity,
  List<CustomerDetailLinkedRow> tasks = const [],
  List<CustomerDetailListingRow> listings = const [],
}) =>
    CustomerDetailWorkspaceInput(
      customerId: 'c1',
      entity: entity,
      openTasks: tasks,
      matchedListings: listings,
      now: _now,
    );

void main() {
  group('computeCustomerDetailWorkspaceSnapshot', () {
    test('summary gerçek sayımlar', () {
      final snap = computeCustomerDetailWorkspaceSnapshot(
        _input(
          entity: _entity(
            lastInteractionAt: _now.subtract(const Duration(days: 10)),
            callsCount: 3,
          ),
          tasks: const [
            CustomerDetailLinkedRow(
              id: 't1',
              title: 'Geri ara',
              statusLabel: 'Bugün',
            ),
          ],
          listings: const [
            CustomerDetailListingRow(listingId: 'l1', title: 'Daire'),
          ],
        ),
      );
      expect(snap.summary.activeTasks, 1);
      expect(snap.summary.activeFollowUp, 1);
      expect(snap.summary.callRelation, 3);
      expect(snap.summary.portfolioCount, 1);
    });

    test('kısmi — iletişim eksik', () {
      final snap = computeCustomerDetailWorkspaceSnapshot(
        _input(entity: _entity(name: '', phone: null, email: null)),
      );
      expect(snap.isPartial, isTrue);
      expect(snap.partialNote, contains('Eksik'));
    });

    test('coverageNote dürüst — AI skor yok', () {
      final snap = computeCustomerDetailWorkspaceSnapshot(
        _input(entity: _entity()),
      );
      expect(snap.coverageNote, contains('AI'));
      expect(snap.coverageNote, contains('skor'));
    });

    test('portföy — skor gösterilmez', () {
      final snap = computeCustomerDetailWorkspaceSnapshot(
        _input(
          entity: _entity(),
          listings: const [
            CustomerDetailListingRow(listingId: 'l1', title: 'Villa'),
          ],
        ),
      );
      final portfolio = snap.sections
          .firstWhere((s) => s.kind == CustomerDetailSectionKind.portfolio);
      expect(portfolio.listings.single.title, 'Villa');
      expect(portfolio.note, contains('skor'));
    });

    test('not found', () {
      final snap = computeCustomerDetailWorkspaceSnapshot(
        _input(entity: null),
      );
      expect(snap.isNotFound, isTrue);
    });
  });
}
