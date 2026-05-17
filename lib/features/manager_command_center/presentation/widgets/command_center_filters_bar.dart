import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/providers/command_center_stream_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommandCenterFiltersBar extends ConsumerWidget {
  const CommandCenterFiltersBar({
    super.key,
    required this.filterTeamId,
    required this.filterAgentId,
    required this.filterOutcome,
    required this.teamMemberIds,
    required this.onTeamChanged,
    required this.onAgentChanged,
    required this.onOutcomeChanged,
  });

  final String? filterTeamId;
  final String? filterAgentId;
  final String? filterOutcome;
  final List<String> teamMemberIds;
  final void Function(String? teamId, List<String> memberIds) onTeamChanged;
  final void Function(String?) onAgentChanged;
  final void Function(String?) onOutcomeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(commandCenterTeamsProvider);
    final agentsAsync = ref.watch(commandCenterAgentsFilterProvider);

    return teamsAsync.when(
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox.shrink(),
      data: (teams) => agentsAsync.when(
        loading: () => const SizedBox(height: 48),
        error: (_, __) => const SizedBox.shrink(),
        data: (agents) => _FiltersRow(
          teams: teams,
          agents: agents,
          filterTeamId: filterTeamId,
          filterAgentId: filterAgentId,
          filterOutcome: filterOutcome,
          teamMemberIds: teamMemberIds,
          onTeamChanged: onTeamChanged,
          onAgentChanged: onAgentChanged,
          onOutcomeChanged: onOutcomeChanged,
        ),
      ),
    );
  }
}

class _FiltersRow extends StatelessWidget {
  const _FiltersRow({
    required this.teams,
    required this.agents,
    required this.filterTeamId,
    required this.filterAgentId,
    required this.filterOutcome,
    required this.teamMemberIds,
    required this.onTeamChanged,
    required this.onAgentChanged,
    required this.onOutcomeChanged,
  });

  final List<TeamDoc> teams;
  final CommandCenterAgentsFilterData agents;
  final String? filterTeamId;
  final String? filterAgentId;
  final String? filterOutcome;
  final List<String> teamMemberIds;
  final void Function(String? teamId, List<String> memberIds) onTeamChanged;
  final void Function(String?) onAgentChanged;
  final void Function(String?) onOutcomeChanged;

  @override
  Widget build(BuildContext context) {
    var agentIds = agents.agentIds;
    if (filterTeamId != null && teamMemberIds.isNotEmpty) {
      agentIds = agentIds.where((id) => teamMemberIds.contains(id)).toList();
    }
    final agentNames = agents.agentNames;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = AppThemeExtension.of(context).surface;
    final surfaceCard = isDark
        ? AppThemeExtension.of(context).card
        : AppThemeExtension.of(context).surface;
    final border = AppThemeExtension.of(context).border;
    final textColor = AppThemeExtension.of(context).textPrimary;
    final hintColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space1 + 2,
      ),
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          bottom: BorderSide(color: border.withValues(alpha: 0.32)),
        ),
      ),
      child: Row(
        children: [
          if (teams.isNotEmpty)
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: filterTeamId,
                  isExpanded: true,
                  hint: Text('Ekip',
                      style: TextStyle(color: hintColor, fontSize: 13)),
                  dropdownColor: surfaceCard,
                  items: [
                    DropdownMenuItem(
                      child:
                          Text('Tüm ekipler', style: TextStyle(color: textColor)),
                    ),
                    ...teams.map(
                      (t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(
                          t.name,
                          style: TextStyle(color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) {
                      onTeamChanged(null, <String>[]);
                      return;
                    }
                    final t = teams.where((x) => x.id == v).toList();
                    final memberIds =
                        t.isEmpty ? <String>[] : t.first.memberIds;
                    onTeamChanged(v, memberIds);
                  },
                ),
              ),
            ),
          if (teams.isNotEmpty) const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: filterAgentId,
                isExpanded: true,
                hint: Text('Danışman',
                    style: TextStyle(color: hintColor, fontSize: 13)),
                dropdownColor: surfaceCard,
                items: [
                  DropdownMenuItem(
                    child: Text('Tümü', style: TextStyle(color: textColor)),
                  ),
                  ...agentIds.map(
                    (id) => DropdownMenuItem(
                      value: id,
                      child: Text(
                        agentNames[id] ?? id,
                        style: TextStyle(color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: onAgentChanged,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: filterOutcome,
                isExpanded: true,
                hint: Text('Sonuç',
                    style: TextStyle(color: hintColor, fontSize: 13)),
                dropdownColor: surfaceCard,
                items: [
                  DropdownMenuItem(
                    child: Text('Tümü', style: TextStyle(color: textColor)),
                  ),
                  DropdownMenuItem(
                    value: 'connected',
                    child:
                        Text('Bağlandı', style: TextStyle(color: textColor)),
                  ),
                  DropdownMenuItem(
                    value: 'missed',
                    child:
                        Text('Cevapsız', style: TextStyle(color: textColor)),
                  ),
                  DropdownMenuItem(
                    value: 'no_answer',
                    child: Text('Cevap yok',
                        style: TextStyle(color: textColor)),
                  ),
                  DropdownMenuItem(
                    value: 'busy',
                    child: Text('Meşgul', style: TextStyle(color: textColor)),
                  ),
                  DropdownMenuItem(
                    value: 'failed',
                    child: Text('Başarısız',
                        style: TextStyle(color: textColor)),
                  ),
                  DropdownMenuItem(
                    value: 'handoff_pending',
                    child: Text('Sonuç bekleniyor (handoff)',
                        style: TextStyle(color: textColor)),
                  ),
                ],
                onChanged: onOutcomeChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
