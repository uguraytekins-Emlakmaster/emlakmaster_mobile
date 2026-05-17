import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

class CommandCenterFiltersBar extends StatelessWidget {
  const CommandCenterFiltersBar({
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
  Widget build(BuildContext context) {
    return StreamBuilder<List<TeamDoc>>(
      stream: FirestoreService.teamsStream(),
      builder: (context, teamSnap) {
        final teams = teamSnap.data ?? [];
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.agentsStream(),
          builder: (context, agentSnap) {
            final agents = agentSnap.data?.docs ?? [];
            var agentIds = agents.map((d) => d.id).toList();
            if (filterTeamId != null && teamMemberIds.isNotEmpty) {
              agentIds =
                  agentIds.where((id) => teamMemberIds.contains(id)).toList();
            }
            final agentNames = {
              for (final d in agents)
                d.id: d.data()['displayName'] as String? ?? d.id,
            };
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final surface = isDark
                ? AppThemeExtension.of(context).surface
                : AppThemeExtension.of(context).surface;
            final surfaceCard = isDark
                ? AppThemeExtension.of(context).card
                : AppThemeExtension.of(context).surface;
            final border = isDark
                ? AppThemeExtension.of(context).border
                : AppThemeExtension.of(context).border;
            final textColor = isDark
                ? AppThemeExtension.of(context).textPrimary
                : AppThemeExtension.of(context).textPrimary;
            final hintColor =
                theme.colorScheme.onSurface.withValues(alpha: 0.7);
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space4,
                  vertical: DesignTokens.space1 + 2),
              decoration: BoxDecoration(
                color: surface,
                border: Border(
                    bottom: BorderSide(
                        color: border.withValues(alpha: 0.32))),
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
                                child: Text('Tüm ekipler',
                                    style: TextStyle(color: textColor))),
                            ...teams.map((t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t.name,
                                      style: TextStyle(color: textColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                )),
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
                  if (teams.isNotEmpty)
                    const SizedBox(width: DesignTokens.space3),
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
                              child: Text('Tümü',
                                  style: TextStyle(color: textColor))),
                          ...agentIds.map((id) => DropdownMenuItem(
                                value: id,
                                child: Text(agentNames[id] ?? id,
                                    style: TextStyle(color: textColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) => onAgentChanged(v),
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
                              child: Text('Tümü',
                                  style: TextStyle(color: textColor))),
                          DropdownMenuItem(
                              value: 'connected',
                              child: Text('Bağlandı',
                                  style: TextStyle(color: textColor))),
                          DropdownMenuItem(
                              value: 'missed',
                              child: Text('Cevapsız',
                                  style: TextStyle(color: textColor))),
                          DropdownMenuItem(
                              value: 'no_answer',
                              child: Text('Cevap yok',
                                  style: TextStyle(color: textColor))),
                          DropdownMenuItem(
                              value: 'busy',
                              child: Text('Meşgul',
                                  style: TextStyle(color: textColor))),
                          DropdownMenuItem(
                              value: 'failed',
                              child: Text('Başarısız',
                                  style: TextStyle(color: textColor))),
                          DropdownMenuItem(
                              value: 'handoff_pending',
                              child: Text('Sonuç bekleniyor (handoff)',
                                  style: TextStyle(color: textColor))),
                        ],
                        onChanged: (v) => onOutcomeChanged(v),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
