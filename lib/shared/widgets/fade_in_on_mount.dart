import 'package:flutter/material.dart';

/// Smooth fade-in when the widget first appears (e.g. charts after async load).
class FadeInOnMount extends StatefulWidget {
  const FadeInOnMount({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 420),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  State<FadeInOnMount> createState() => _FadeInOnMountState();
}

class _FadeInOnMountState extends State<FadeInOnMount> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: widget.curve),
      child: widget.child,
    );
  }
}
