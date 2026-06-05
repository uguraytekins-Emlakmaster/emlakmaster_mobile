import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_types.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/providers/follow_up_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/widgets/follow_up_workspace_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Takiplerim — danışman takip workspace (Screen 28). Consultant shell index 5
/// ('follow_up'). Premium, dürüst, hızlı operasyonel takip: gerçek sessiz müşteri
/// kuyruğu (≥7 gün), kural tabanlı öncelik; uydurma skor veya sahte AI aciliyeti yok.
class ConsultantResurrectionPage extends ConsumerStatefulWidget {
  const ConsultantResurrectionPage({super.key});

  @override
  ConsumerState<ConsultantResurrectionPage> createState() =>
      _ConsultantResurrectionPageState();
}

class _ConsultantResurrectionPageState
    extends ConsumerState<ConsultantResurrectionPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ShellScreenReadyListener(
      screenName: 'follow_up',
      provider: followUpWorkspaceSnapshotProvider,
      itemCount: (v) => (v as FollowUpWorkspaceSnapshot).rows.length,
      child: const PremiumShellBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: FollowUpWorkspaceSurface(),
          ),
        ),
      ),
    );
  }
}
