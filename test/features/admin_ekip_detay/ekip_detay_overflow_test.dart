import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/admin_ekip_detay_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/utils/ekip_detay_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/widgets/ekip_detay_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/widgets/ekip_detay_member_row.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _profiles = <({String name, Size size})>[
  (name: 'iPhone SE', size: Size(320, 568)),
  (name: 'iPhone 14', size: Size(390, 844)),
  (name: 'iPhone 15 Plus', size: Size(430, 932)),
  (name: 'Android compact', size: Size(360, 640)),
  (name: 'macOS window', size: Size(1280, 800)),
];

const _strip = EkipDetayHealthStrip(
  totalMembers: 6,
  activeMembers: 5,
  inactiveMembers: 1,
  interventionMembers: 2,
  teamNeedsIntervention: false,
  officeOpenTasks: 8,
  officeFollowUpQueue: 4,
  officeMissedCalls: 1,
  hasOfficeSignals: true,
);

final _member = UserDoc(
  uid: 'a1',
  role: 'agent',
  name: 'Mehmet Kara Uzun İsim Danışman',
  email: 'mehmet.kara@emlakmaster.com',
  isActive: true,
  teamId: 't1',
);

Future<void> _pumpChrome(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: EdgeInsets.only(
            top: 47,
            bottom: size.height > 700 ? 34 : 0,
          ),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PremiumEkipDetayHeader(
                    teamName: 'Merkez Satış Ekibi Alpha',
                    managerLine: 'Ekip lideri · Ayşe Yılmaz',
                  ),
                  const PremiumEkipDetayHealthStrip(strip: _strip),
                  const EkipDetayOfficeNote(),
                  EkipDetayQuickRouteRow(
                    onKadro: () {},
                    onTeams: () {},
                    onReports: () {},
                    onAddMember: () {},
                    onCommandCenter: () {},
                  ),
                  const EkipDetaySectionHeader(title: 'Ekip üyeleri', count: 6),
                  EkipDetayMemberRow(
                    user: _member,
                    teamManagerId: 'm1',
                    onTap: () {},
                    onEdit: () {},
                    onKadro: () {},
                    onReports: () {},
                  ),
                  SizedBox(height: AdminEkipDetayTokens.bottomReserve),
                ],
              ),
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
    testWidgets('Ekip detay chrome zero overflow · ${profile.name}',
        (tester) async {
      await _pumpChrome(tester, profile.size);
      expect(tester.takeException(), isNull);
    });
  }
}
