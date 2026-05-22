import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_sparkline.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/navigation/app_back_dispatcher.dart';
import 'package:flutter/material.dart';

// Ortak premium bileşenler — performans için const ve hafif boya tercih edilir.

// —— Scaffold & header ——

class PremiumPageScaffold extends StatelessWidget {
  const PremiumPageScaffold({
    super.key,
    required this.body,
    this.header,
    this.floatingActionButton,
    this.padding,
  });

  final Widget body;
  final Widget? header;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Scaffold(
      backgroundColor: ext.background,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) header!,
            Expanded(
              child: Padding(
                padding: padding ??
                    const EdgeInsets.symmetric(
                      horizontal: DesignTokens.screenEdgePadding,
                    ),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumPageHeader extends StatelessWidget {
  const PremiumPageHeader({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing = const [],
    this.showBack = false,
    this.onBack,
    this.showNavigation = true,
    this.showHomeWhenCanPop = true,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final List<Widget> trailing;
  /// Manuel geri — [showNavigation] false ise kullanılır.
  final bool showBack;
  final VoidCallback? onBack;
  /// Otomatik geri + ana sayfa kromu.
  final bool showNavigation;
  final bool showHomeWhenCanPop;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.screenEdgePadding,
        DesignTokens.space3,
        DesignTokens.screenEdgePadding,
        DesignTokens.space4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showNavigation && !showBack)
            Padding(
              padding: const EdgeInsets.only(right: DesignTokens.space2),
              child: PremiumNavLeading(showHomeWhenCanPop: showHomeWhenCanPop),
            ),
          if (showBack)
            Padding(
              padding: const EdgeInsets.only(right: DesignTokens.space3),
              child: _PremiumIconContainer(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack ??
                    () {
                      final shell = context.findAncestorStateOfType<
                          AdaptiveShellScaffoldState>();
                      AppBackDispatcher.tryPop(
                        context,
                        onShellBack:
                            shell?.tryPopTabHistory,
                      );
                    },
              ),
            ),
          if (leading != null) ...[
            leading!,
            const SizedBox(width: DesignTokens.space3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: DesignTokens.titleSubtitleGap),
                  Text(
                    subtitle!,
                    style: AppTypography.meta(context).copyWith(
                      color: ext.textSecondary,
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }
}

class PremiumSectionHeader extends StatelessWidget {
  const PremiumSectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.icon,
  });

  final String label;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: ext.accent),
            const SizedBox(width: DesignTokens.space2),
          ],
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: ext.accent,
                fontSize: DesignTokens.fontSizeXs,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// —— Cards ——

class PremiumSurfaceCard extends StatelessWidget {
  const PremiumSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DesignTokens.cardPaddingComfortable),
    this.goldBorder = false,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool goldBorder;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final card = DecoratedBox(
      decoration: ext.premiumSurfaceDecoration(goldBorder: goldBorder),
      child: Padding(padding: padding, child: child),
    );
    final wrapped = onTap == null
        ? card
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius:
                  BorderRadius.circular(DesignTokens.radiusCardPrimary),
              child: card,
            ),
          );
    if (margin != null) {
      return Padding(padding: margin!, child: wrapped);
    }
    return wrapped;
  }
}

class PremiumMetricCard extends StatelessWidget {
  const PremiumMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trendLabel,
    this.trendUp,
    this.iconColor,
    this.sparklineValues,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? trendLabel;
  final bool? trendUp;
  final Color? iconColor;
  final List<double>? sparklineValues;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final accent = iconColor ?? ext.accent;
    return PremiumSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PremiumIconContainer(
                icon: icon,
                color: accent,
                size: 36,
                iconSize: 18,
              ),
              const Spacer(),
              if (trendLabel != null)
                Text(
                  trendLabel!,
                  style: TextStyle(
                    color: trendUp == true
                        ? ext.success
                        : (trendUp == false ? ext.danger : ext.textTertiary),
                    fontSize: DesignTokens.fontSizeXs,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),
          Text(
            value,
            style: AppTypography.metricValue(context).copyWith(
              fontSize: DesignTokens.fontSize2xl,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: DesignTokens.metricLabelGap),
          Text(
            label,
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: DesignTokens.fontSizeSm,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (sparklineValues != null && sparklineValues!.length >= 2) ...[
            const SizedBox(height: DesignTokens.space2),
            PremiumSparkline(
              values: sparklineValues!,
              color: accent.withValues(alpha: 0.85),
            ),
          ],
        ],
      ),
    );
  }
}

// —— Controls ——

class PremiumSegmentedControl<T> extends StatelessWidget {
  const PremiumSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
    this.labelBuilder,
  });

  final List<T> segments;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: ext.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: segments.map((seg) {
          final active = seg == selected;
          final label = labelBuilder?.call(seg) ?? seg.toString();
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(seg),
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                child: AnimatedContainer(
                  duration: DesignTokens.durationFast,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusPill),
                    border: active
                        ? Border.all(
                            color: ext.accent.withValues(alpha: 0.55),
                          )
                        : null,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active ? ext.accent : ext.textPassive,
                      fontSize: DesignTokens.fontSizeSm,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PremiumFilterChip extends StatelessWidget {
  const PremiumFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            border: Border.all(
              color: selected
                  ? ext.accent.withValues(alpha: 0.65)
                  : ext.border.withValues(alpha: 0.45),
            ),
            color: selected ? ext.accent.withValues(alpha: 0.08) : ext.surface,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? ext.accent : ext.textSecondary,
                  fontSize: DesignTokens.fontSizeSm,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? ext.accent.withValues(alpha: 0.2)
                        : ext.border.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: selected ? ext.accent : ext.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
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

class PremiumSearchBar extends StatelessWidget {
  const PremiumSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Ara…',
    this.onSubmitted,
    this.onChanged,
    this.trailing,
    this.showMic = false,
    this.onMicTap,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  final bool showMic;
  final VoidCallback? onMicTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ext.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
              border: Border.all(color: ext.border.withValues(alpha: 0.5)),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: TextStyle(color: ext.textPrimary),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: ext.textTertiary),
                prefixIcon: Icon(Icons.search_rounded, color: ext.textTertiary),
                suffixIcon: showMic
                    ? IconButton(
                        onPressed: onMicTap,
                        icon: Icon(Icons.mic_none_rounded,
                            color: ext.textSecondary),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: DesignTokens.space2),
          trailing!,
        ],
      ],
    );
  }
}

class PremiumStatusPill extends StatelessWidget {
  const PremiumStatusPill({
    super.key,
    required this.label,
    this.color,
    this.outlined = false,
  });

  final String label;
  final Color? color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final c = color ?? ext.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: outlined ? Border.all(color: c.withValues(alpha: 0.5)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: DesignTokens.fontSizeXs,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class PremiumIconTile extends StatelessWidget {
  const PremiumIconTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.badge,
    this.hintVisual,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? badge;
  final Widget? hintVisual;

  @override
  Widget build(BuildContext context) {
    return PremiumListRow(
      leading: _PremiumIconContainer(icon: icon),
      title: title,
      subtitle: subtitle,
      trailing: trailing ??
          (badge != null
              ? PremiumStatusPill(label: badge!, outlined: true)
              : Icon(
                  Icons.chevron_right_rounded,
                  color: AppThemeExtension.of(context).accent,
                )),
      onTap: onTap,
      hintVisual: hintVisual,
    );
  }
}

class PremiumListRow extends StatelessWidget {
  const PremiumListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.hintVisual,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? hintVisual;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return PremiumSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(DesignTokens.space4),
      child: Row(
        children: [
          leading,
          const SizedBox(width: DesignTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: DesignTokens.fontSizeMd,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: ext.textSecondary,
                      fontSize: DesignTokens.fontSizeSm,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hintVisual != null)
            Opacity(opacity: 0.35, child: hintVisual!),
          if (trailing != null) ...[
            const SizedBox(width: DesignTokens.space2),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class PremiumEmptyState extends StatelessWidget {
  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return PremiumSurfaceCard(
      goldBorder: true,
      padding: const EdgeInsets.symmetric(
        vertical: DesignTokens.space10,
        horizontal: DesignTokens.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PremiumEmptySymbol(icon: icon),
          const SizedBox(height: DesignTokens.space6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ext.textPrimary,
              fontSize: DesignTokens.fontSizeXl,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: DesignTokens.space3),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ext.textSecondary,
                fontSize: DesignTokens.fontSizeSm,
                height: 1.4,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: DesignTokens.space6),
            PremiumCtaButton(label: actionLabel!, onPressed: onAction!),
          ],
        ],
      ),
    );
  }
}

class _PremiumEmptySymbol extends StatelessWidget {
  const _PremiumEmptySymbol({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ext.accent.withValues(alpha: 0.15)),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ext.accent.withValues(alpha: 0.1),
            ),
          ),
          Icon(icon, size: 36, color: ext.accent),
        ],
      ),
    );
  }
}

class PremiumInfoBanner extends StatelessWidget {
  const PremiumInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.onDismiss,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return DecoratedBox(
      decoration: ext.premiumSurfaceDecoration(
        radius: DesignTokens.radiusLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: ext.accent),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: DesignTokens.fontSizeSm,
                  height: 1.4,
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close_rounded, color: ext.textTertiary, size: 20),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
      ),
    );
  }
}

class PremiumCtaButton extends StatelessWidget {
  const PremiumCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool expanded;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final child = Material(
      color: secondary ? ext.surface : ext.accent,
      borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: secondary ? ext.accent : ext.onBrand,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondary ? ext.textPrimary : ext.onBrand,
                    fontWeight: FontWeight.w700,
                    fontSize: DesignTokens.fontSizeMd,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class PremiumSettingsToggleRow extends StatelessWidget {
  const PremiumSettingsToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space2,
      ),
      child: Row(
        children: [
          _PremiumIconContainer(icon: icon, size: 40),
          const SizedBox(width: DesignTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: ext.textSecondary,
                    fontSize: DesignTokens.fontSizeSm,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: ext.accent.withValues(alpha: 0.45),
            activeThumbColor: ext.accent,
          ),
        ],
      ),
    );
  }
}

class _PremiumIconContainer extends StatelessWidget {
  const _PremiumIconContainer({
    required this.icon,
    this.onTap,
    this.color,
    this.size = 44,
    this.iconSize = 22,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final c = color ?? ext.accent;
    final box = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: ext.border.withValues(alpha: 0.4)),
      ),
      child: Icon(icon, color: c, size: iconSize),
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: box,
      ),
    );
  }
}
