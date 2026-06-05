import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/pages/tasks_page.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_display_provider.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_query_document_snapshot.dart';

const _proofDir = 'build/screenshots/screen4_tasks';
const _macSize = Size(1280, 800);

class _ProofAuthUser implements User {
  _ProofAuthUser(this.uid);
  @override
  final String uid;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FixedProofTasksCache extends AdvisorTasksStaleCache {
  _FixedProofTasksCache(this._value);
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _value;
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? build(String uid) => _value;
}

List<QueryDocumentSnapshot<Map<String, dynamic>>> _proofTaskDocs() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return [
    fakeQueryDocumentSnapshot('t1', {
      'title': 'Müşteriyi ara — Ayşe Demir',
      'done': false,
      'dueAt': Timestamp.fromDate(today),
      'customerId': 'c1',
      'advisorId': 'proof_advisor',
    }),
    fakeQueryDocumentSnapshot('t2', {
      'title': 'Portföy sunumu hazırla',
      'done': false,
      'dueAt': Timestamp.fromDate(today.subtract(const Duration(days: 2))),
      'advisorId': 'proof_advisor',
    }),
    fakeQueryDocumentSnapshot('t3', {
      'title': 'Sözleşme takibi',
      'done': false,
      'dueAt': Timestamp.fromDate(today.add(const Duration(days: 4))),
      'customerId': 'c2',
      'recurrence': 'weekly',
      'advisorId': 'proof_advisor',
    }),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('06 — live macOS consultant TasksPage harness', (tester) async {
    if (!Platform.isMacOS && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    const key = Key('proof_live_macos');
    final docs = _proofTaskDocs();
    const uid = 'proof_advisor';

    tester.view.physicalSize = _macSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => Stream<User?>.value(_ProofAuthUser(uid)),
          ),
          advisorTasksDisplayProvider(uid).overrideWith(
            (ref) => AsyncData(docs),
          ),
          advisorTasksStaleCacheProvider.overrideWith(
            () => _FixedProofTasksCache(docs),
          ),
          customerEntityByIdProvider.overrideWith((ref, id) {
            return Stream.value(switch (id) {
              'c1' => CustomerEntity(
                  id: 'c1',
                  fullName: 'Ayşe Demir',
                  primaryPhone: '+905321112233',
                  createdAt: DateTime(2024),
                  updatedAt: DateTime(2024),
                ),
              'c2' => CustomerEntity(
                  id: 'c2',
                  fullName: 'Mehmet Kaya',
                  primaryPhone: '+905559998877',
                  createdAt: DateTime(2024),
                  updatedAt: DateTime(2024),
                ),
              _ => null,
            });
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: MediaQuery(
            data: const MediaQueryData(size: _macSize),
            child: Material(
              color: const Color(0xFF0A0E1A),
              child: RepaintBoundary(
                key: key,
                child: const PremiumShellBackdrop(
                  child: TasksPage(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Görevlerim'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
    expect(tester.takeException(), isNull);

    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      final dir = Directory(_proofDir);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final path = '$_proofDir/06_live_macos_consultant_tasks.png';
      await File(path).writeAsBytes(bytes!.buffer.asUint8List());
      expect(File(path).lengthSync(), greaterThan(2000));
    });
  });
}
