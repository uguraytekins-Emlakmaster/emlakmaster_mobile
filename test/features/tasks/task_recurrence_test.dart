import 'package:emlakmaster_mobile/features/tasks/domain/task_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('taskRecurrenceLabel maps known codes', () {
    expect(taskRecurrenceLabel('weekly'), 'Her hafta');
    expect(taskRecurrenceLabel(null), isNull);
  });

  test('nextDueForRecurrence advances weekly', () {
    final from = DateTime(2026, 3, 10);
    final next = nextDueForRecurrence(from, 'weekly');
    expect(next, DateTime(2026, 3, 17));
  });
}
