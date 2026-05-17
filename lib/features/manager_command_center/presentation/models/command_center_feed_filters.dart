import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_quick_filter.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/models/command_center_view_scope.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/providers/command_center_stream_providers.dart';

/// Komuta merkezi çağrı beslemesi filtre paketi (immutable).
class CommandCenterFeedFilters {
  const CommandCenterFeedFilters({
    required this.viewScope,
    required this.searchQueryLower,
    this.filterTeamId,
    this.filterAgentId,
    this.filterOutcome,
    this.teamMemberIds = const [],
    this.quickFilter = CallSurfaceQuickFilter.all,
  });

  final CommandCenterViewScope viewScope;
  final String searchQueryLower;
  final String? filterTeamId;
  final String? filterAgentId;
  final String? filterOutcome;
  final List<String> teamMemberIds;
  final CallSurfaceQuickFilter quickFilter;

  CommandCenterCallsScope get callsStreamScope =>
      viewScope == CommandCenterViewScope.pending
          ? CommandCenterCallsScope.pending
          : CommandCenterCallsScope.all;

  bool get hasActiveFilters =>
      filterTeamId != null ||
      filterAgentId != null ||
      filterOutcome != null ||
      quickFilter != CallSurfaceQuickFilter.all ||
      searchQueryLower.isNotEmpty;
}
