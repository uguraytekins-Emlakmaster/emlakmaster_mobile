import 'package:emlakmaster_mobile/core/navigation/tab_history_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TabHistoryController', () {
    test('recordVisit pushes previous tab and pop returns it', () {
      final history = TabHistoryController(initialIndex: 0);
      history.recordVisit(1);
      history.recordVisit(2);
      expect(history.popTab(), 1);
      expect(history.popTab(), 0);
      expect(history.popTab(), isNull);
    });

    test('same tab visit is ignored', () {
      final history = TabHistoryController(initialIndex: 0);
      history.recordVisit(0);
      expect(history.canPopTab, isFalse);
    });

    test('jumpWithoutHistory does not add stack entry', () {
      final history = TabHistoryController(initialIndex: 0);
      history.recordVisit(1);
      history.jumpWithoutHistory(2);
      expect(history.popTab(), 0);
      expect(history.currentIndex, 0);
    });
  });
}
