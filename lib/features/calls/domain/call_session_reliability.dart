/// Güvenilir uygulama-içi arama kaynağı — iOS dürüstlük sınırı.
abstract final class CallSessionReliability {
  CallSessionReliability._();

  /// `tel:` handoff sonrası dönüşte kayıt istemi gösterilebilir.
  static const Duration returnPromptMaxAge = Duration(minutes: 45);

  /// Taslak otomatik sona erer.
  static const Duration draftMaxAge = Duration(hours: 72);

  static const Set<String> _reliableScreens = {
    'customer_detail',
    'consultant_calls',
    'command_center',
    'manager_crm_strip',
    'execution_reminder',
    'task_callback',
    'call_action_sheet',
    'crm_dialer',
    'call_screen',
    'dashboard',
    'resurrection',
    'customer_list',
    'consultant_dashboard',
    'consultant_resurrection',
    'call_identity_sheet',
    'resurrection_topic',
    'command_center_scope_consultant_empty',
    'command_center_scope_customer_empty',
    'command_center_filter_empty',
    'consultant_calls_filter_empty',
  };

  static bool isReliableHandoffSource(String startedFromScreen) {
    final s = startedFromScreen.trim();
    if (s.isEmpty || s == 'unknown') return false;
    if (s == 'identity_sheet_raw_dial') return false;
    return _reliableScreens.contains(s);
  }

  static bool shouldOfferReturnPrompt({
    required int createdAtMs,
    required String startedFromScreen,
    required bool returnPromptShown,
    required bool captureCompleted,
  }) {
    if (returnPromptShown || captureCompleted) return false;
    if (!isReliableHandoffSource(startedFromScreen)) return false;
    final age = DateTime.now().millisecondsSinceEpoch - createdAtMs;
    if (age < 0 || age > returnPromptMaxAge.inMilliseconds) return false;
    return true;
  }

  static bool isDraftStale(int createdAtMs) {
    final age = DateTime.now().millisecondsSinceEpoch - createdAtMs;
    return age > draftMaxAge.inMilliseconds;
  }
}
