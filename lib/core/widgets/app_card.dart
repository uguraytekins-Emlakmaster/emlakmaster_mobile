import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/design_tokens.dart';

/// Ortak premium kart yüzeyi. Tüm kritik kart tipleri bunun üzerine inşa edilebilir.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.onTap,
    this.padding,
    this.margin,
    this.child,
    this.backgroundColor,
    this.borderColor,
    this.elevation = 0,
  });

  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Widget? child;
  final Color? backgroundColor;
  final Color? borderColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final card = _AnimatedSurface(
      onTap: onTap,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      elevation: elevation,
      child: child,
    );
    return card;
  }
}

class _AnimatedSurface extends StatefulWidget {
  const _AnimatedSurface({
    required this.onTap,
    required this.padding,
    required this.margin,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    required this.elevation,
  });

  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Widget? child;
  final Color? backgroundColor;
  final Color? borderColor;
  final double elevation;

  @override
  State<_AnimatedSurface> createState() => _AnimatedSurfaceState();
}

class _AnimatedSurfaceState extends State<_AnimatedSurface> {
  bool _hovering = false;
  bool _pressed = false;

  void _setHover(bool value) {
    if (!mounted) return;
    setState(() => _hovering = value);
  }

  void _setPressed(bool value) {
    if (!mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final interactive = widget.onTap != null;
    final baseColor = widget.backgroundColor ?? ext.card;
    final baseBorder = widget.borderColor ?? ext.border;

    final hoverTransform = _pressed
        ? (Matrix4.identity()..scaleByDouble(0.98, 0.98, 1.0, 1))
        : (_hovering
            ? (Matrix4.identity()..translateByDouble(0.0, -2.0, 0.0, 1))
            : Matrix4.identity());

    final hoverShadow = widget.elevation > 0 || _hovering
        ? [
            BoxShadow(
              color: ext.shadowColor,
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ]
        : const <BoxShadow>[];

    final borderColor = _hovering && interactive
        ? DesignTokens.primary.withValues(alpha: 0.5)
        : baseBorder;

    Widget surface = AnimatedContainer(
      duration: DesignTokens.durationFast,
      curve: Curves.easeOutCubic,
      margin: widget.margin ?? const EdgeInsets.all(0),
      padding: widget.padding ??
          const EdgeInsets.all(DesignTokens.space4),
      transform: hoverTransform,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: borderColor),
        boxShadow: hoverShadow,
      ),
      child: widget.child,
    );

    if (interactive) {
      surface = MouseRegion(
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: surface,
        ),
      );
    }

    return surface;
  }
}

