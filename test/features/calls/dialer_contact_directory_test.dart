import 'package:emlakmaster_mobile/features/calls/presentation/utils/dialer_contact_directory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('filterDialerContacts', () {
    final sample = [
      const DialerContactEntry(
        displayName: 'Ayşe Yılmaz',
        phoneDigits: '5321112233',
        phoneDisplay: '0532 111 22 33',
      ),
      const DialerContactEntry(
        displayName: 'Mehmet Demir',
        phoneDigits: '2125554433',
        phoneDisplay: '0212 555 44 33',
      ),
    ];

    test('empty query returns nothing', () {
      expect(filterDialerContacts(sample, ''), isEmpty);
    });

    test('matches display name', () {
      final r = filterDialerContacts(sample, 'ayşe');
      expect(r, hasLength(1));
      expect(r.first.displayName, 'Ayşe Yılmaz');
    });

    test('matches phone digits', () {
      final r = filterDialerContacts(sample, '212555');
      expect(r, hasLength(1));
      expect(r.first.displayName, 'Mehmet Demir');
    });
  });
}
