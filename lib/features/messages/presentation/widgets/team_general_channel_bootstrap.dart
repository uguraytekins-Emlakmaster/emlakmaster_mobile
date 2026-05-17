import 'package:emlakmaster_mobile/features/messages/presentation/providers/team_chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Genel kanalı bir kez hazırlar; [ref.listen] build içinde değil.
class TeamGeneralChannelBootstrap extends ConsumerStatefulWidget {
  const TeamGeneralChannelBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TeamGeneralChannelBootstrap> createState() =>
      _TeamGeneralChannelBootstrapState();
}

class _TeamGeneralChannelBootstrapState
    extends ConsumerState<TeamGeneralChannelBootstrap> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(teamGeneralChannelReadyProvider, (_, __) {});
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
