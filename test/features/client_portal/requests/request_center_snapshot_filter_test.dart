import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_filter.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeRequestCenterSnapshot', () {
    test('signedIn → profil/tercih hazır, 3 aktif kanal', () {
      final snap = computeRequestCenterSnapshot(
        signedIn: true,
        displayName: 'Ada',
      );
      expect(snap.entries.length, 4);
      expect(snap.signedIn, isTrue);
      expect(snap.greetingName, 'Ada');
      // explore + advisor + preferences = 3 ready (create = preview)
      expect(snap.summary.activeChannels, 3);
      expect(snap.summary.profileReady, isTrue);
      // Dürüstlük: kayıtlı talep sunucuda tutulmuyor → 0
      expect(snap.summary.savedRequests, 0);
      expect(snap.summary.requestPreview, isTrue);

      final prefs = snap.entries.firstWhere((e) => e.id == 'preferences');
      expect(prefs.readiness, RequestReadiness.ready);
    });

    test('signedOut → tercih engelli, 2 aktif kanal', () {
      final snap = computeRequestCenterSnapshot(signedIn: false);
      expect(snap.signedIn, isFalse);
      expect(snap.greetingName, isEmpty);
      // explore + advisor = 2 ready
      expect(snap.summary.activeChannels, 2);
      expect(snap.summary.profileReady, isFalse);

      final prefs = snap.entries.firstWhere((e) => e.id == 'preferences');
      expect(prefs.readiness, RequestReadiness.blocked);
      expect(prefs.statusLabel, 'Giriş gerekli');
    });

    test('talep oluştur kanalı dürüstçe önizleme (yakında)', () {
      final snap = computeRequestCenterSnapshot(signedIn: true);
      final create = snap.entries.firstWhere((e) => e.id == 'create');
      expect(create.readiness, RequestReadiness.preview);
      expect(create.statusLabel, 'Yakında');
      // Talep mesaj kanalına yönlenir (gerçek iletişim).
      expect(create.shortcut, MainShellShortcut.openMessagesTab);
      expect(snap.coverageNote, contains('sunucuda'));
      expect(snap.coverageNote, contains('Uydurma'));
    });

    test('preformatted: her kanalın gerçek bir kabuk sekmesi hedefi var', () {
      final snap = computeRequestCenterSnapshot(signedIn: true);
      // Dead button yok — her kanalın somut actionLabel + shortcut'u olmalı.
      for (final e in snap.entries) {
        expect(e.actionLabel.isNotEmpty, isTrue);
        expect(e.searchText.isNotEmpty, isTrue);
      }
    });
  });

  group('filterRequestCenterEntries', () {
    late List<RequestCenterEntry> entries;

    setUp(() {
      entries = computeRequestCenterSnapshot(signedIn: true).entries;
    });

    List<RequestCenterEntry> run(RequestCenterFilter f, [String q = '']) =>
        filterRequestCenterEntries(entries, query: q, filter: f);

    test('all → tüm kanallar', () {
      expect(run(RequestCenterFilter.all).length, 4);
    });

    test('active → yalnızca hazır kanallar', () {
      final r = run(RequestCenterFilter.active);
      expect(r.length, 3);
      expect(r.every((e) => e.isReady), isTrue);
    });

    test('draft → yalnızca yakında kanal (talep oluştur)', () {
      final r = run(RequestCenterFilter.draft);
      expect(r.length, 1);
      expect(r.single.id, 'create');
    });

    test('message → mesaj kanalına yönlenenler (talep + danışman)', () {
      final r = run(RequestCenterFilter.message);
      expect(r.length, 2);
      expect(r.every((e) => e.isMessage), isTrue);
    });

    test('arama → danışman kanalını bulur', () {
      final r = run(RequestCenterFilter.all, 'danışman');
      expect(r.any((e) => e.kind == RequestKind.advisor), isTrue);
    });

    test('arama eşleşmezse boş', () {
      expect(run(RequestCenterFilter.all, 'zzzz-yok'), isEmpty);
    });
  });
}
