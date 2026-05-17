import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/models/command_center_view_scope.dart';
import 'package:flutter/material.dart';

/// Gruplu / düz liste sliver'ları için bağlam.
class CommandCenterScopeConfig {
  const CommandCenterScopeConfig({
    required this.scope,
    required this.filtered,
    required this.agentNames,
    required this.locals,
    required this.currentUid,
    required this.customerFullNameById,
    required this.listBottomInset,
    required this.onClearFilters,
  });

  final CommandCenterViewScope scope;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered;
  final Map<String, String> agentNames;
  final List<LocalCallRecord> locals;
  final String? currentUid;
  final Map<String, String> customerFullNameById;
  final double listBottomInset;
  final VoidCallback onClearFilters;
}
