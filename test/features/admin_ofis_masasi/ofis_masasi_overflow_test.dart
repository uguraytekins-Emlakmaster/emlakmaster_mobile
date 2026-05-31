// ignore_for_file: avoid_redundant_argument_values

import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/admin_ofis_masasi_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/utils/ofis_masasi_types.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/widgets/ofis_masasi_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/widgets/ofis_masasi_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Profile {
  const _Profile(this.name, this.size);
  final String name;
  final Size size;
}

const _profiles = [
  _Profile('iPhone SE', Size(320, 568)),
  _Profile('iPhone 14/15', Size(390, 844)),
  _Profile('Android compact', Size(360, 780)),
  _Profile('Android normal', Size(412, 915)),
  _Profile('tablet', Size(768, 1024)),
  _Profile('macOS window', Size(900, 700)),
];

const _summary = OfisMasasiSummary(
  activeMembers: 11,
  pendingInvites: 4,
  suspendedMembers: 2,
  connectionsReady: 1,
  connectionsNeedingSetup: 2,
  interventionCount: 3,
  totalMembers: 14,
  totalInvites: 5,
  totalConnections: 3,
  connectionsKnown: true,
);

const _inviteRow = OfisRowViewModel(
  id: 'invite:1',
  kind: OfisRowKind.invite,
  title: 'Davet kodu · QX7K2M9P',
  subtitle: 'Danışman daveti · Çok Uzun Yönetici İsmi Soyismi Buraya',
  detailLine: '2/5 kullanım · Son: 30 Haz 2026',
  statusLabel: 'Bekliyor',
  tone: OfisTone.info,
  timestampLabel: '2 sa önce oluşturuldu',
  occurredAt: null,
  needsAction: false,
  hasPartialMetadata: false,
  inviteId: '1',
  inviteCode: 'QX7K2M9P',
  isActiveInvite: true,
);

const _memberRow = OfisRowViewModel(
  id: 'member:1',
  kind: OfisRowKind.member,
  title: 'cok.uzun.email.adresi.buraya.gelecek@emlakmastergayrimenkul.com',
  subtitle: 'Müdür · Üyelik',
  detailLine: 'cok.uzun.email.adresi@emlakmaster.com',
  statusLabel: 'Askıda',
  tone: OfisTone.warning,
  timestampLabel: '3 gün önce katıldı',
  occurredAt: null,
  needsAction: true,
  hasPartialMetadata: false,
  memberUserId: 'u1',
  canSuspend: false,
  canRemove: true,
);

const _connectionRow = OfisRowViewModel(
  id: 'connection:sahibinden',
  kind: OfisRowKind.connection,
  title: 'Sahibinden.com',
  subtitle: 'Kurulum tamamlanmadı · temel bilgiler eksik',
  detailLine: '',
  statusLabel: 'Eksik kurulum',
  tone: OfisTone.warning,
  timestampLabel: '1 gün önce güncellendi',
  occurredAt: null,
  needsAction: true,
  hasPartialMetadata: false,
  connectionPlatformKey: 'sahibinden',
  connectionConfigured: true,
);

Future<void> _pumpChrome(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PremiumOfisMasasiHeader(
                  coverageNote:
                      'Yalnızca gerçek ofis verisi gösterilir: üyeler, davetler ve '
                      'platform kurulum kayıtları. Canlı senkron ve onboarding iddiası yok.',
                ),
                const OfisMasasiSummaryStripView(summary: _summary),
                OfisMasasiQuickRoutes(
                  onCreateInvite: () {},
                  onUyelikler: () {},
                  onKadro: () {},
                  onTeams: () {},
                  onConnections: () {},
                ),
                OfisMasasiCompactSearch(hintText: 'Ara', onChanged: (_) {}),
                const OfisMasasiSectionHeader(title: 'Üyeler', count: 14),
                OfisMasasiRow(
                  viewModel: _memberRow,
                  onTap: () {},
                  onDetail: () {},
                  onKadro: () {},
                  onRemove: () {},
                ),
                const OfisMasasiSectionHeader(title: 'Davetler', count: 5),
                OfisMasasiRow(
                  viewModel: _inviteRow,
                  onTap: () {},
                  onDetail: () {},
                  onCopyCode: () {},
                  onDeactivate: () {},
                ),
                const OfisMasasiSectionHeader(
                  title: 'Bağlantılar',
                  count: 3,
                  note:
                      'Canlı OAuth/otomatik senkron devrede değil; yalnızca ofis kurulum durumu gösterilir.',
                ),
                OfisMasasiRow(
                  viewModel: _connectionRow,
                  onTap: () {},
                  onDetail: () {},
                  onOpenConnections: () {},
                ),
                const SizedBox(height: AdminOfisMasasiTokens.bottomReserve),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final profile in _profiles) {
    testWidgets('Ofis Masası chrome zero overflow · ${profile.name}',
        (tester) async {
      await _pumpChrome(tester, profile.size);
      expect(tester.takeException(), isNull);
    });
  }
}
