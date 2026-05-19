import 'package:emlakmaster_mobile/core/performance/startup_mount_schedule.dart';
import 'package:flutter/material.dart';

/// İlk karelerden sonra alt bölümü mount eder — açılış ve sekme geçişi hafifler.
class DeferredMountSection extends StatefulWidget {
  const DeferredMountSection({
    super.key,
    required this.child,
    this.delay = StartupMountSchedule.dashboardPrimary,
  });

  const DeferredMountSection.shellChrome({
    super.key,
    required this.child,
  }) : delay = StartupMountSchedule.shellChrome;

  const DeferredMountSection.dashboardOperational({
    super.key,
    required this.child,
  }) : delay = StartupMountSchedule.dashboardOperational;

  const DeferredMountSection.dashboardPrimary({
    super.key,
    required this.child,
  }) : delay = StartupMountSchedule.dashboardPrimary;

  const DeferredMountSection.dashboardSecondary({
    super.key,
    required this.child,
  }) : delay = StartupMountSchedule.dashboardSecondary;

  const DeferredMountSection.dashboardInsight({
    super.key,
    required this.child,
  }) : delay = StartupMountSchedule.dashboardInsight;

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
