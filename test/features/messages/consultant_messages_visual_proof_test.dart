import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/models/message_conversation_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/utils/message_conversation_list_filter.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/widgets/consultant_messages_chrome.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/widgets/message_conversation_card.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/widgets/message_list_row_quick_actions.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen6_messages';
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
    await File('$_proofDir/$name').writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Future<void> _pumpFrame(
  WidgetTester tester, {
  required Key captureKey,
  required Widget child,
  double? height,
}) async {
  tester.view.physicalSize = _phoneSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: _phoneSize,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: Material(
          color: const Color(0xFF0A0E1A),
          child: Center(
            child: SizedBox(
              width: _phoneSize.width,
              height: height ?? _phoneSize.height,
              child: RepaintBoundary(key: captureKey, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

MessageConversationListItem _conv({
  required String title,
  int unread = 0,
  String preview = 'Son mesaj önizlemesi',
}) =>
    MessageConversationListItem(
      id: 'c1',
      kind: MessageConversationKind.direct,
      surface: MessageConversationSurface.teamLive,
      title: title,
      subtitle: 'Danışman',
      preview: preview,
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 12)),
      unreadCount: unread,
      channelId: 'ch1',
      officeId: 'o1',
    );

Widget _card(MessageConversationListItem item) {
  final snapshot = MessageConversationRowSnapshot.fromItem(item);
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: MessageConversationCard(
      item: item,
      snapshot: snapshot,
      onTap: () {},
      onOpen: () {},
      onCall: () {},
      onWhatsApp: () {},
      onMarkRead: () {},
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 — header metrics filters proof', (tester) async {
    const key = Key('proof_messages_header');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PremiumMessagesPageHeader(
            title: 'Mesaj Merkezi',
            subtitle: 'Çok kanallı iletişim · müşteri mesajları',
          ),
          PremiumMessagesStatusBanner(
            message:
                'Önizleme modu — ekip sohbeti canlıdır. Harici kanallar için bağlantı gerekir.',
            icon: Icons.info_outline_rounded,
          ),
          const PremiumMessagesSummaryStrip(
            summary: MessageListSummary(
              totalConversations: 4,
              unread: 2,
              liveChannels: 1,
            ),
          ),
          PremiumMessageSearchRow(
            controller: TextEditingController(),
            hintText: 'Kişi veya mesaj ara',
          ),
          PremiumMessageFilterStrip(
            selected: MessagePlatformFilter.all,
            onSelected: (_) {},
          ),
        ],
      ),
    );
    await _savePng(tester, key, '01_header_metrics_filters.png');
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('02 — conversation rows proof', (tester) async {
    const key = Key('proof_messages_rows');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 400,
      child: Column(
        children: [
          _card(_conv(title: 'Genel sohbet', preview: 'Toplantı 15:00')),
          _card(_conv(title: 'Ayşe Demir', unread: 2)),
          _card(_conv(title: 'Mehmet Kaya', unread: 0)),
        ],
      ),
    );
    await _savePng(tester, key, '02_conversation_rows.png');
  });

  testWidgets('03 — conversation actions proof', (tester) async {
    const key = Key('proof_messages_actions');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 168,
      child: _card(_conv(title: 'Hızlı aksiyonlar')),
    );
    await _savePng(tester, key, '03_conversation_actions.png');
    expect(find.byType(MessageListRowQuickActions), findsOneWidget);
  });

  testWidgets('04 — empty state proof', (tester) async {
    const key = Key('proof_messages_empty');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 520,
      child: const Column(
        children: [
          PremiumMessagesPageHeader(
            title: 'Mesaj Merkezi',
            subtitle: 'Çok kanallı iletişim · müşteri mesajları',
          ),
          PremiumMessagesSummaryStrip(summary: MessageListSummary.empty),
          EmptyState(
            premiumVisual: true,
            grouped: true,
            icon: Icons.forum_outlined,
            title: 'Henüz mesaj yok',
            subtitle:
                'Kanal bağlantısı kurulduğunda mesajlar burada görünür.',
            actionLabel: 'Kanal bağla',
          ),
        ],
      ),
    );
    await _savePng(tester, key, '04_empty_state.png');
  });

  testWidgets('05 — bottom nav safe area proof', (tester) async {
    const key = Key('proof_messages_dock');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: _phoneSize.height,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: Column(
          children: [
            const PremiumMessagesPageHeader(
              title: 'Mesaj Merkezi',
              subtitle: 'Çok kanallı iletişim · müşteri mesajları',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                children: [
                  _card(_conv(title: 'Son konuşma — dock üstünde görünür')),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: PremiumBottomNavDock(
          items: const [
            AdaptiveNavItem(
              Icons.space_dashboard_rounded,
              ProductLabels.consultantHome,
            ),
            AdaptiveNavItem(Icons.call_rounded, ProductLabels.myCalls),
            AdaptiveNavItem(Icons.people_rounded, ProductLabels.myCustomers),
            AdaptiveNavItem(Icons.task_alt_rounded, ProductLabels.myTasks),
            AdaptiveNavItem(Icons.apps_rounded, ProductLabels.consultantMore),
          ],
          selectedIndex: 4,
          onTap: (_) {},
        ),
      ),
    );
    await _savePng(tester, key, '05_bottom_nav_safe_area.png');
  });

  testWidgets('06 — preview channel required proof', (tester) async {
    const key = Key('proof_messages_channel');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 560,
      child: SingleChildScrollView(
        child: Column(
        children: [
          const PremiumMessagesPageHeader(
            title: 'Mesaj Merkezi',
            subtitle: 'Çok kanallı iletişim · müşteri mesajları',
            showPreviewBadge: true,
          ),
          PremiumMessagesStatusBanner(
            message:
                'Kanal bağlantısı gerekli — WhatsApp mesajları bu kanal bağlandığında görünecek.',
            icon: Icons.link_off_rounded,
            actionLabel: 'Kanal bağla',
          ),
          PremiumMessageFilterStrip(
            selected: MessagePlatformFilter.whatsapp,
            onSelected: (_) {},
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: EmptyState(
              premiumVisual: true,
              grouped: true,
              icon: Icons.chat_outlined,
              title: 'Henüz mesaj yok',
              subtitle:
                  'Kanal bağlantısı kurulduğunda WhatsApp mesajları burada görünür.',
              actionLabel: 'Kanal bağla',
            ),
          ),
        ],
        ),
      ),
    );
    await _savePng(tester, key, '06_preview_or_channel_required_state.png');
    expect(find.text('WhatsApp'), findsWidgets);
  });
}
