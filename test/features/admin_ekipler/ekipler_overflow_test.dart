import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/admin_ekipler_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/utils/ekipler_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/utils/ekipler_team_filter.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/widgets/ekipler_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/widgets/ekipler_team_row.dart';
import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _profiles = <({String name, Size size})>[
  (name: 'iPhone SE', size: Size(320, 568)),
  (name: 'iPhone 14', size: Size(390, 844)),
  (name: 'iPhone 15 Plus', size: Size(430, 932)),
  (name: 'Android compact', size: Size(360, 640)),
  (name: 'macOS window', size: Size(1280, 800)),
];

const _strip = EkiplerHealthStrip(
  activeTeams: 3,
  totalConsultants: 12,
  interventionTeams: 1,
  unassignedConsultants: 2,
  officeOpenTasks: 8,
  officeFollowUpQueue: 4,
  officeMissedCalls: 1,
  hasOfficeSignals: true,
);

const _vm = EkiplerTeamViewModel(
  team: TeamDoc(id: 't1', name: 'Merkez Satış Ekibi Alpha', managerId: 'm1'),
  stats: EkiplerTeamRosterStats(
    totalMembers: 6,
    activeMembers: 5,
    inactiveMembers: 1,
    isEmpty: false,
    allMembersInactive: false,
    needsIntervention: false,
    hasManager: true,
  ),
  managerName: 'Mehmet Kara Uzun İsim',
  managerRoleLabel: 'Ekip lideri',
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
                  const PremiumEkiplerHeader(),
                  const PremiumEkiplerHealthStrip(strip: _strip),
                  EkiplerCompactSearch(
                    hintText: 'Ekip ara',
                    onChanged: (_) {},
                  ),
                  EkiplerFilterChips(
                    selected: EkiplerTeamFilter.intervention,
                    onSelected: (_) {},
                  ),
                  EkiplerTeamRow(
                    viewModel: _vm,
                    detailed: true,
                    onTap: () {},
                    onKadro: () {},
                    onReports: () {},
                    onAssign: () {},
                  ),
                  SizedBox(height: AdminEkiplerTokens.bottomReserve),
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
    testWidgets('Ekipler chrome zero overflow · ${profile.name}', (tester) async {
      await _pumpChrome(tester, profile.size);
      expect(tester.takeException(), isNull);
    });
  }
}
