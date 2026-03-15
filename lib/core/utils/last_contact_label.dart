/// Son temas tarihine göre kısa etiket ve renk (müşteri kartı chip'i için).
class LastContactLabel {
  LastContactLabel._();

  static String label(DateTime? lastAt) {
    if (lastAt == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(lastAt);
    if (diff.inMinutes < 60) return 'Az önce';
    if (diff.inHours < 24 && lastAt.day == now.day) return 'Bugün';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} hafta önce';
    return '${(diff.inDays / 30).floor()} ay önce';
  }

  static int colorType(DateTime? lastAt) {
    if (lastAt == null) return 0;
    final diff = DateTime.now().difference(lastAt);
    if (diff.inDays == 0) return 1; // bugün -> yeşil
    if (diff.inDays <= 3) return 2;  // birkaç gün -> sarı
    return 3; // uzun süre -> gri
  }
}
