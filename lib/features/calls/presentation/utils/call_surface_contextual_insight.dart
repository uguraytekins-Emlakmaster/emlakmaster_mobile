/// Tek satırlık, düşük öncelikli bağlam ipucu (gürültü yapmamak için en fazla biri).
abstract final class CallSurfaceContextualInsight {
  CallSurfaceContextualInsight._();

  static String? _outcomeCode(Map<String, dynamic> data) =>
      (data['outcome'] as String?)?.trim().isNotEmpty == true
          ? data['outcome'] as String
          : (data['callOutcome'] as String?)?.trim();

  static String? forFirestoreData(
    Map<String, dynamic> data, {
    String? notePreview,
    bool hasCallablePhone = false,
  }) {
    final oc = _outcomeCode(data) ?? '';
    if (hasCallablePhone &&
        (oc == 'missed' ||
            oc == 'no_answer' ||
            oc == 'busy' ||
            oc == 'failed')) {
      return 'Tekrar aramak için hazır.';
    }
    final cid = (data['customerId'] as String?)?.trim();
    final n = notePreview?.trim() ?? '';
    if (cid != null && cid.isNotEmpty && n.isEmpty) {
      return 'Kısa not ekip için faydalı olur.';
    }
    return null;
  }

  static String? forLocalDraft({
    required String? outcome,
    required bool hasCallablePhone,
    required bool hasNote,
  }) {
    final oc = (outcome ?? '').trim();
    if (hasCallablePhone &&
        (oc == 'missed' ||
            oc == 'no_answer' ||
            oc == 'busy' ||
            oc == 'failed')) {
      return 'Tekrar aramak için hazır.';
    }
    if (!hasNote) {
      return 'Kısa not ekip için faydalı olur.';
    }
    return null;
  }
}
