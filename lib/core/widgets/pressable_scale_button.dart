import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';

/// Basıldığında hafif küçülen, haptic veren etkileşimli buton sarmalayıcı.
class PressableScaleButton extends StatefulWidget {
  const PressableScaleButton({
    super.key,
    this.onPressed,
    required this.child,
    this.scaleDown = 0.96,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double scaleDown;

  @override
  State<PressableScaleButton> createState() => _PressableScaleButtonState();
}

class _PressableScaleButtonState extends State<PressableScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DesignTokens.durationFast,
    );
    _scale = Tween<double>(begin: 1, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onPressed!();
            },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
