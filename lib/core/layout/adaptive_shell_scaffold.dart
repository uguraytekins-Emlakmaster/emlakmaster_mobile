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
    this.title,
    this.actions,
    this.fab,
    this.fabLocation,
    this.onIndexChanged,
    this.shortcutMap = const {},
  });

  final List<AdaptiveNavItem> navItems;
  final List<Widget> pages;
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
  ProviderSubscription<MainShellShortcut?>? _shortcutSub;

  void _shellLog(String msg) {
    debugPrint('[ShellNav] $msg');
  }

  @override
  void initState() {
    super.initState();
    _shortcutSub = ref.listenManual<MainShellShortcut?>(
      mainShellShortcutProvider,
      (prev, next) {
        if (next == null) return;
        final navLen = widget.navItems.length;
        final pageLen = widget.pages.length;
        final idx = switch (next) {
          MainShellShortcut.openAccountTab =>
            widget.shortcutMap[next] ?? (navLen > 0 ? navLen - 1 : -1),
          MainShellShortcut.openHomeTab => widget.shortcutMap[next] ?? 0,
          _ => widget.shortcutMap[next] ?? -1,
        };
        ref.read(mainShellShortcutProvider.notifier).state = null;
        if (idx < 0 || idx >= navLen || idx >= pageLen) {
          _shellLog(
            'shortcut reject idx=$idx navLen=$navLen pageLen=$pageLen shortcut=$next',
          );
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _onNavTap(idx);
        });
      },
    );
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
    if (oldWidget.pages.length != len) {
      _pruneMaterialized(len);
      _materialized.add(_currentIndex.clamp(0, len - 1));
    }
  }

  void _pruneMaterialized(int pageLen) {
    _materialized.removeWhere((i) => i < 0 || i >= pageLen);
    if (_materialized.isEmpty) _materialized.add(0);
  }

  void _onNavTap(int index) {
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
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    _shellLog('onNavTap $index (was $_currentIndex)');
    setState(() {
      _currentIndex = index;
      _materialized.add(index);
    });
    widget.onIndexChanged?.call(index);
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
    _onNavTap(index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.length != widget.navItems.length) {
      _shellLog(
        'BUILD WARNING pages=${widget.pages.length} nav=${widget.navItems.length} — mismatch can blank content',
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

    final safeIndex = _currentIndex.clamp(0, widget.pages.length - 1);
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
                        : ColoredBox(
                            color: ext.background,
                            child: const SizedBox.expand(),
                          ),
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
