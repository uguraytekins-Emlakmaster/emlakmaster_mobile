import '../../domain/office_exception.dart';

/// UI için kısa mesaj — ham Firebase metni gösterme.
String officeErrorUserMessage(Object error) {
  if (error is OfficeException) {
    return error.userMessage;
  }
  final s = error.toString().toLowerCase();
  if (s.contains('permission-denied')) {
    return 'Bu işlem için yetkiniz yok. Firestore kurallarını kontrol edin.';
  }
  if (s.contains('network') || s.contains('unavailable')) {
    return 'Bağlantı hatası. İnterneti kontrol edip tekrar deneyin.';
  }
  return 'İşlem tamamlanamadı. Tekrar deneyin.';
}
