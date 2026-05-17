import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Yüzen premium alt gezinme — BackdropFilter yok, hafif gölge.
class PremiumBottomNavDock extends StatelessWidget {
  const PremiumBottomNavDock({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.centerItemIndex,
    this.onCenterTap,
    this.centerIcon = Icons.add_rounded,
    this.centerLabel,
  });

  final List<AdaptiveNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int? centerItemIndex;
  final VoidCallback? onCenterTap;
  final IconData centerIcon;
  final String? centerLabel;

  static const double dockHeight = 64;
  static const double centerButtonSize = 52;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
  final hasCenter = centerItemIndex != null && onCenterTap != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(DesignTokens.radius3xl),
          border: Border.all(color: ext.border.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: ext.shadowColor.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SizedBox(
          height: dockHeight,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (hasCenter && i == centerItemIndex)
                  _CenterNavSlot(
                    icon: centerIcon,
                    label: centerLabel,
                    onTap: onCenterTap!,
                    ext: ext,
                  )
                else
                  Expanded(
                    child: _DockNavItem(
                      item: items[i],
                      selected: selectedIndex == i,
                      onTap: () => onTap(i),
                      ext: ext,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DockNavItem extends StatelessWidget {
  const _DockNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.ext,
  });

  final AdaptiveNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final AppThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ext.accent : ext.textPassive;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (selected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 18,
                height: 2,
                decoration: BoxDecoration(
                  color: ext.accent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CenterNavSlot extends StatelessWidget {
  const _CenterNavSlot({
    required this.icon,
    required this.onTap,
    required this.ext,
    this.label,
  });

  final IconData icon;
  final VoidCallback onTap;
  final AppThemeExtension ext;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              color: ext.accent,
              elevation: 0,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: PremiumBottomNavDock.centerButtonSize,
                  height: PremiumBottomNavDock.centerButtonSize,
                  child: Icon(icon, color: ext.onBrand, size: 26),
                ),
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 4),
              Text(
                label!,
                style: TextStyle(
                  color: ext.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
