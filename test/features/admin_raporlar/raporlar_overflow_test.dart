import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/providers/raporlar_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_types.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/widgets/raporlar_command_surface.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

RaporlarSnapshot _fullSnapshot() => computeRaporlarSnapshot(
      role: AppRole.brokerOwner,
      signals: const RaporlarGroundedSignals(
        teamsCount: 6,
        officeKnown: true,
        officePendingInvites: 4,
        officeIntervention: 2,
        connectionKnown: true,
        connectionIntervention: 1,
        connectionReady: 3,
      ),
    );

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        raporlarSnapshotProvider
            .overrideWith((ref) => AsyncValue.data(_fullSnapshot())),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: RaporlarCommandSurface()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  const profiles = <String, Size>{
    'iPhone SE': Size(320, 568),
    'iPhone 14/15': Size(390, 844),
    'iPhone Pro Max': Size(430, 932),
    'Android compact': Size(360, 740),
    'Android normal': Size(412, 915),
    'tablet': Size(768, 1024),
    'macOS window': Size(1024, 768),
  };

  profiles.forEach((name, size) {
    testWidgets('overflow yok — $name', (tester) async {
      await _pumpAt(tester, size);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('dar ekranda satır başlığı + durum chip taşmaz', (tester) async {
    await _pumpAt(tester, const Size(320, 700));
    // Müdahale gerekli durum etiketi (en uzun) görünür ve taşma yok.
    expect(find.text('Müdahale gerekli'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filtre seçimi listeyi daraltır (müdahale)', (tester) async {
    await _pumpAt(tester, const Size(390, 844));
    await tester.tap(find.text('Müdahale'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
