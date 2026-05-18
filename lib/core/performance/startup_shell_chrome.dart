import 'package:emlakmaster_mobile/core/performance/deferred_mount_section.dart';
import 'package:flutter/material.dart';

/// Kabuk üstü şeritler (senkron, post-call, draft) — ilk kareden sonra mount.
class StartupShellChrome extends StatelessWidget {
  const StartupShellChrome({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 480),
  });

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return DeferredMountSection(delay: delay, child: child);
  }
}
