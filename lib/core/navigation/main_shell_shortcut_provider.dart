import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ana kabuk içinde bir sonraki karede hedef sekmeye git.
enum MainShellShortcut {
  openHomeTab,
  openMessageCenterTab,
  openCallsTab,
  openCustomersTab,
  openListingsTab,
  openFollowUpTab,
  openTasksTab,
  openFavoritesTab,
  openMessagesTab,
  openVirtualTourTab,
  openRequestsTab,
  openAccountTab,
}

class MainShellShortcutCommand {
  const MainShellShortcutCommand({
    required this.id,
    required this.shortcut,
  });

  final int id;
  final MainShellShortcut shortcut;
}

class MainShellShortcutQueueNotifier
    extends StateNotifier<List<MainShellShortcutCommand>> {
  MainShellShortcutQueueNotifier({
    List<MainShellShortcutCommand>? initialCommands,
  })  : _nextId = ((initialCommands?.fold<int>(
                  0,
                  (maxId, item) => item.id > maxId ? item.id : maxId,
                ) ??
                0) +
                1),
        super(List<MainShellShortcutCommand>.from(initialCommands ?? const []));

  int _nextId;

  void enqueue(MainShellShortcut shortcut) {
    state = [
      ...state,
      MainShellShortcutCommand(id: _nextId++, shortcut: shortcut),
    ];
  }

  void clear() {
    state = [];
  }

  MainShellShortcutCommand? takeFirstMatching(
    bool Function(MainShellShortcut shortcut) predicate,
  ) {
    final index = state.indexWhere((item) => predicate(item.shortcut));
    if (index < 0) return null;
    final match = state[index];
    final next = [...state]..removeAt(index);
    state = next;
    return match;
  }
}

final mainShellShortcutProvider =
    StateNotifierProvider<MainShellShortcutQueueNotifier,
        List<MainShellShortcutCommand>>(
  (ref) => MainShellShortcutQueueNotifier(),
);
