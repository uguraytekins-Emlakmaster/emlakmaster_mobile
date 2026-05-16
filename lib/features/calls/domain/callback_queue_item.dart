import 'dart:convert';

/// Geri arama kuyruğu — görev değil, arama odaklı hatırlatma.
class CallbackQueueItem {
  const CallbackQueueItem({
    required this.id,
    required this.phone,
    this.customerId,
    this.displayName = '',
    this.note = '',
    required this.dueAtMs,
    required this.createdAtMs,
    this.priority = 1,
    this.completed = false,
  });

  final String id;
  final String phone;
  final String? customerId;
  final String displayName;
  final String note;
  final int dueAtMs;
  final int createdAtMs;
  final int priority;
  final bool completed;

  bool get isDue =>
      !completed && DateTime.now().millisecondsSinceEpoch >= dueAtMs;

  CallbackQueueItem copyWith({
    bool? completed,
  }) {
    return CallbackQueueItem(
      id: id,
      phone: phone,
      customerId: customerId,
      displayName: displayName,
      note: note,
      dueAtMs: dueAtMs,
      createdAtMs: createdAtMs,
      priority: priority,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        if (customerId != null && customerId!.isNotEmpty) 'customerId': customerId,
        'displayName': displayName,
        'note': note,
        'dueAtMs': dueAtMs,
        'createdAtMs': createdAtMs,
        'priority': priority,
        'completed': completed,
      };

  static CallbackQueueItem? tryFromJson(Map<String, dynamic> m) {
    final id = m['id'] as String?;
    final phone = m['phone'] as String?;
    if (id == null || id.isEmpty || phone == null || phone.isEmpty) return null;
    return CallbackQueueItem(
      id: id,
      phone: phone,
      customerId: m['customerId'] as String?,
      displayName: m['displayName'] as String? ?? '',
      note: m['note'] as String? ?? '',
      dueAtMs: (m['dueAtMs'] as num?)?.toInt() ?? 0,
      createdAtMs: (m['createdAtMs'] as num?)?.toInt() ?? 0,
      priority: (m['priority'] as num?)?.toInt() ?? 1,
      completed: m['completed'] as bool? ?? false,
    );
  }

  static List<CallbackQueueItem> listFromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => tryFromJson(Map<String, dynamic>.from(e)))
          .whereType<CallbackQueueItem>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static String listToJsonString(List<CallbackQueueItem> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }
}
