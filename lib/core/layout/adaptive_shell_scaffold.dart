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
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    widget.onIndexChanged?.call(index);
    _pageController.animateToPage(
      index,
      duration: DesignTokens.durationNormal,
      curve: Curves.easeInOut,
    );
  }

  /// Programatik sekme geçişi (ör. gösterge kartından Müşterilerim’e).
  void jumpToTab(int index) {
    if (index < 0 || index >= widget.navItems.length) return;
    if (index == _currentIndex) return;
    _onNavTap(index);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(mainShellShortcutProvider, (prev, next) {
      if (next == null) return;
      final idx = switch (next) {
        MainShellShortcut.openAccountTab =>
          widget.shortcutMap[next] ?? (widget.navItems.length - 1),
        MainShellShortcut.openHomeTab => widget.shortcutMap[next] ?? 0,
        _ => widget.shortcutMap[next] ?? -1,
      };
      ref.read(mainShellShortcutProvider.notifier).state = null;
      if (idx >= 0 && idx < widget.navItems.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _onNavTap(idx);
        });
      }
    });

    final isWide = AdaptiveShellScaffold.isWide(context);
    final theme = Theme.of(context);
    final ext = AppThemeExtension.of(context);
    final surface = ext.surface;
    final primary = theme.colorScheme.primary;
    final onSurfaceVariant = ext.textSecondary;

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
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) {
              setState(() => _currentIndex = i);
              widget.onIndexChanged?.call(i);
            },
            children: widget.pages,
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
              selectedIndex: _currentIndex,
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
                final isSelected = _currentIndex == i;
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
