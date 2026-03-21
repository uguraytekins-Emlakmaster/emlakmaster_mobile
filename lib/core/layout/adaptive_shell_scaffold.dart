import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';

/// Nav item for [AdaptiveShellScaffold].
class AdaptiveNavItem {
  const AdaptiveNavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Web/Desktop: sidebar (NavigationRail). Mobile: bottom nav.
/// RBAC-agnostic; used by Admin, Consultant, and Client shells.
class AdaptiveShellScaffold extends StatefulWidget {
  const AdaptiveShellScaffold({
    super.key,
    required this.navItems,
    required this.pages,
    this.title,
    this.actions,
    this.fab,
    this.fabLocation,
    this.onIndexChanged,
  });

  final List<AdaptiveNavItem> navItems;
  final List<Widget> pages;
  final String? title;
  final List<Widget>? actions;
  final Widget? fab;
  final FloatingActionButtonLocation? fabLocation;
  final void Function(int index)? onIndexChanged;

  /// True when width >= [DesignTokens.breakpointWide] (sidebar layout).
  static bool isWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= DesignTokens.breakpointWide;
  }

  @override
  State<AdaptiveShellScaffold> createState() => _AdaptiveShellScaffoldState();
}

class _AdaptiveShellScaffoldState extends State<AdaptiveShellScaffold> {
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
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    widget.onIndexChanged?.call(index);
    _pageController.animateToPage(
      index,
      duration: DesignTokens.durationNormal,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = AdaptiveShellScaffold.isWide(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final primary = theme.colorScheme.primary;
    final onSurfaceVariant = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;

    final body = Column(
      children: [
        if (widget.title != null && isWide)
          Padding(
            padding: const EdgeInsets.fromLTRB(DesignTokens.space4, DesignTokens.space4, DesignTokens.space4, DesignTokens.space2),
            child: Row(
              children: [
                Text(
                  widget.title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight,
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
        backgroundColor: isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onNavTap,
              backgroundColor: surface,
              selectedIconTheme: IconThemeData(color: primary, size: 24),
              unselectedIconTheme: IconThemeData(color: onSurfaceVariant, size: 22),
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
      backgroundColor: isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight,
      body: body,
      floatingActionButton: widget.fab,
      floatingActionButtonLocation: widget.fabLocation ?? FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08))),
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
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
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
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
