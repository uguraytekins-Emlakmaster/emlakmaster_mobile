import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/pressable_scale_button.dart';

/// Boş liste / boş sonuç ekranı. Premium empty state + hafif giriş animasyonu.
class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.outlinedActionLabel,
    this.onOutlinedAction,
    this.compact = false,
    this.illustration,
    this.premiumVisual = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? outlinedActionLabel;
  final VoidCallback? onOutlinedAction;
  final bool compact;
  final Widget? illustration;
  final bool premiumVisual;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final brand = ext.brandPrimary;
    final textColor = ext.foregroundSecondary;

    final iconBox = widget.compact ? 56.0 : 96.0;
    final iconSize = widget.compact ? 28.0 : 48.0;
    final ringSize = widget.premiumVisual && !widget.compact ? 132.0 : iconBox;

    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.illustration != null)
          widget.illustration!
        else
          SizedBox(
            width: ringSize,
            height: ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.premiumVisual && !widget.compact)
                  Container(
                    width: ringSize,
                    height: ringSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: brand.withValues(alpha: 0.22),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: brand.withValues(alpha: 0.08),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        brand.withValues(alpha: 0.14),
                        brand.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    size: iconSize,
                    color: brand.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: widget.compact ? DesignTokens.space3 : DesignTokens.space5),
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ext.foreground,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: DesignTokens.space2),
          Text(
            widget.subtitle!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor.withValues(alpha: 0.88),
                  height: 1.4,
                ),
          ),
        ],
        if (widget.outlinedActionLabel != null && widget.onOutlinedAction != null) ...[
          SizedBox(height: widget.compact ? DesignTokens.space3 : DesignTokens.space4),
          OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onOutlinedAction!();
            },
            icon: Icon(Icons.add_rounded, size: 18, color: brand),
            label: Text(
              widget.outlinedActionLabel!,
              style: TextStyle(color: brand, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: brand.withValues(alpha: 0.85)),
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space3),
            ),
          ),
        ],
        if (widget.actionLabel != null && widget.onAction != null) ...[
          SizedBox(height: widget.compact ? DesignTokens.space3 : DesignTokens.space5),
          PressableScaleButton(
            child: FilledButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onAction!();
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(widget.actionLabel!),
              style: FilledButton.styleFrom(
                backgroundColor: brand,
                foregroundColor: ext.onBrand,
              ),
            ),
          ),
        ],
      ],
    );

    return Center(
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? DesignTokens.space4 : DesignTokens.space6),
        child: FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: content,
          ),
        ),
      ),
    );
  }
}
