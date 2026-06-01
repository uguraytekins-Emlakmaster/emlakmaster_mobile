import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_filter.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_types.dart';
import 'package:flutter_test/flutter_test.dart';

AccountSnapshot _signedIn({
  String? email = 'musteri@example.com',
  String? name = 'Ada Yılmaz',
  String? phone = '+90 555 111 22 33',
  String? memberSince = '15.01.2024',
  bool verified = true,
}) =>
    computeAccountSnapshot(
      signedIn: true,
      email: email,
      displayName: name,
      phone: phone,
      memberSinceLabel: memberSince,
      emailVerified: verified,
      appVersion: '1.0.0',
    );

AccountSnapshot _signedOut() => computeAccountSnapshot(
      signedIn: false,
      emailVerified: false,
      appVersion: '1.0.0',
    );

AccountEntry _byId(AccountSnapshot s, String id) =>
    s.entries.firstWhere((e) => e.id == id);

void main() {
  group('computeAccountSnapshot — gerçek hesap verisi', () {
    test('signedIn: gerçek e-posta/ad/üyelik + çıkış satırı', () {
      final s = _signedIn();
      expect(s.signedIn, isTrue);
      expect(s.email, 'musteri@example.com');
      expect(s.greetingName, 'Ada Yılmaz');
      expect(s.avatarLetter, 'M');

      expect(_byId(s, 'email').value, 'musteri@example.com');
      expect(_byId(s, 'email').readiness, AccountReadiness.ready);
      expect(_byId(s, 'name').value, 'Ada Yılmaz');
      expect(_byId(s, 'phone').value, '+90 555 111 22 33');
      expect(_byId(s, 'member_since').value, contains('15.01.2024'));

      // Oturum açıkken çıkış satırı vardır ve destructive.
      final signOut = _byId(s, 'sign_out');
      expect(signOut.destructive, isTrue);
      expect(signOut.action, AccountAction.signOut);
    });

    test('savedFields yalnızca gerçekten kayıtlı alanları sayar', () {
      expect(_signedIn().summary.savedFields, 3); // email + name + phone
      expect(
        _signedIn(phone: null, name: '').summary.savedFields,
        1, // sadece email
      );
      expect(_signedOut().summary.savedFields, 0);
    });

    test('eksik alanlar uydurulmaz, dürüstçe işaretlenir', () {
      final s = _signedIn(name: '', phone: null, memberSince: null);
      expect(_byId(s, 'name').value, 'Kayıtlı değil');
      expect(_byId(s, 'name').readiness, AccountReadiness.partial);
      expect(_byId(s, 'phone').value, 'Kayıtlı değil');
      expect(_byId(s, 'phone').readiness, AccountReadiness.partial);
      // Telefon yoksa aksiyon dürüstçe mesaj kanalına yönlendirir (dead yok).
      expect(_byId(s, 'phone').action, AccountAction.goMessages);
      expect(_byId(s, 'member_since').readiness, AccountReadiness.partial);
    });

    test('signedOut: hesap bloklu, çıkış satırı yok', () {
      final s = _signedOut();
      expect(s.signedIn, isFalse);
      expect(_byId(s, 'email').value, 'Giriş yapılmamış');
      expect(_byId(s, 'email').readiness, AccountReadiness.blocked);
      expect(s.entries.any((e) => e.id == 'sign_out'), isFalse);
      expect(s.entries.any((e) => e.id == 'member_since'), isFalse);
    });

    test('coverageNote uydurma bilgi vermediğini açıkça belirtir', () {
      expect(_signedIn().coverageNote, contains('uydurma'));
      expect(_signedIn().coverageNote, contains('sunucuda'));
    });

    test('kanallar gerçek sekmelere yönlenir (dead button yok)', () {
      final s = _signedIn();
      expect(_byId(s, 'requests').action, AccountAction.goRequests);
      expect(_byId(s, 'engagement').action, AccountAction.goEngagement);
      expect(_byId(s, 'message_channel').action, AccountAction.goMessages);
      expect(_byId(s, 'privacy').action, AccountAction.privacy);
      expect(_byId(s, 'about').action, AccountAction.about);
    });
  });

  group('filterAccountEntries', () {
    test('kategori filtreleri yalnızca ilgili bölümü döndürür', () {
      final s = _signedIn();
      expect(
        filterAccountEntries(s.entries, filter: AccountFilter.account).length,
        5,
      );
      expect(
        filterAccountEntries(s.entries, filter: AccountFilter.contact).length,
        2,
      );
      expect(
        filterAccountEntries(s.entries, filter: AccountFilter.channels).length,
        2,
      );
      expect(
        filterAccountEntries(s.entries, filter: AccountFilter.privacy).length,
        3,
      );
    });

    test('Tümü tüm satırları döndürür', () {
      final s = _signedIn();
      expect(
        filterAccountEntries(s.entries).length,
        s.entries.length,
      );
    });

    test('Kısmi yalnızca sunucuda olmayan alanları döndürür', () {
      final s = _signedIn(name: '', phone: null);
      final partial =
          filterAccountEntries(s.entries, filter: AccountFilter.partial);
      expect(partial.map((e) => e.id), containsAll(['name', 'phone']));
      expect(partial.every((e) => e.readiness != AccountReadiness.ready),
          isTrue);
    });
  });
}
