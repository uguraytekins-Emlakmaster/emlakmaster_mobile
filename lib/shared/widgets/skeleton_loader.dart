import 'package:flutter/material.dart';

import '../../core/services/app_lifecycle_power_service.dart';
import '../../core/theme/design_tokens.dart';

/// Premium skeleton loader; loading state'lerde kullanılır.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    AppLifecyclePowerService.isInBackground.addListener(_syncAnimationState);
    _syncAnimationState();
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _syncAnimationState() {
    if (AppLifecyclePowerService.shouldReduceMotion) {
      _controller.stop();
      _controller.value = 0.4;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    AppLifecyclePowerService.isInBackground.removeListener(_syncAnimationState);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ??
                BorderRadius.circular(DesignTokens.radiusMd),
            color: Colors.white.withValues(alpha: _animation.value * 0.12),
          ),
        );
      },
    );
  }
}
