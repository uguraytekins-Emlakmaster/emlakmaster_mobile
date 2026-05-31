// ignore_for_file: avoid_redundant_argument_values

import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/admin_uyelikler_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/utils/uyelikler_types.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/widgets/uyelikler_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/widgets/uyelikler_row.dart';
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
];

const _strip = UyeliklerSummaryStrip(
  pendingInvites: 4,
  acceptedInvites: 6,
  expiredInvites: 2,
  activeMembers: 11,
  interventionCount: 3,
  totalMembers: 14,
  totalInvites: 12,
);

const _inviteRow = UyelikRowViewModel(
  id: 'invite:1',
  kind: UyelikKind.invite,
  title: 'Davet kodu · QX7K2M9P',
  subtitle: 'Danışman daveti · Çok Uzun Yönetici İsmi Soyismi Buraya',
  detailLine: '2/5 kullanım · Son: 30 Haz 2026',
  statusLabel: 'Bekliyor',
  durum: UyelikDurum.pending,
  tone: UyelikTone.info,
  timestampLabel: '2 sa önce oluşturuldu',
  occurredAt: null,
  needsAction: false,
  hasPartialMetadata: false,
  inviteId: '1',
  inviteCode: 'QX7K2M9P',
  isActiveInvite: true,
);

const _memberRow = UyelikRowViewModel(
  id: 'member:1',
  kind: UyelikKind.member,
  title: 'cok.uzun.email.adresi.buraya.gelecek@emlakmastergayrimenkul.com',
  subtitle: 'Müdür · Üyelik',
  detailLine: 'cok.uzun.email.adresi@emlakmaster.com',
  statusLabel: 'Askıda',
  durum: UyelikDurum.suspended,
  tone: UyelikTone.warning,
  timestampLabel: '3 gün önce katıldı',
  occurredAt: null,
  needsAction: true,
  hasPartialMetadata: false,
  memberUserId: 'u1',
  canModerate: true,
  canSuspend: false,
  canRemove: true,
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
                const PremiumUyeliklerHeader(
                  coverageNote:
                      'Yalnızca gerçek davet ve üyelik kayıtları gösterilir. '
                      'Onboarding ilerlemesi cihaz-yereldir; sunucuda izlenmediği için burada gösterilmez.',
                ),
                const PremiumUyeliklerSummaryStrip(strip: _strip),
                UyeliklerQuickRouteRow(
                  onCreateInvite: () {},
                  onOfficeAdmin: () {},
                  onKadro: () {},
                ),
                UyeliklerCompactSearch(hintText: 'Ara', onChanged: (_) {}),
                UyeliklerFilterChips(
                  selected: UyeliklerFilter.all,
                  onSelected: (_) {},
                ),
                UyelikRow(
                  viewModel: _inviteRow,
                  onTap: () {},
                  onDetail: () {},
                  onCopyCode: () {},
                  onDeactivate: () {},
                ),
                UyelikRow(
                  viewModel: _memberRow,
                  onTap: () {},
                  onDetail: () {},
                  onKadro: () {},
                  onRemove: () {},
                ),
                const SizedBox(height: AdminUyeliklerTokens.bottomReserve),
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
    testWidgets('Uyelikler chrome zero overflow · ${profile.name}',
        (tester) async {
      await _pumpChrome(tester, profile.size);
      expect(tester.takeException(), isNull);
    });
  }
}
