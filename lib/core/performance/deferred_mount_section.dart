import 'package:flutter/material.dart';

/// İlk karelerden sonra alt bölümü mount eder — açılış ve sekme geçişi hafifler.
class DeferredMountSection extends StatefulWidget {
  const DeferredMountSection({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 320),
  });

  final Widget child;
  final Duration delay;

  @override
  State<DeferredMountSection> createState() => _DeferredMountSectionState();
}

class _DeferredMountSectionState extends State<DeferredMountSection> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(widget.delay, () {
        if (mounted) setState(() => _enabled = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return const SizedBox.shrink();
    return widget.child;
  }
}
