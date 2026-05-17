String? taskRecurrenceLabel(String? code) {
  switch (code) {
    case 'daily':
      return 'Her gün';
    case 'weekly':
      return 'Her hafta';
    case 'monthly':
      return 'Her ay';
    default:
      return null;
  }
}

DateTime nextDueForRecurrence(DateTime from, String recurrence) {
  switch (recurrence) {
    case 'daily':
      return from.add(const Duration(days: 1));
    case 'weekly':
      return from.add(const Duration(days: 7));
    case 'monthly':
      return DateTime(from.year, from.month + 1, from.day);
    default:
      return from.add(const Duration(days: 7));
  }
}
