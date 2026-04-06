import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ana kabuk içinde bir sonraki karede hedef sekmeye git.
enum MainShellShortcut {
  openHomeTab,
  openCallsTab,
  openCustomersTab,
  openListingsTab,
  openFollowUpTab,
  openTasksTab,
  openFavoritesTab,
  openMessagesTab,
  openVirtualTourTab,
  openAccountTab,
}

final mainShellShortcutProvider =
    StateProvider<MainShellShortcut?>((ref) => null);
