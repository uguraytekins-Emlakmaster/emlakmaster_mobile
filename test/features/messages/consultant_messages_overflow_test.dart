import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/models/message_conversation_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/utils/message_conversation_list_filter.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/widgets/consultant_messages_chrome.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/widgets/message_conversation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _profiles = <({String name, Size size, double textScale})>[
  (name: 'iPhone SE', size: Size(320, 568), textScale: 1.0),
  (name: 'iPhone 14', size: Size(390, 844), textScale: 1.0),
  (name: 'iPhone 15 Pro', size: Size(393, 852), textScale: 1.15),
  (name: 'Android compact', size: Size(360, 640), textScale: 1.0),
  (name: 'Android normal', size: Size(412, 915), textScale: 1.0),
  (name: 'macOS windowed', size: Size(1280, 800), textScale: 1.0),
  (name: 'iPad tablet', size: Size(834, 1194), textScale: 1.0),
  (name: 'large tablet', size: Size(1024, 1366), textScale: 1.1),
];

MessageConversationListItem _item() => const MessageConversationListItem(
      id: 'dm1',
      kind: MessageConversationKind.direct,
      surface: MessageConversationSurface.teamLive,
      title: 'Ayşe Demir — uzun isim taşmasın',
      subtitle: 'Danışman',
      preview: 'Müşteri dosyasını paylaştım, inceler misin?',
      lastMessageAt: null,
      unreadCount: 2,
      channelId: 'ch1',
      officeId: 'office1',
    );

Future<void> _pumpChrome(WidgetTester tester, Size size, double textScale) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final item = _item();
  final snapshot = MessageConversationRowSnapshot.fromItem(item);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          padding: EdgeInsets.only(bottom: size.height > 700 ? 34 : 0),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const PremiumMessagesPageHeader(
                  title: 'Mesaj Merkezi',
                  subtitle: 'Çok kanallı iletişim · müşteri mesajları',
                ),
                const PremiumMessagesSummaryStrip(
                  summary: MessageListSummary(
                    totalConversations: 3,
                    unread: 2,
                    liveChannels: 1,
                  ),
                ),
                PremiumMessageFilterStrip(
                  selected: MessagePlatformFilter.all,
                  onSelected: (_) {},
                ),
                MessageConversationCard(
                  item: item,
                  snapshot: snapshot,
                  onTap: () {},
                  onOpen: () {},
                  onCall: () {},
                  onWhatsApp: () {},
                  onMarkRead: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('Consultant Messages Phase 6 overflow zero', () {
    for (final profile in _profiles) {
      testWidgets('chrome + row · ${profile.name}', (tester) async {
        await _pumpChrome(tester, profile.size, profile.textScale);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
