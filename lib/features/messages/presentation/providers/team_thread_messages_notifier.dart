import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/messages/data/team_chat_repository.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_message_entity.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_message_page.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/providers/team_chat_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeamThreadMessagesState {
  const TeamThreadMessagesState({
    this.liveMessages = const [],
    this.olderMessages = const [],
    this.oldestLiveDoc,
    this.oldestOlderDoc,
    this.hasMoreOlder = true,
    this.isInitialLoading = true,
    this.isLoadingOlder = false,
    this.error,
  });

  final List<TeamMessage> liveMessages;
  final List<TeamMessage> olderMessages;
  final DocumentSnapshot<Map<String, dynamic>>? oldestLiveDoc;
  final DocumentSnapshot<Map<String, dynamic>>? oldestOlderDoc;
  final bool hasMoreOlder;
  final bool isInitialLoading;
  final bool isLoadingOlder;
  final Object? error;

  List<TeamMessage> get allMessages =>
      TeamThreadMessagesNotifier.mergeMessages(olderMessages, liveMessages);

  DocumentSnapshot<Map<String, dynamic>>? get paginationCursor =>
      oldestOlderDoc ?? oldestLiveDoc;

  TeamThreadMessagesState copyWith({
    List<TeamMessage>? liveMessages,
    List<TeamMessage>? olderMessages,
    DocumentSnapshot<Map<String, dynamic>>? oldestLiveDoc,
    DocumentSnapshot<Map<String, dynamic>>? oldestOlderDoc,
    bool? hasMoreOlder,
    bool? isInitialLoading,
    bool? isLoadingOlder,
    Object? error,
    bool clearError = false,
  }) {
    return TeamThreadMessagesState(
      liveMessages: liveMessages ?? this.liveMessages,
      olderMessages: olderMessages ?? this.olderMessages,
      oldestLiveDoc: oldestLiveDoc ?? this.oldestLiveDoc,
      oldestOlderDoc: oldestOlderDoc ?? this.oldestOlderDoc,
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final teamThreadMessagesProvider = NotifierProvider.autoDispose
    .family<TeamThreadMessagesNotifier, TeamThreadMessagesState, TeamThreadArgs>(
  TeamThreadMessagesNotifier.new,
);

class TeamThreadMessagesNotifier
    extends AutoDisposeFamilyNotifier<TeamThreadMessagesState, TeamThreadArgs> {
  StreamSubscription<TeamMessagePage>? _liveSub;

  @override
  TeamThreadMessagesState build(TeamThreadArgs arg) {
    ref.onDispose(() {
      unawaited(_liveSub?.cancel());
    });
    Future.microtask(_subscribeLive);
    return const TeamThreadMessagesState();
  }

  void _subscribeLive() {
    unawaited(_liveSub?.cancel());
    _liveSub = TeamChatRepository.watchRecentMessages(
      arg.officeId,
      arg.channelId,
    ).listen(
      (page) {
        state = state.copyWith(
          liveMessages: page.messages,
          oldestLiveDoc: page.oldestDoc,
          hasMoreOlder: state.hasMoreOlder || page.hasMore,
          isInitialLoading: false,
          clearError: true,
        );
      },
      onError: (Object e) {
        state = state.copyWith(
          error: e,
          isInitialLoading: false,
        );
      },
    );
  }

  Future<void> loadOlder() async {
    if (state.isLoadingOlder || !state.hasMoreOlder) return;
    final cursor = state.paginationCursor;
    if (cursor == null) {
      state = state.copyWith(hasMoreOlder: false);
      return;
    }
    state = state.copyWith(isLoadingOlder: true, clearError: true);
    try {
      final page = await TeamChatRepository.fetchOlderMessages(
        officeId: arg.officeId,
        channelId: arg.channelId,
        startAfter: cursor,
      );
      state = state.copyWith(
        olderMessages: mergeMessages(state.olderMessages, page.messages),
        oldestOlderDoc: page.oldestDoc ?? state.oldestOlderDoc,
        hasMoreOlder: page.hasMore,
        isLoadingOlder: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingOlder: false,
        error: e,
      );
    }
  }

  /// Eski + canlı listeleri birleştirir; `id` ile tekilleştirir; en yeni önce sıralar.
  static List<TeamMessage> mergeMessages(
    List<TeamMessage> older,
    List<TeamMessage> live,
  ) {
    final map = <String, TeamMessage>{};
    for (final m in older) {
      map[m.id] = m;
    }
    for (final m in live) {
      map[m.id] = m;
    }
    final merged = map.values.toList()
      ..sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
    return List.unmodifiable(merged);
  }
}
