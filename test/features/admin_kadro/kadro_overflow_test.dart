import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/admin_kadro_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/utils/kadro_consultant_filter.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/utils/kadro_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/widgets/kadro_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/widgets/kadro_consultant_row.dart';
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

const _strip = KadroHealthStrip(
  activeConsultants: 8,
  needsIntervention: 2,
  teamCount: 4,
  inactiveConsultants: 1,
  unassignedConsultants: 1,
  officeOpenTasks: 14,
  officeFollowUpQueue: 5,
  officeMissedCalls: 2,
  hasOfficeSignals: true,
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
                  const PremiumKadroHeader(),
                  const PremiumKadroHealthStrip(strip: _strip),
                  KadroCompactSearch(hintText: 'Danışman ara', onChanged: (_) {}),
                  KadroFilterChips(
                    selected: KadroRosterFilter.intervention,
                    onSelected: (_) {},
                  ),
                  KadroConsultantRow(
                    user: const UserDoc(
                      uid: '1',
                      role: 'agent',
                      name: 'Ayşe Yılmaz Uzun İsim Test',
                      email: 'ayse@cokuzunemailadresi.com',
                      teamId: 't1',
                    ),
                    teamName: 'Merkez Satış Ekibi Alpha',
                    onTap: () {},
                    onEdit: () {},
                    onTeamDetail: () {},
                    onReports: () {},
                  ),
                  SizedBox(height: AdminKadroTokens.bottomReserve),
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
    testWidgets('Kadro chrome zero overflow · ${profile.name}', (tester) async {
      await _pumpChrome(tester, profile.size);
      expect(tester.takeException(), isNull);
    });
  }
}
