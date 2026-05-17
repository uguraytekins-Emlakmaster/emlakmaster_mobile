import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/features/contact_save/data/contact_permission_helper.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

/// Rehber satırı — tuş takımı ve üst arama için.
class DialerContactEntry {
  const DialerContactEntry({
    required this.displayName,
    required this.phoneDigits,
    required this.phoneDisplay,
  });

  final String displayName;
  final String phoneDigits;
  final String phoneDisplay;
}

enum DialerContactsLoadResult {
  granted,
  denied,
  permanentlyDenied,
}

/// Rehber izni + telefonlu kişiler (alfabetik).
Future<({DialerContactsLoadResult perm, List<DialerContactEntry> contacts})>
    loadDialerContactDirectory() async {
  final perm =
      await ContactPermissionHelper.instance.requestContactPermission();
  switch (perm) {
    case ContactPermissionResult.permanentlyDenied:
      return (
        perm: DialerContactsLoadResult.permanentlyDenied,
        contacts: <DialerContactEntry>[],
      );
    case ContactPermissionResult.denied:
      return (
        perm: DialerContactsLoadResult.denied,
        contacts: <DialerContactEntry>[],
      );
    case ContactPermissionResult.granted:
      break;
  }

  final raw = await FlutterContacts.getAll(
    properties: {ContactProperty.phone},
  );
  final entries = <DialerContactEntry>[];
  for (final c in raw) {
    if (c.phones.isEmpty) continue;
    final phone = c.phones.first.number;
    final digits = OutboundPhoneDial.digitsOnly(phone);
    if (digits.isEmpty) continue;
    entries.add(
      DialerContactEntry(
        displayName: (c.displayName ?? '').trim(),
        phoneDigits: digits,
        phoneDisplay: phone.trim(),
      ),
    );
  }
  entries.sort(
    (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );
  return (perm: DialerContactsLoadResult.granted, contacts: entries);
}

/// İsim veya numara ile filtre (boş sorgu → boş liste).
List<DialerContactEntry> filterDialerContacts(
  List<DialerContactEntry> all,
  String query,
) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final qLower = q.toLowerCase();
  final qDigits = OutboundPhoneDial.digitsOnly(q);
  return all
      .where((c) {
        if (c.displayName.isNotEmpty &&
            c.displayName.toLowerCase().contains(qLower)) {
          return true;
        }
        if (qDigits.isNotEmpty && c.phoneDigits.contains(qDigits)) {
          return true;
        }
        return c.phoneDisplay.toLowerCase().contains(qLower);
      })
      .take(12)
      .toList();
}
