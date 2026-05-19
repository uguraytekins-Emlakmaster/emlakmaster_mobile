import 'package:emlakmaster_mobile/core/performance/deferred_mount_section.dart';
import 'package:flutter/material.dart';

/// Kabuk üstü şeritler (senkron, post-call) — [StartupMountSchedule.shellChrome].
class StartupShellChrome extends StatelessWidget {
  const StartupShellChrome({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DeferredMountSection.shellChrome(child: child);
  }
}
