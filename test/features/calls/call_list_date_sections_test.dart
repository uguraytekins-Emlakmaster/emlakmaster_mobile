import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_list_date_sections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('callListSectionLabel uses Bugün and Dün', () {
    final now = DateTime(2026, 5, 16, 14, 30);
    expect(
      callListSectionLabel(DateTime(2026, 5, 16, 9, 0), now: now),
      'Bugün',
    );
    expect(
      callListSectionLabel(DateTime(2026, 5, 15, 9, 0), now: now),
      'Dün',
    );
    expect(
      callListSectionLabel(DateTime(2026, 4, 2, 9, 0), now: now),
      '2 Nisan 2026',
    );
  });

  test('callListTimeLabel formats HH:mm', () {
    expect(
      callListTimeLabel(DateTime(2026, 5, 16, 9, 5)),
      '09:05',
    );
  });
}
