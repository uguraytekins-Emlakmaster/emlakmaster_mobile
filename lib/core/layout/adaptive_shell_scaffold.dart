import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/main_shell_shortcut_provider.dart';
import '../theme/app_theme_extension.dart';
import '../theme/design_tokens.dart';

/// Nav item for [AdaptiveShellScaffold].
class AdaptiveNavItem {
  const AdaptiveNavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Web/Desktop: sidebar (NavigationRail). Mobile: bottom nav.
/// RBAC-agnostic; used by Admin, Consultant, and Client shells.
///
/// Sekme içeriği [IndexedStack] ile gösterilir (PageView değil): PageView + ilk sayfa
/// bazı cihazlarda gövdeyi boş/siyah bırakabiliyordu; indeks doğrudan içeriği seçer.
///
/// Ağır sekmeler (Dashboard, War Room, …) **ilk açılışta tek tek** oluşturulur; aksi halde
/// tüm sayfalar aynı anda mount olup ana izolatta kilitlenmeye yol açabiliyordu.
class AdaptiveShellScaffold extends ConsumerStatefulWidget {
  const AdaptiveShellScaffold({
    super.key,
    required this.navItems,
    required this.pages,
    this.tabIds,
    this.title,
    this.actions,
    this.fab,
    this.fabLocation,
    this.onIndexChanged,
    this.shortcutMap = const {},
  });

  final List<AdaptiveNavItem> navItems;
  final List<Widget> pages;
  final List<Object>? tabIds;
  final String? title;
  final List<Widget>? actions;
  final Widget? fab;
  final FloatingActionButtonLocation? fabLocation;
  final void Function(int index)? onIndexChanged;
  final Map<MainShellShortcut, int> shortcutMap;

  /// True when width >= [DesignTokens.breakpointWide] (sidebar layout).
  static bool isWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= DesignTokens.breakpointWide;
  }

  @override
  ConsumerState<AdaptiveShellScaffold> createState() =>
      AdaptiveShellScaffoldState();
}

class AdaptiveShellScaffoldState extends ConsumerState<AdaptiveShellScaffold> {
  int _currentIndex = 0;

  /// Yalnızca ziyaret edilen sekmeler gerçek widget ile oluşturulur.
  final Set<int> _materialized = {0};
  ProviderSubscription<List<MainShellShortcutCommand>>? _shortcutSub;
  bool _shortcutReplayScheduled = false;

  /// Aynı sekmede her frame log basmayı önler (yalnızca kDebugMode).
  int? _lastLoggedActiveIndex;
  int? _lastLoggedPageCount;

  void _shellLog(String msg) {
    debugPrint('[ShellNav] $msg');
  }

  int _clampIndex(int index, int maxInclusive) {
    return index.clamp(0, maxInclusive).toInt();
  }

  Object _tabIdentityFor(AdaptiveShellScaffold widget, int index) {
    final ids = widget.tabIds;
    if (ids != null && index >= 0 && index < ids.length) {
      return ids[index];
    }
    return index;
  }

  int? _resolveShortcutIndex(MainShellShortcut shortcut) {
    final navLen = widget.navItems.length;
    final pageLen = widget.pages.length;
    final idx = switch (shortcut) {
      MainShellShortcut.openAccountTab =>
        widget.shortcutMap[shortcut] ?? (navLen > 0 ? navLen - 1 : -1),
      MainShellShortcut.openHomeTab => widget.shortcutMap[shortcut] ?? 0,
      _ => widget.shortcutMap[shortcut] ?? -1,
    };
    if (idx < 0 || idx >= navLen || idx >= pageLen) {
      return null;
    }
    return idx;
  }

  bool _hasReplayableShortcut() {
    final queued = ref.read(mainShellShortcutProvider);
    for (final command in queued) {
      if (_resolveShortcutIndex(command.shortcut) != null) {
        return true;
      }
    }
    return false;
  }

  void _scheduleShortcutReplay() {
    if (_shortcutReplayScheduled) return;
    _shortcutReplayScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shortcutReplayScheduled = false;
      if (!mounted) return;
      _replayNextQueuedShortcut();
    });
  }

  void _replayNextQueuedShortcut() {
    final command = ref.read(mainShellShortcutProvider.notifier).takeFirstMatching(
      (shortcut) => _resolveShortcutIndex(shortcut) != null,
    );
    if (command == null) return;
    final idx = _resolveShortcutIndex(command.shortcut);
    if (idx == null) {
      _shellLog(
        'queued shortcut became invalid id=${command.id} shortcut=${command.shortcut}',
      );
      return;
    }
    developer.log(
      'queued shortcut replay id=${command.id} shortcut=${command.shortcut} idx=$idx '
      '(current=$_currentIndex)',
      name: 'ShellNav.shortcut',
    );
    _applyTabSelection(
      idx,
      source: 'queuedShortcut(${command.shortcut})',
      haptic: false,
    );
    if (_hasReplayableShortcut()) {
      _scheduleShortcutReplay();
    }
  }

  Widget _inactiveSlotPlaceholder(BuildContext context, int tabIndex) {
    final ext = AppThemeExtension.of(context);
    return ColoredBox(
      color: ext.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: ext.accent.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: DesignTokens.space3),
              Text(
                'Sekme hazırlanıyor…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: DesignTokens.space2),
                Text(
                  'index=$tabIndex',
                  style: TextStyle(
                    color: ext.textTertiary.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _maybeLogActivePage(int safeIndex) {
    if (!kDebugMode) return;
    final len = widget.pages.length;
    if (_lastLoggedActiveIndex == safeIndex && _lastLoggedPageCount == len) {
      return;
    }
    _lastLoggedActiveIndex = safeIndex;
    _lastLoggedPageCount = len;
    final label = safeIndex < widget.navItems.length
        ? widget.navItems[safeIndex].label
        : '?';
    final type = safeIndex < widget.pages.length
        ? widget.pages[safeIndex].runtimeType.toString()
        : 'out_of_range';
    _shellLog(
      'body activeIndex=$safeIndex label="$label" pageType=$type pageLen=$len materialized=$_materialized',
    );
  }

  @override
  void initState() {
    super.initState();
    _shortcutSub = ref.listenManual<List<MainShellShortcutCommand>>(
      mainShellShortcutProvider,
      (prev, next) {
        if (next.isEmpty) return;
        _scheduleShortcutReplay();
      },
    );
    _shellLog(
      'shell init pageLen=${widget.pages.length} navLen=${widget.navItems.length} '
      'startIndex=$_currentIndex startTabId=${_tabIdentityFor(widget, _currentIndex)} '
      'materialized=$_materialized',
    );
    _scheduleShortcutReplay();
  }

  @override
  void dispose() {
    _shortcutSub?.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AdaptiveShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    final len = widget.pages.length;
    if (len == 0) {
      _shellLog('didUpdateWidget: pages empty');
      return;
    }
    if (_currentIndex >= len) {
      final newIdx = len - 1;
      _shellLog(
        'clamp tab index $_currentIndex -> $newIdx (navLen=${widget.navItems.length} pageLen=$len)',
      );
      setState(() {
        _currentIndex = newIdx;
        _pruneMaterialized(len);
        _materialized.add(newIdx);
      });
      return;
    }
    final previousSelectedId =
        oldWidget.pages.isNotEmpty && oldWidget.navItems.isNotEmpty
            ? _tabIdentityFor(
                oldWidget,
                _clampIndex(_currentIndex, oldWidget.pages.length - 1),
              )
            : null;
    if (widget.tabIds != null &&
        oldWidget.tabIds != null &&
        previousSelectedId != null) {
      final rebasedIndex = widget.tabIds!.indexOf(previousSelectedId);
      if (rebasedIndex >= 0 && rebasedIndex != _currentIndex) {
        _shellLog(
          'rebase selected tab id=$previousSelectedId oldIndex=$_currentIndex -> newIndex=$rebasedIndex',
        );
        setState(() {
          _currentIndex = rebasedIndex;
          _pruneMaterialized(len);
          _materialized.add(rebasedIndex);
        });
        return;
      }
    }
    if (oldWidget.pages.length != len) {
      _pruneMaterialized(len);
      _materialized.add(_clampIndex(_currentIndex, len - 1));
      _lastLoggedActiveIndex = null;
      _lastLoggedPageCount = null;
      _scheduleShortcutReplay();
    }
  }

  void _pruneMaterialized(int pageLen) {
    _materialized.removeWhere((i) => i < 0 || i >= pageLen);
    if (_materialized.isEmpty) _materialized.add(0);
  }

  void _applyTabSelection(
    int index, {
    required String source,
    bool haptic = true,
  }) {
    final label = index >= 0 && index < widget.navItems.length
        ? widget.navItems[index].label
        : '?';
    developer.log(
      '$source received label="$label" targetIndex=$index selectedBefore=$_currentIndex '
      'pageLen=${widget.pages.length} navLen=${widget.navItems.length}',
      name: 'ShellNav.tap',
    );
    if (widget.pages.isEmpty || widget.navItems.isEmpty) {
      _shellLog('onNavTap ignored: empty nav/pages');
      return;
    }
    if (index < 0 || index >= widget.pages.length) {
      _shellLog(
        'onNavTap reject index=$index pageLen=${widget.pages.length} navLen=${widget.navItems.length}',
      );
      return;
    }
    if (index >= widget.navItems.length) {
      _shellLog(
          'onNavTap reject index=$index vs navLen=${widget.navItems.length}');
      return;
    }
    if (index == _currentIndex) {
      developer.log(
        '$source noop (already on index=$index label="$label")',
        name: 'ShellNav.tap',
      );
      return;
    }
    if (haptic) {
      HapticFeedback.lightImpact();
    }
    _shellLog(
      '$source index=$index (was $_currentIndex) tabId=${_tabIdentityFor(widget, index)}',
    );
    setState(() {
      _currentIndex = index;
      _materialized.add(index);
    });
    developer.log(
      '$source applied selectedAfter=$_currentIndex resolvedPage='
      '${index < widget.pages.length ? widget.pages[index].runtimeType : "?"}',
      name: 'ShellNav.tap',
    );
    widget.onIndexChanged?.call(index);
  }

  void _onNavTap(int index) {
    _applyTabSelection(index, source: 'navTap');
  }

  /// Programatik sekme geçişi (ör. gösterge kartından Müşterilerim’e).
  void jumpToTab(int index) {
    if (widget.navItems.isEmpty || widget.pages.isEmpty) {
      _shellLog('jumpToTab noop: empty nav/pages');
      return;
    }
    if (index < 0 || index >= widget.navItems.length) {
      _shellLog(
        'jumpToTab reject index=$index navLen=${widget.navItems.length}',
      );
      return;
    }
    if (index >= widget.pages.length) {
      _shellLog(
        'jumpToTab reject index=$index pageLen=${widget.pages.length} (nav/page mismatch)',
      );
      return;
    }
    if (index == _currentIndex) return;
    _shellLog('jumpToTab $index (was $_currentIndex)');
    _applyTabSelection(index, source: 'jumpToTab', haptic: false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.length != widget.navItems.length) {
      _shellLog(
        'BUILD WARNING pages=${widget.pages.length} nav=${widget.navItems.length} — mismatch can blank content',
      );
    }
    if (widget.tabIds != null && widget.tabIds!.length != widget.pages.length) {
      _shellLog(
        'BUILD WARNING tabIds=${widget.tabIds!.length} pages=${widget.pages.length} — mismatch can drift selection',
      );
    }

    final isWide = AdaptiveShellScaffold.isWide(context);
    final theme = Theme.of(context);
    final ext = AppThemeExtension.of(context);
    final surface = ext.surface;
    final primary = theme.colorScheme.primary;
    final onSurfaceVariant = ext.textSecondary;

    if (widget.pages.isEmpty || widget.navItems.isEmpty) {
      _shellLog('build: empty pages — showing fallback scaffold');
      return Scaffold(
        backgroundColor: ext.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: ext.textSecondary,
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  'Gezinme yapılandırması eksik.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: DesignTokens.space2),
                Text(
                  'Sekme listesi boş döndü. Uygulamayı yeniden başlatın veya destek ile iletişime geçin.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ext.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final safeIndex = _clampIndex(_currentIndex, widget.pages.length - 1);
    if (!_materialized.contains(safeIndex)) {
      _shellLog(
        'fallback: active index $safeIndex was not materialized — scheduling fix',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_materialized.contains(safeIndex)) {
          setState(() => _materialized.add(safeIndex));
        }
      });
    }
    _maybeLogActivePage(safeIndex);
    final body = Column(
      children: [
        if (widget.title != null && isWide)
          Padding(
            padding: const EdgeInsets.fromLTRB(DesignTokens.space4,
                DesignTokens.space4, DesignTokens.space4, DesignTokens.space2),
            child: Row(
              children: [
                Text(
                  widget.title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.actions != null) ...[
                  const Spacer(),
                  ...widget.actions!,
                ],
              ],
            ),
          ),
        Expanded(
          child: IndexedStack(
            index: safeIndex,
            sizing: StackFit.expand,
            children: [
              for (var i = 0; i < widget.pages.length; i++)
                IgnorePointer(
                  ignoring: i != safeIndex,
                  child: TickerMode(
                    enabled: i == safeIndex,
                    child: _materialized.contains(i)
                        ? widget.pages[i]
                        : (i == safeIndex
                            ? _inactiveSlotPlaceholder(context, i)
                            : ColoredBox(
                                color: ext.background,
                                child: const SizedBox.expand(),
                              )),
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    if (isWide) {
      return Scaffold(
        backgroundColor: ext.background,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: safeIndex,
              onDestinationSelected: _onNavTap,
              backgroundColor: surface,
              selectedIconTheme: IconThemeData(color: primary, size: 24),
              unselectedIconTheme:
                  IconThemeData(color: onSurfaceVariant, size: 22),
              labelType: NavigationRailLabelType.all,
              destinations: widget.navItems
                  .map((e) => NavigationRailDestination(
                        icon: Icon(e.icon),
                        selectedIcon: Icon(e.icon),
                        label: Text(e.label),
                      ))
                  .toList(),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: ext.background,
      body: body,
      floatingActionButton: widget.fab,
      floatingActionButtonLocation:
          widget.fabLocation ?? FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(
              top: BorderSide(color: ext.border.withValues(alpha: 0.55))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(widget.navItems.length, (i) {
                final item = widget.navItems[i];
                final isSelected = safeIndex == i;
                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onNavTap(i),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMd),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: 22,
                              color: isSelected ? primary : onSurfaceVariant,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected ? primary : onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
