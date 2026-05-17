import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/messages/data/team_chat_presence.dart';
import 'package:emlakmaster_mobile/features/messages/data/team_chat_repository.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_message_entity.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/providers/team_chat_providers.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/providers/team_thread_messages_notifier.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Ofis ekibi — gerçek zamanlı metin sohbeti.
class TeamThreadPage extends ConsumerStatefulWidget {
  const TeamThreadPage({
    super.key,
    required this.officeId,
    required this.channelId,
    required this.title,
    this.subtitle = '',
  });

  final String officeId;
  final String channelId;
  final String title;
  final String subtitle;

  @override
  ConsumerState<TeamThreadPage> createState() => _TeamThreadPageState();
}

class _TeamThreadPageState extends ConsumerState<TeamThreadPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;
  int _lastMessageCount = 0;

  TeamThreadArgs get _args => TeamThreadArgs(
        officeId: widget.officeId,
        channelId: widget.channelId,
      );

  @override
  void initState() {
    super.initState();
    TeamChatPresence.setActive(
      officeId: widget.officeId,
      channelId: widget.channelId,
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    TeamChatPresence.clearActive();
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 48) return;
    ref.read(teamThreadMessagesProvider(_args).notifier).loadOlder();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty || _sending) return;
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _sending = true);
    try {
      await TeamChatRepository.sendTextMessage(
        officeId: widget.officeId,
        channelId: widget.channelId,
        senderId: uid,
        text: text,
      );
      _controller.clear();
      await AppFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj gönderilemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final scheme = Theme.of(context).colorScheme;
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid;

    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  const PremiumNavLeading(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: ext.foreground,
                                fontWeight: FontWeight.w800,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.subtitle.isNotEmpty)
                          Text(
                            widget.subtitle,
                            style: TextStyle(color: ext.foregroundMuted, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _TeamMessageList(
                args: _args,
                currentUserId: uid,
                scrollController: _scrollController,
                lastMessageCount: _lastMessageCount,
                onMessageCountChanged: (count) => _lastMessageCount = count,
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: ext.surface,
                border: Border(top: BorderSide(color: ext.border.withValues(alpha: 0.5))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Mesaj yazın…',
                        filled: true,
                        fillColor: ext.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                          borderSide: BorderSide(color: ext.border.withValues(alpha: 0.45)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                          borderSide: BorderSide(color: ext.border.withValues(alpha: 0.45)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: ext.onBrand,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: _sending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ext.onBrand,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMessageList extends ConsumerStatefulWidget {
  const _TeamMessageList({
    required this.args,
    required this.currentUserId,
    required this.scrollController,
    required this.lastMessageCount,
    required this.onMessageCountChanged,
  });

  final TeamThreadArgs args;
  final String? currentUserId;
  final ScrollController scrollController;
  final int lastMessageCount;
  final ValueChanged<int> onMessageCountChanged;

  @override
  ConsumerState<_TeamMessageList> createState() => _TeamMessageListState();
}

class _TeamMessageListState extends ConsumerState<_TeamMessageList> {
  void _maybeScrollToLatest(List<TeamMessage> messages) {
    if (messages.length <= widget.lastMessageCount) {
      widget.onMessageCountChanged(messages.length);
      return;
    }
    final wasEmpty = widget.lastMessageCount == 0;
    widget.onMessageCountChanged(messages.length);
    final controller = widget.scrollController;
    if (!controller.hasClients) return;
    final nearBottom = controller.offset < 120;
    if (!wasEmpty && !nearBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasClients) return;
      controller.jumpTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final threadState = ref.watch(teamThreadMessagesProvider(widget.args));

    if (threadState.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (threadState.error != null && threadState.allMessages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Mesajlar yüklenemedi.\n${threadState.error}',
            textAlign: TextAlign.center,
            style: TextStyle(color: ext.foregroundSecondary),
          ),
        ),
      );
    }

    final messages = threadState.allMessages;
    _maybeScrollToLatest(messages);

    if (messages.isEmpty) {
      return Center(
        child: Text(
          'İlk mesajı siz gönderin',
          style: TextStyle(color: ext.foregroundMuted),
        ),
      );
    }

    final headerCount = (threadState.isLoadingOlder ? 1 : 0) +
        (threadState.hasMoreOlder && !threadState.isLoadingOlder ? 1 : 0);

    return ListView.builder(
      controller: widget.scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      cacheExtent: 480,
      itemCount: messages.length + headerCount,
      itemBuilder: (context, index) {
        if (threadState.isLoadingOlder && index == messages.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (threadState.hasMoreOlder &&
            !threadState.isLoadingOlder &&
            index == messages.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(
              child: TextButton.icon(
                onPressed: () =>
                    ref.read(teamThreadMessagesProvider(widget.args).notifier).loadOlder(),
                icon: const Icon(Icons.expand_less_rounded, size: 18),
                label: const Text('Daha eski mesajlar'),
              ),
            ),
          );
        }

        final msg = messages[index];
        final isMine = msg.senderId == widget.currentUserId;
        return RepaintBoundary(
          child: _Bubble(
            alignRight: isMine,
            text: msg.text,
            time: _formatTime(msg.createdAt),
          ),
        );
      },
    );
  }

  static String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat.Hm().format(dt);
    }
    return DateFormat('d MMM HH:mm', 'tr').format(dt);
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.alignRight,
    required this.text,
    required this.time,
  });

  final bool alignRight;
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: alignRight ? scheme.primary.withValues(alpha: 0.22) : ext.surfaceElevated,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(alignRight ? 18 : 4),
            bottomRight: Radius.circular(alignRight ? 4 : 18),
          ),
          border: Border.all(color: ext.border.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(color: ext.foreground, fontSize: 15, height: 1.35),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(time, style: TextStyle(color: ext.foregroundMuted, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}
