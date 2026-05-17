import 'dart:developer' as developer;
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../navigation/app_exit_confirm.dart';
import '../navigation/app_back_dispatcher.dart';
import '../navigation/back_navigation_scope.dart';
import '../navigation/shell_navigation_host.dart';
import '../navigation/shell_tab_back_host.dart';
import '../navigation/tab_history_controller.dart';
import '../performance/shell_tab_keep_alive.dart';
import '../navigation/main_shell_shortcut_provider.dart';
import '../theme/app_theme_extension.dart';
import '../theme/design_tokens.dart';
import '../../widgets/premium/premium_bottom_nav_dock.dart';

/// Nav item for [AdaptiveShellScaffold].
class AdaptiveNavItem {
  const AdaptiveNavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// [navPageIndices] içinde menü açan “Daha Fazla” gibi öğeler için.
const int kShellNavMoreMenu = -1;

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
    this.navPageIndices,
    this.onMoreNavTap,
  });

  final List<AdaptiveNavItem> navItems;
  final List<Widget> pages;
  /// Alt menü / rail öğesi → [pages] indeksi. [kShellNavMoreMenu] menü açar.
  /// Verilmezse her nav öğesi kendi indeksine gider (nav.length == pages.length).
  final List<int>? navPageIndices;
  final VoidCallback? onMoreNavTap;
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
  final TabHistoryController _tabHistory = TabHistoryController();
  BackNavigationCallback? _tabBackHandler;

  /// Aktif [pages] indeksi (sekme geri kaydı için).
  int get activeTabIndex => _currentIndex;

  void registerTabBackHandler(int pageIndex, BackNavigationCallback? handler) {
    if (pageIndex != _currentIndex) return;
    _tabBackHandler = handler;
  }

  /// Uygulama içi geri — önce sekme içi mod, sonra sekme geçmişi.
  bool tryPopTabHistory() => _tryPopTabHistory();

  /// Yalnızca ziyaret edilen sekmeler gerçek widget ile oluşturulur.
  final Set<int> _materialized = {0};
  ProviderSubscription<List<MainShellShortcutCommand>>? _shortcutSub;
  bool _shortcutReplayScheduled = false;

  /// Aynı sekmede her frame log basmayı önler (yalnızca kDebugMode).
  int? _lastLoggedActiveIndex;
  int? _lastLoggedPageCount;

  bool get _traceEnabled => AppLogger.verboseDiagnosticsEnabled;

  void _shellLog(String msg) {
    if (!_traceEnabled) return;
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

  bool _isValidPageIndex(int idx) =>
      idx >= 0 && idx < widget.pages.length;

  int? _resolveShortcutIndex(MainShellShortcut shortcut) {
    final navLen = widget.navItems.length;
    final idx = switch (shortcut) {
      MainShellShortcut.openAccountTab => widget.navPageIndices != null
          ? widget.shortcutMap[shortcut]
          : widget.shortcutMap[shortcut] ?? (navLen > 0 ? navLen - 1 : -1),
      MainShellShortcut.openHomeTab => widget.shortcutMap[shortcut] ?? 0,
      _ => widget.shortcutMap[shortcut] ?? -1,
    };
    if (idx == null || idx < 0) return null;
    if (!_isValidPageIndex(idx)) return null;
    if (widget.navPageIndices == null && idx >= navLen) return null;
    return idx;
  }

  int _bottomNavSelectedIndex(int pageIndex) {
    final map = widget.navPageIndices;
    if (map == null) return pageIndex;
    final direct = map.indexOf(pageIndex);
    if (direct >= 0) return direct;
    final more = map.indexOf(kShellNavMoreMenu);
    if (more >= 0) return more;
    return pageIndex.clamp(0, widget.navItems.length - 1);
  }

  int? _pageIndexForNavTap(int navIndex) {
    final map = widget.navPageIndices;
    if (map == null) return navIndex;
    if (navIndex < 0 || navIndex >= map.length) return null;
    final page = map[navIndex];
    if (page == kShellNavMoreMenu) return null;
    return page;
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
    if (_traceEnabled) {
      developer.log(
        'queued shortcut replay id=${command.id} shortcut=${command.shortcut} idx=$idx '
        '(current=$_currentIndex)',
        name: 'ShellNav.shortcut',
      );
    }
    _applyTabSelection(
      idx,
      source: 'queuedShortcut(${command.shortcut})',
      haptic: false,
      recordHistory: false,
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

  Future<void> _onShellSystemBack() async {
    await AppBackDispatcher.handleShellSystemBack(
      context,
      tryPopTab: _tryPopTabHistory,
      onExitApp: () => maybeExitApplication(context),
    );
  }

  bool _tryPopTabHistory() {
    if (_tabBackHandler?.call() == true) return true;
    final prev = _tabHistory.popTab();
    if (prev == null) return false;
    _applyTabSelection(
      prev,
      source: 'systemBackTab',
      haptic: false,
      recordHistory: false,
    );
    return true;
  }

  void _applyTabSelection(
    int pageIndex, {
    required String source,
    bool haptic = true,
    bool recordHistory = true,
  }) {
    final navHighlight = _bottomNavSelectedIndex(pageIndex);
    final label = navHighlight >= 0 && navHighlight < widget.navItems.length
        ? widget.navItems[navHighlight].label
        : '?';
    if (_traceEnabled) {
      developer.log(
        '$source received label="$label" targetPage=$pageIndex selectedBefore=$_currentIndex '
        'pageLen=${widget.pages.length} navLen=${widget.navItems.length}',
        name: 'ShellNav.tap',
      );
    }
    if (widget.pages.isEmpty || widget.navItems.isEmpty) {
      _shellLog('onNavTap ignored: empty nav/pages');
      return;
    }
    if (!_isValidPageIndex(pageIndex)) {
      _shellLog(
        'onNavTap reject pageIndex=$pageIndex pageLen=${widget.pages.length}',
      );
      return;
    }
    if (pageIndex == _currentIndex) {
      if (_traceEnabled) {
        developer.log(
          '$source noop (already on page=$pageIndex label="$label")',
          name: 'ShellNav.tap',
        );
      }
      return;
    }
    if (haptic) {
      AppFeedback.lightImpact();
    }
    if (recordHistory) {
      _tabHistory.recordVisit(pageIndex);
    } else {
      _tabHistory.jumpWithoutHistory(pageIndex);
    }
    _shellLog(
      '$source pageIndex=$pageIndex (was $_currentIndex) tabId=${_tabIdentityFor(widget, pageIndex)}',
    );
    setState(() {
      _currentIndex = pageIndex;
      _materialized.add(pageIndex);
    });
    if (_traceEnabled) {
      developer.log(
        '$source applied selectedAfter=$_currentIndex resolvedPage='
        '${pageIndex < widget.pages.length ? widget.pages[pageIndex].runtimeType : "?"}',
        name: 'ShellNav.tap',
      );
    }
    widget.onIndexChanged?.call(pageIndex);
  }

  void _onNavTap(int navIndex) {
    final page = _pageIndexForNavTap(navIndex);
    if (page == null) {
      AppFeedback.lightImpact();
      widget.onMoreNavTap?.call();
      return;
    }
    _applyTabSelection(page, source: 'navTap');
  }

  /// Programatik sekme geçişi — [pages] indeksine gider (gizli sekmeler dahil).
  void jumpToTab(int pageIndex, {bool recordHistory = true}) {
    if (widget.pages.isEmpty) {
      _shellLog('jumpToTab noop: empty pages');
      return;
    }
    if (!_isValidPageIndex(pageIndex)) {
      _shellLog(
        'jumpToTab reject pageIndex=$pageIndex pageLen=${widget.pages.length}',
      );
      return;
    }
    if (pageIndex == _currentIndex) return;
    _shellLog('jumpToTab page=$pageIndex (was $_currentIndex)');
    _applyTabSelection(
      pageIndex,
      source: 'jumpToTab',
      haptic: false,
      recordHistory: recordHistory,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.length != widget.navItems.length &&
        widget.navPageIndices == null) {
      _shellLog(
        'BUILD WARNING pages=${widget.pages.length} nav=${widget.navItems.length} — mismatch can blank content',
      );
    }
    if (widget.navPageIndices != null &&
        widget.navPageIndices!.length != widget.navItems.length) {
      _shellLog(
        'BUILD WARNING navPageIndices=${widget.navPageIndices!.length} nav=${widget.navItems.length}',
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
    final navUnselectedColor = theme.brightness == Brightness.dark
        ? ext.textSecondary
        : ext.textPassive;

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
    final selectedNavIndex =
        _bottomNavSelectedIndex(safeIndex).clamp(0, widget.navItems.length - 1);
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
                        ? ShellTabBackHost(
                            pageIndex: i,
                            child: ShellTabKeepAlive(
                              child: widget.pages[i],
                            ),
                          )
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

    Widget shell = isWide
        ? Scaffold(
        backgroundColor: ext.background,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedNavIndex,
              onDestinationSelected: _onNavTap,
              backgroundColor: surface,
              selectedIconTheme: IconThemeData(color: primary, size: 24),
              unselectedIconTheme:
                  IconThemeData(color: navUnselectedColor, size: 22),
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
      )
        : Scaffold(
      backgroundColor: ext.background,
      body: body,
      floatingActionButton: widget.fab,
      floatingActionButtonLocation:
          widget.fabLocation ?? FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: ColoredBox(
        color: Colors.transparent,
        child: PremiumBottomNavDock(
          items: widget.navItems,
          selectedIndex: selectedNavIndex,
          onTap: _onNavTap,
        ),
      ),
    );

    shell = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onShellSystemBack();
      },
      child: ShellNavigationHost(
        onShellSystemBack: _onShellSystemBack,
        child: shell,
      ),
    );
    return shell;
  }
}
