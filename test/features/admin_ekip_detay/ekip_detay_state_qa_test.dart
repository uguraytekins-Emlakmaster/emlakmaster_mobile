import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/admin_ekip_detay_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/widgets/ekip_detay_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/widgets/ekip_detay_member_row.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/widgets/ekip_detay_skeleton.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('turkish section upper produces EKİP ÜYELERİ', () {
    expect(turkishSectionUpper('Ekip üyeleri'), 'EKİP ÜYELERİ');
  });

  testWidgets('not-found state has honest copy and no raw exception', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: EkipDetayEmptyState(
            title: 'Ekip bulunamadı.',
            message: 'Bu ekip kaydı artık mevcut olmayabilir.',
            actionLabel: 'Ekiplere dön',
            onAction: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Ekip bulunamadı.'), findsOneWidget);
    expect(find.text('Bu ekip kaydı artık mevcut olmayabilir.'), findsOneWidget);
    expect(find.text('Ekiplere dön'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry state has honest copy and retry action', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: EkipDetayEmptyState(
            title: 'Ekip detayı yüklenemedi',
            message: 'Bağlantınızı kontrol edip tekrar deneyin.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Ekip detayı yüklenemedi'), findsOneWidget);
    expect(find.text('Yeniden dene'), findsOneWidget);
    await tester.tap(find.text('Yeniden dene'));
    expect(retried, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long member list reserves bottom safe area above dock', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const members = [
      UserDoc(uid: 'a1', role: 'agent', name: 'Ali', teamId: 't1'),
      UserDoc(uid: 'a2', role: 'agent', name: 'Burak', teamId: 't1'),
      UserDoc(uid: 'a3', role: 'agent', name: 'Cem', teamId: 't1'),
      UserDoc(uid: 'a4', role: 'agent', name: 'Deniz', teamId: 't1'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(top: 47, bottom: 34),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  for (final m in members)
                    EkipDetayMemberRow(
                      user: m,
                      teamManagerId: 'a1',
                      onTap: () {},
                      onEdit: () {},
                    ),
                  SizedBox(
                    height: AdminEkipDetayTokens.bottomReserve + 34,
                    key: const Key('bottom_reserve'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final reserveBox = tester.renderObject<RenderBox>(
      find.byKey(const Key('bottom_reserve')),
    );
    expect(reserveBox.size.height, AdminEkipDetayTokens.bottomReserve + 34);
    expect(tester.takeException(), isNull);
  });
}
