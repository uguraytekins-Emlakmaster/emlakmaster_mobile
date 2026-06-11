import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import '../domain/axion_agent_models.dart';
import '../domain/axion_agent_repository.dart';

/// V1 yerel denetim deposu (stub).
///
/// Backend yazımı V1'de riskli olduğundan olaylar bellek içinde tutulur.
/// Arayüz (AxionAgentAuditRepository) korunur; ileride Firestore
/// implementasyonu güvenli şekilde devreye alınabilir.
class LocalAxionAgentAuditRepository implements AxionAgentAuditRepository {
  LocalAxionAgentAuditRepository({this.maxEvents = 200});

  final int maxEvents;
  final List<AxionAuditEvent> _events = [];

  @override
  Future<void> record(AxionAuditEvent event) async {
    _events.add(event);
    if (_events.length > maxEvents) {
      _events.removeRange(0, _events.length - maxEvents);
    }
    if (kDebugMode) {
      debugPrint(
        '[AxionAudit] ${event.eventType.name} '
        'target=${event.targetType}/${event.targetId} '
        'source=${event.sourceType.name}',
      );
    }
  }

  @override
  Future<List<AxionAuditEvent>> recent({int limit = 50}) async {
    final reversed = _events.reversed.take(limit).toList(growable: false);
    return reversed;
  }
}

/// V1 bellek içi öneri deposu (stub).
class InMemoryAxionAgentSuggestionStore
    implements AxionAgentSuggestionStore {
  final Map<String, AxionAgentSuggestion> _byId = {};

  @override
  Future<void> save(AxionAgentSuggestion suggestion) async {
    _byId[suggestion.id] = suggestion;
  }

  @override
  Future<AxionAgentSuggestion?> byId(String id) async => _byId[id];

  @override
  Future<List<AxionAgentSuggestion>> pendingForUser(String userId) async {
    return _byId.values.toList(growable: false);
  }
}
