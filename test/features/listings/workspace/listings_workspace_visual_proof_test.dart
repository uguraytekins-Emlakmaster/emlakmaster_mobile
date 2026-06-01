import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_host.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_types.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/providers/listings_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/widgets/listings_workspace_row.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/widgets/listings_workspace_surface.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen29_consultant_listings';
const _phone = Size(390, 844);
const _boundary = Key('listings_workspace_proof');

ListingsWorkspaceSnapshot _fullSnapshot() {
  final now = DateTime(2024, 6, 15, 12);
  return computeListingsWorkspaceSnapshot(
    [
      ListingRowView(
        id: 'l1',
        sourcePlatform: 'internal',
        sourceListingId: 'l1',
        isOwnedByOffice: true,
        syncStatus: ListingSyncStatus.synced,
        title: 'Satılık Daire — Kadıköy',
        priceLabel: '3.200.000',
        locationLabel: 'İstanbul Kadıköy',
        imageUrl: null,
        surface: ListingSurface.owned,
        rowKind: ListingRowKind.officePortfolio,
        detailListingId: 'l1',
        listingType: 'Satılık Konut',
        platformStatus: 'published',
      ),
      ListingRowView(
        id: 'l2',
        sourcePlatform: 'internal',
        sourceListingId: 'l2',
        isOwnedByOffice: true,
        syncStatus: ListingSyncStatus.pending,
        title: 'Eksik kayıt',
        priceLabel: '—',
        locationLabel: '—',
        surface: ListingSurface.owned,
        rowKind: ListingRowKind.officePortfolio,
        detailListingId: 'l2',
      ),
      ListingRowView(
        id: 'l3',
        sourcePlatform: 'sahibinden',
        sourceListingId: 'ext1',
        isOwnedByOffice: true,
        syncStatus: ListingSyncStatus.error,
        title: 'Senkron hatası',
        priceLabel: '1.800.000',
        locationLabel: 'Ankara Çankaya',
        surface: ListingSurface.owned,
        rowKind: ListingRowKind.connectedPlatform,
        listingType: 'Kiralık',
        platformStatus: 'active',
      ),
    ],
    now: now,
    canManage: true,
  );
}

ListingsWorkspaceSnapshot _emptySnapshot() =>
    computeListingsWorkspaceSnapshot([], now: DateTime(2024, 6, 15), canManage: true);

Future<void> _savePng(WidgetTester tester, String name) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final dir = Directory(_proofDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final path = '$_proofDir/$name';
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    expect(File(path).lengthSync(), greaterThan(800));
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required ListingsWorkspaceSnapshot snapshot,
}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        listingsWorkspaceSnapshotProvider.overrideWithValue(
          AsyncValue.data(snapshot),
        ),
        canManagePlatformIntegrationsProvider.overrideWithValue(true),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const RepaintBoundary(
          key: _boundary,
          child: ShellTabBackHost(
            pageIndex: 4,
            child: Scaffold(body: ListingsWorkspaceSurface()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 header summary filters proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await _savePng(tester, '01_header_summary_filters.png');
  });

  testWidgets('02 listing rows proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
    await tester.pump();
    await _savePng(tester, '02_listing_rows.png');
  });

  testWidgets('03 actions proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await tester.tap(find.byType(PopupMenuButton<ListingRowMenu>).first);
    await tester.pumpAndSettle();
    await _savePng(tester, '03_actions.png');
  });

  testWidgets('04 empty or partial state proof', (tester) async {
    await _pump(tester, snapshot: _emptySnapshot());
    await _savePng(tester, '04_empty_or_partial_state.png');
  });

  testWidgets('05 bottom safe area proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pump();
    await _savePng(tester, '05_bottom_safe_area.png');
  });
}
