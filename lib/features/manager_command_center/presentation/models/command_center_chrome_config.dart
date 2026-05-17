import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_quick_filter.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/models/command_center_view_scope.dart';
import 'package:flutter/material.dart';

/// Komuta merkezi üst chrome (segment, filtre, arama) için sayfa durumu + geri çağrılar.
class CommandCenterChromeConfig {
  const CommandCenterChromeConfig({
    required this.scope,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.filterTeamId,
    required this.filterAgentId,
    required this.filterOutcome,
    required this.teamMemberIds,
    required this.quickFilter,
    required this.kpiExpanded,
    required this.onScopeChanged,
    required this.onTeamChanged,
    required this.onAgentChanged,
    required this.onOutcomeChanged,
    required this.onQuickFilterChanged,
    required this.onToggleKpiExpanded,
    required this.onSearchTap,
  });

  final CommandCenterViewScope scope;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchQuery;
  final String? filterTeamId;
  final String? filterAgentId;
  final String? filterOutcome;
  final List<String> teamMemberIds;
  final CallSurfaceQuickFilter quickFilter;
  final bool kpiExpanded;
  final ValueChanged<CommandCenterViewScope> onScopeChanged;
  final void Function(String? teamId, List<String> memberIds) onTeamChanged;
  final ValueChanged<String?> onAgentChanged;
  final ValueChanged<String?> onOutcomeChanged;
  final ValueChanged<CallSurfaceQuickFilter> onQuickFilterChanged;
  final VoidCallback onToggleKpiExpanded;
  final VoidCallback onSearchTap;
}
