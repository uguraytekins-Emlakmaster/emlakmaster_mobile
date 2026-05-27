import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/messages/data/team_chat_repository.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/consultant_messages_tokens.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/models/message_conversation_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/providers/team_chat_inbox_providers.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/providers/team_chat_providers.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/utils/message_conversation_list_filter.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/widgets/consultant_messages_chrome.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/widgets/message_conversation_card.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/widgets/message_external_preview_sheet.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/widgets/message_list_skeleton.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/widgets/team_general_channel_bootstrap.dart';
import 'package:emlakmaster_mobile/screens/consultant_shell_nav.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Mesaj Merkezi — ekip sohbeti canlı; harici kanallar önizleme (sahte gönderim yok).
class MessageCenterPage extends ConsumerStatefulWidget {
  const MessageCenterPage({super.key});

  @override
  ConsumerState<MessageCenterPage> createState() => _MessageCenterPageState();
}

class _MessageCenterPageState extends ConsumerState<MessageCenterPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  MessagePlatformFilter _platformFilter = MessagePlatformFilter.all;
  String _searchQuery = '';
  bool _bannerDismissed = false;
  int _retryKey = 0;
  late final DebouncedSearchController _debouncedSearch;

  @override
  void initState() {
    super.initState();
    _debouncedSearch = DebouncedSearchController(
      onQueryChanged: (q) {
        if (_searchQuery != q) setState(() => _searchQuery = q);
      },
    );
  }

  @override
  void dispose() {
    _debouncedSearch.dispose();
    super.dispose();
  }

  double _dockBottomReserve(BuildContext context) {
    final ts = MediaQuery.textScalerOf(context);
    final ratio =
        ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
    return 112 * ratio.clamp(1.0, 1.38);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final premium = PremiumThemeExtension.of(context);
    final officeId = ref.watch(teamChatOfficeIdProvider);
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
    final canManage = ref.watch(canManagePlatformIntegrationsProvider);
    final dockReserve = _dockBottomReserve(context);

    if (officeId == null || uid == null) {
      return TeamGeneralChannelBootstrap(
        child: PremiumShellBackdrop(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: PremiumMessagesPageHeader(
                      title: 'Mesaj Merkezi',
                      subtitle: 'Çok kanallı iletişim · müşteri mesajları',
                      showPreviewBadge: false,
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        ConsultantMessagesTokens.horizontal,
                        24,
                        ConsultantMessagesTokens.horizontal,
                        dockReserve,
                      ),
                      child: EmptyState(
                        premiumVisual: true,
                        grouped: true,
                        icon: Icons.domain_outlined,
                        title: 'Ofis bağlantısı gerekli',
                        subtitle:
                            'Ekip mesajlaşması için önce bir ofise bağlanmanız gerekir.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final channelsAsync = ref.watch(teamChannelsProvider);
    final membersAsync = ref.watch(officeTeamMemberProfilesProvider);
    final inboxAsync = ref.watch(teamChatInboxProvider(uid));

    return ShellScreenReadyListener(
      screenName: 'messages',
      provider: teamChannelsProvider,
      itemCount: (v) => (v as List).length,
      child: TeamGeneralChannelBootstrap(
        child: PremiumShellBackdrop(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Builder(
                key: ValueKey('messages_$_retryKey'),
                builder: (context) {
                  if (channelsAsync.isLoading && !channelsAsync.hasValue) {
                    return CustomScrollView(
                      slivers: [
                        ..._headerSlivers(
                          premium: premium,
                          canManage: canManage,
                          officeId: officeId,
                        ),
                        const SliverToBoxAdapter(child: MessageListSkeleton()),
                      ],
                    );
                  }

                  if (channelsAsync.hasError && !channelsAsync.hasValue) {
                    return CustomScrollView(
                      slivers: [
                        ..._headerSlivers(
                          premium: premium,
                          canManage: canManage,
                          officeId: officeId,
                        ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _MessagesErrorState(
                            onRetry: () {
                              ref.invalidate(teamChannelsProvider);
                              setState(() => _retryKey++);
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  final channels = channelsAsync.valueOrNull ?? [];
                  final members = membersAsync.valueOrNull ?? [];
                  final inbox = inboxAsync.valueOrNull ?? [];
                  final allItems = buildTeamConversationItems(
                    officeId: officeId,
                    currentUserId: uid,
                    channels: channels,
                    members: members,
                    inbox: inbox,
                  );
                  final summary = computeMessageListSummary(
                    items: allItems,
                    inbox: inbox,
                  );

                  if (_platformFilter.isExternalOnly) {
                    return _externalFilterBody(
                      context,
                      filter: _platformFilter,
                      canManage: canManage,
                      dockReserve: dockReserve,
                      premium: premium,
                      officeId: officeId,
                    );
                  }

                  final filtered =
                      filterTeamConversations(allItems, _searchQuery);

                  return CustomScrollView(
                    cacheExtent: 320,
                    slivers: [
                      ..._headerSlivers(
                        premium: premium,
                        canManage: canManage,
                        officeId: officeId,
                        summary: summary,
                        showTeamBanner: !_bannerDismissed,
                      ),
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              ConsultantMessagesTokens.horizontal,
                              16,
                              ConsultantMessagesTokens.horizontal,
                              dockReserve,
                            ),
                            child: EmptyState(
                              premiumVisual: true,
                              grouped: true,
                              icon: Icons.forum_outlined,
                              title: _searchQuery.isNotEmpty
                                  ? 'Sonuç yok'
                                  : 'Henüz mesaj yok',
                              subtitle: _searchQuery.isNotEmpty
                                  ? 'Aramayı değiştirin veya filtreyi sıfırlayın.'
                                  : 'Ekip üyeleriyle sohbet başlatın; mesajlar burada görünür.',
                              actionLabel: _searchQuery.isNotEmpty
                                  ? 'Filtreyi sıfırla'
                                  : null,
                              onAction:
                                  _searchQuery.isNotEmpty ? _resetFilters : null,
                              outlinedActionLabel:
                                  _searchQuery.isEmpty ? 'Çağrılarım' : null,
                              onOutlinedAction: _searchQuery.isEmpty
                                  ? () => ConsultantShellNav.goToCallsTab(
                                        context,
                                      )
                                  : null,
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            ConsultantMessagesTokens.horizontal,
                            0,
                            ConsultantMessagesTokens.horizontal,
                            dockReserve,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = filtered[index];
                                final snapshot =
                                    MessageConversationRowSnapshot.fromItem(
                                  item,
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: RepaintBoundary(
                                    child: MessageConversationCard(
                                      item: item,
                                      snapshot: snapshot,
                                      onTap: () => _openConversation(
                                        context,
                                        ref,
                                        item: item,
                                        officeId: officeId,
                                        currentUserId: uid,
                                        members: members,
                                      ),
                                      onOpen: () => _openConversation(
                                        context,
                                        ref,
                                        item: item,
                                        officeId: officeId,
                                        currentUserId: uid,
                                        members: members,
                                      ),
                                      onCall: () => _MessagesActions.call(
                                        context,
                                        item,
                                      ),
                                      onWhatsApp: () =>
                                          _MessagesActions.whatsApp(
                                        context,
                                        item,
                                      ),
                                      onMarkRead: () =>
                                          _MessagesActions.markRead(context),
                                    ),
                                  ),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _headerSlivers({
    required PremiumThemeExtension premium,
    required bool canManage,
    required String officeId,
    MessageListSummary? summary,
    bool showTeamBanner = true,
  }) {
    return [
      SliverToBoxAdapter(
        child: PremiumMessagesPageHeader(
          title: 'Mesaj Merkezi',
          subtitle: 'Çok kanallı iletişim · müşteri mesajları',
          actions: [
            if (canManage)
              IconButton(
                tooltip: 'Kanal ayarları',
                onPressed: () {
                  AppFeedback.lightImpact();
                  context.push(AppRouter.routeConnectedAccounts);
                },
                icon: Icon(
                  Icons.hub_outlined,
                  color: premium.champagneGold,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
      if (showTeamBanner)
        SliverToBoxAdapter(
          child: PremiumMessagesStatusBanner(
            message:
                'Önizleme modu — ekip sohbeti canlıdır. WhatsApp / Instagram / E-posta gönderimi için kanal bağlantısı gerekir.',
            icon: Icons.info_outline_rounded,
            onDismiss: () => setState(() => _bannerDismissed = true),
            actionLabel: canManage ? 'Kanal bağla' : null,
            onAction: canManage
                ? () => context.push(AppRouter.routeConnectedAccounts)
                : null,
          ),
        ),
      if (summary != null)
        SliverToBoxAdapter(
          child: PremiumMessagesSummaryStrip(summary: summary),
        ),
      SliverToBoxAdapter(
        child: PremiumMessageSearchRow(
          controller: _debouncedSearch.controller,
          hintText: 'Kişi veya mesaj ara',
        ),
      ),
      SliverToBoxAdapter(
        child: PremiumMessageFilterStrip(
          selected: _platformFilter,
          onSelected: (f) => setState(() => _platformFilter = f),
        ),
      ),
    ];
  }

  Widget _externalFilterBody(
    BuildContext context, {
    required MessagePlatformFilter filter,
    required bool canManage,
    required double dockReserve,
    required PremiumThemeExtension premium,
    required String officeId,
  }) {
    return CustomScrollView(
      slivers: [
        ..._headerSlivers(
          premium: premium,
          canManage: canManage,
          officeId: officeId,
          summary: MessageListSummary.empty,
          showTeamBanner: false,
        ),
        SliverToBoxAdapter(
          child: PremiumMessagesStatusBanner(
            message:
                'Kanal bağlantısı gerekli — ${filter.label} mesajları bu kanal bağlandığında görünecek.',
            icon: Icons.link_off_rounded,
            actionLabel: canManage ? 'Kanal bağla' : 'Önizleme',
            onAction: canManage
                ? () => context.push(AppRouter.routeConnectedAccounts)
                : () => showMessageExternalPreviewSheet(
                      context,
                      filter: filter,
                    ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              ConsultantMessagesTokens.horizontal,
              8,
              ConsultantMessagesTokens.horizontal,
              dockReserve,
            ),
            child: EmptyState(
              premiumVisual: true,
              grouped: true,
              icon: Icons.chat_outlined,
              title: 'Henüz mesaj yok',
              subtitle:
                  'Kanal bağlantısı kurulduğunda ${filter.label} mesajları burada görünür.',
              actionLabel: canManage ? 'Kanal bağla' : null,
              onAction: canManage
                  ? () => context.push(AppRouter.routeConnectedAccounts)
                  : null,
              outlinedActionLabel: 'Müşterilerim',
              onOutlinedAction: () =>
                  ConsultantShellNav.goToCustomersTab(context),
            ),
          ),
        ),
      ],
    );
  }

  void _resetFilters() {
    _debouncedSearch.controller.clear();
    setState(() {
      _searchQuery = '';
      _platformFilter = MessagePlatformFilter.all;
    });
  }

  static Future<void> _openConversation(
    BuildContext context,
    WidgetRef ref, {
    required MessageConversationListItem item,
    required String officeId,
    required String currentUserId,
    required List<TeamMemberProfile> members,
  }) async {
    if (!item.isTeamLive || item.channelId == null) return;
    AppFeedback.lightImpact();
    try {
      if (item.kind == MessageConversationKind.general) {
        await TeamChatRepository.ensureGeneralChannel(officeId);
      } else if (item.kind == MessageConversationKind.memberStart &&
          item.otherUserId != null) {
        await TeamChatRepository.ensureDirectChannel(
          officeId: officeId,
          currentUserId: currentUserId,
          otherUserId: item.otherUserId!,
        );
      }
      if (!context.mounted) return;
      var title = item.title;
      var subtitle = item.subtitle;
      if (item.kind == MessageConversationKind.direct &&
          item.otherUserId != null) {
        final match = members
            .where((m) => m.membership.userId == item.otherUserId)
            .firstOrNull;
        if (match != null) {
          title = match.displayName;
          subtitle = officeRoleLabel(match.membership.role);
        }
      }
      context.push(
        AppRouter.routeMessageThread,
        extra: <String, dynamic>{
          'officeId': officeId,
          'channelId': item.channelId,
          'title': title,
          'subtitle': subtitle,
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sohbet açılamadı. Lütfen tekrar deneyin.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _MessagesErrorState extends StatelessWidget {
  const _MessagesErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: EmptyState(
          compact: true,
          grouped: true,
          icon: Icons.cloud_off_outlined,
          title: 'Mesajlar yüklenemedi',
          subtitle: 'Bağlantınızı kontrol edip tekrar deneyin.',
          actionLabel: 'Tekrar dene',
          onAction: onRetry,
        ),
      ),
    );
  }
}

abstract final class _MessagesActions {
  static void call(BuildContext context, MessageConversationListItem item) {
    AppFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ekip üyesi araması için telefon bilgisi profilde tanımlı değil. Çağrılarım üzerinden müşteri arayın.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void whatsApp(BuildContext context, MessageConversationListItem item) {
    AppFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Mesaj gönderimi için kanal bağlantısı gerekli. Ekip sohbeti Tümü sekmesinde canlıdır.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void markRead(BuildContext context) {
    AppFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Okundu işaretleme yakında. Bildirimler gelmeye devam edebilir.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
