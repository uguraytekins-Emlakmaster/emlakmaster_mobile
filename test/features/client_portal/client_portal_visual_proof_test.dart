// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/data/client_portal_preview_catalog.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/models/client_listing_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/pages/client_portal_favorites_page.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/utils/client_portal_actions.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/utils/client_portal_filter.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_chrome.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_listing_tile.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_row_actions.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen10_client_portal';
const _phoneSize = Size(390, 844);
const _pixelRatio = 3.0;

Future<void> _savePng(WidgetTester tester, Key key, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final dir = Directory(_proofDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final path = '$_proofDir/$name';
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    expect(File(path).lengthSync(), greaterThan(800));
  });
}

Future<void> _pumpFrame(
  WidgetTester tester, {
  required Key captureKey,
  required Widget child,
  Size size = _phoneSize,
  double? height,
  List<Override>? overrides,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides ?? const [],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: const EdgeInsets.only(top: 47, bottom: 34),
          ),
          child: Material(
            color: const Color(0xFF0A0E1A),
            child: Center(
              child: SizedBox(
                width: size.width,
                height: height ?? size.height,
                child: RepaintBoundary(
                  key: captureKey,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Widget _clientShellDock({required Widget body}) {
  return Scaffold(
    backgroundColor: const Color(0xFF0A0E1A),
    body: body,
    bottomNavigationBar: PremiumBottomNavDock(
      items: const [
        AdaptiveNavItem(Icons.search_rounded, 'Keşfet'),
        AdaptiveNavItem(Icons.favorite_rounded, ProductLabels.favorites),
        AdaptiveNavItem(Icons.chat_rounded, ProductLabels.messages),
        AdaptiveNavItem(Icons.video_camera_back_rounded, ProductLabels.virtualTour),
        AdaptiveNavItem(Icons.person_rounded, ProductLabels.profile),
      ],
      selectedIndex: 0,
      onTap: (_) {},
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppFeedback.applyRuntimeFlags(haptic: false, sound: false);
  });

  testWidgets('01 — header summary filters proof', (tester) async {
    const key = Key('proof_client_header');
    final summary = computeClientPortalSummary(signedIn: true);

    await _pumpFrame(
      tester,
      captureKey: key,
      size: _phoneSize,
      height: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PremiumClientPortalHeader(
            title: 'Hoş geldiniz',
            subtitle: 'Size özel portföy · güvenilir danışman deneyimi',
          ),
          PremiumClientSummaryStrip(summary: summary),
          PremiumClientPortalSearchRow(controller: TextEditingController()),
          PremiumClientPortalFilterStrip(
            selected: ClientPortalFilter.all,
            onSelected: (_) {},
          ),
        ],
      ),
    );
    await _savePng(tester, key, '01_header_summary_filters.png');
    expect(find.text('Hoş geldiniz'), findsOneWidget);
    expect(find.text('Tümü'), findsOneWidget);
    expect(find.text('Favoriler'), findsOneWidget);
  });

  testWidgets('02 — listing cards proof', (tester) async {
    const key = Key('proof_client_cards');
    final rows = clientPortalPreviewCatalog.take(2).toList();

    await _pumpFrame(
      tester,
      captureKey: key,
      height: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final listing in rows)
              ClientPortalListingTile(
                listing: listing,
                snapshot: ClientListingRowSnapshot.fromPreview(listing),
                onInspect: () {},
                onFavorite: () {},
                onMessage: () {},
                onAppointment: () {},
                onShare: () {},
              ),
          ],
        ),
      ),
    );
    await _savePng(tester, key, '02_listing_cards.png');
    expect(find.text('İncele'), findsWidgets);
    expect(find.textContaining('Yakında'), findsWidgets);
  });

  testWidgets('03 — row actions proof', (tester) async {
    const key = Key('proof_client_actions');

    await _pumpFrame(
      tester,
      captureKey: key,
      height: 120,
      child: ClientPortalRowActions(
        onInspect: () {},
        onFavorite: () {},
        onMessage: () {},
        onAppointment: () {},
        onShare: () {},
      ),
    );
    await _savePng(tester, key, '03_actions.png');
    expect(find.text('Mesaj'), findsOneWidget);
    expect(find.text('Paylaş'), findsOneWidget);
  });

  testWidgets('04 — empty or preview state proof', (tester) async {
    const key = Key('proof_client_empty');

    await _pumpFrame(
      tester,
      captureKey: key,
      height: 560,
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: const ClientPortalFavoritesPage(),
    );
    await _savePng(tester, key, '04_empty_or_preview_state.png');
    // Favoriler tab'ı artık İlgi & Etkileşim yüzeyini (Screen 20) barındırır.
    expect(find.text('İlgi & Etkileşim'), findsWidgets);
    expect(find.textContaining('sunucuda'), findsWidgets);
  });

  testWidgets('05 — bottom nav safe area proof', (tester) async {
    const key = Key('proof_client_dock');

    await _pumpFrame(
      tester,
      captureKey: key,
      height: _phoneSize.height,
      child: _clientShellDock(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PremiumClientPortalHeader(
              title: 'Hoş geldiniz',
              subtitle: 'Size özel portföy',
            ),
            PremiumClientSummaryStrip(
              summary: computeClientPortalSummary(signedIn: false),
            ),
            const Expanded(
              child: Center(
                child: EmptyState(
                  compact: true,
                  icon: Icons.search_rounded,
                  title: 'Keşfet',
                  subtitle: 'Portföy önizlemesi',
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await _savePng(tester, key, '05_bottom_nav_safe_area.png');
    expect(find.text('Keşfet'), findsWidgets);
  });

  testWidgets('favorite preview action shows honest feedback', (tester) async {
    await _pumpFrame(
      tester,
      captureKey: const Key('action_test'),
      height: 400,
      child: Scaffold(
        body: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () => ClientPortalActions.favoritePreview(context),
              child: const Text('Favori dene'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Favori dene'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Favori kaydı yakında'), findsOneWidget);
  });
}
