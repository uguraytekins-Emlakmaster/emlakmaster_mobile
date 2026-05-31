import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/client_engagement_filter.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/client_engagement_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/client_engagement_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeClientEngagementSnapshot', () {
    test('signedIn → profil kanalı hazır, 4 aktif kanal', () {
      final snap = computeClientEngagementSnapshot(
        signedIn: true,
        displayName: 'Ada',
        previewPortfolioCount: 8,
      );
      expect(snap.entries.length, 6);
      expect(snap.signedIn, isTrue);
      expect(snap.greetingName, 'Ada');
      expect(snap.summary.previewPortfolio, 8);
      // discovery + message + tour + profile = 4 ready
      expect(snap.summary.activeChannels, 4);
      expect(snap.summary.profileReady, isTrue);
      // Dürüstlük: favori sunucuda tutulmuyor → 0
      expect(snap.summary.favoriteCount, 0);

      final profile = snap.entries.firstWhere((e) => e.id == 'profile');
      expect(profile.readiness, EngagementReadiness.ready);
    });

    test('signedOut → profil engelli, 3 aktif kanal', () {
      final snap = computeClientEngagementSnapshot(
        signedIn: false,
        previewPortfolioCount: 5,
      );
      expect(snap.signedIn, isFalse);
      expect(snap.greetingName, isEmpty);
      expect(snap.summary.activeChannels, 3);
      expect(snap.summary.profileReady, isFalse);

      final profile = snap.entries.firstWhere((e) => e.id == 'profile');
      expect(profile.readiness, EngagementReadiness.blocked);
      expect(profile.statusLabel, 'Giriş gerekli');
    });

    test('favori ve talep kanalları dürüstçe önizleme', () {
      final snap = computeClientEngagementSnapshot(
        signedIn: true,
        previewPortfolioCount: 3,
      );
      final fav = snap.entries.firstWhere((e) => e.id == 'favorites');
      final req = snap.entries.firstWhere((e) => e.id == 'request');
      expect(fav.readiness, EngagementReadiness.preview);
      expect(fav.statusLabel, 'Yakında');
      expect(req.readiness, EngagementReadiness.preview);
      expect(snap.coverageNote, contains('sunucuda'));
    });

    test('preformatted: tüm kanalların gerçek bir kabuk sekmesi hedefi var', () {
      final snap = computeClientEngagementSnapshot(
        signedIn: true,
        previewPortfolioCount: 2,
      );
      // Dead button yok — her kanalın somut actionLabel + shortcut'u olmalı.
      for (final e in snap.entries) {
        expect(e.actionLabel.isNotEmpty, isTrue);
        expect(e.searchText.isNotEmpty, isTrue);
      }
    });
  });

  group('filterEngagementEntries', () {
    late List<ClientEngagementEntry> entries;

    setUp(() {
      entries = computeClientEngagementSnapshot(
        signedIn: true,
        previewPortfolioCount: 8,
      ).entries;
    });

    List<ClientEngagementEntry> run(EngagementFilter f, [String q = '']) =>
        filterEngagementEntries(entries, query: q, filter: f);

    test('all → tüm kanallar', () {
      expect(run(EngagementFilter.all).length, 6);
    });

    test('interaction → yalnızca etkileşim kanalları', () {
      final r = run(EngagementFilter.interaction);
      expect(r.length, 4);
      expect(r.every((e) => e.isInteraction), isTrue);
    });

    test('favorites/message/request → birer kanal', () {
      expect(run(EngagementFilter.favorites).length, 1);
      expect(run(EngagementFilter.message).length, 1);
      expect(run(EngagementFilter.request).length, 1);
    });

    test('saved → favori kanalı', () {
      final r = run(EngagementFilter.saved);
      expect(r.length, 1);
      expect(r.single.kind, EngagementKind.favorites);
    });

    test('recent → sunucuda kayıt yok (dürüst boş)', () {
      expect(run(EngagementFilter.recent), isEmpty);
    });

    test('partial → ready olmayan kanallar (favori + talep)', () {
      final r = run(EngagementFilter.partial);
      expect(r.length, 2);
      expect(r.every((e) => e.readiness != EngagementReadiness.ready), isTrue);
    });

    test('arama → mesaj kanalını bulur', () {
      final r = run(EngagementFilter.all, 'mesaj');
      expect(r.any((e) => e.kind == EngagementKind.message), isTrue);
    });

    test('arama eşleşmezse boş', () {
      expect(run(EngagementFilter.all, 'zzzz-yok'), isEmpty);
    });
  });
}
