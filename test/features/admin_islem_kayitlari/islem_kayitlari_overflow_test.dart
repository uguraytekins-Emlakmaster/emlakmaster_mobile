import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/admin_islem_kayitlari_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/utils/islem_kayitlari_types.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/widgets/islem_kayitlari_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/widgets/islem_kayitlari_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Profile {
  const _Profile(this.name, this.size);
  final String name;
  final Size size;
}

const _profiles = [
  _Profile('iPhone SE', Size(390, 844)),
  _Profile('iPhone 15', Size(430, 932)),
  _Profile('Android compact', Size(360, 780)),
  _Profile('tablet', Size(768, 1024)),
];

final _strip = IslemKayitlariHealthStrip(
  last24hCount: 4,
  criticalCount: 1,
  teamChangeCount: 2,
  consultantActionCount: 3,
  inviteCount: 2,
  warningCount: 1,
  totalEvents: 8,
  auditLogCount: 6,
  hasPartialCoverage: true,
);

final _row = IslemKayitlariRowViewModel(
  id: 'audit:1',
  title: 'Ekip yöneticisi ataması değiştirildi — Alpha Operasyon',
  actorLine: 'Ayşe Yılmaz',
  targetLine: 'Ekip · Alpha Operasyon',
  detailLine: 'team.managerId → u42',
  timestampLabel: '2 sa 15 dk önce',
  occurredAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
  severity: IslemKayitlariSeverity.warning,
  category: IslemKayitlariCategory.team,
  source: IslemKayitlariEventSource.auditLog,
  sourceLabel: 'Audit kaydı',
  categoryLabel: 'Ekip',
  suggestedFilter: IslemKayitlariFilter.team,
  consultantId: null,
  teamId: 't1',
  hasPartialMetadata: false,
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
                PremiumIslemKayitlariHeader(
                  coverageNote:
                      'Kaynaklar: audit_logs ve davet kayıtları. Tüm admin işlemleri henüz loglanmıyor olabilir.',
                ),
                PremiumIslemKayitlariHealthStrip(strip: _strip),
                IslemKayitlariCompactSearch(
                  hintText: 'İşlem ara',
                  onChanged: (_) {},
                ),
                IslemKayitlariFilterChips(
                  selected: IslemKayitlariFilter.team,
                  onSelected: (_) {},
                ),
                IslemKayitlariRow(
                  viewModel: _row,
                  onTap: () {},
                  onDetail: () {},
                  onTeam: () {},
                  onReports: () {},
                  onApplyFilter: () {},
                ),
                const SizedBox(height: AdminIslemKayitlariTokens.bottomReserve),
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
    testWidgets('Islem kayitlari chrome zero overflow · ${profile.name}',
        (tester) async {
      await _pumpChrome(tester, profile.size);
      expect(tester.takeException(), isNull);
    });
  }
}
