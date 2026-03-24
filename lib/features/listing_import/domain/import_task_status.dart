/// İçe aktarma görevi yaşam döngüsü (Phase 1.5 — yerel motor + ileride API).
enum ImportTaskStatus {
  pending,
  processing,
  success,
  failed,
}

extension ImportTaskStatusWire on ImportTaskStatus {
  String get wireValue {
    switch (this) {
      case ImportTaskStatus.pending:
        return 'pending';
      case ImportTaskStatus.processing:
        return 'processing';
      case ImportTaskStatus.success:
        return 'success';
      case ImportTaskStatus.failed:
        return 'failed';
    }
  }
}

ImportTaskStatus importTaskStatusFromWire(String? raw) {
  switch (raw) {
    case 'pending':
      return ImportTaskStatus.pending;
    case 'processing':
    case 'queued':
      return ImportTaskStatus.processing;
    case 'success':
    case 'completed':
    case 'partial':
      return ImportTaskStatus.success;
    case 'failed':
      return ImportTaskStatus.failed;
    default:
      return ImportTaskStatus.pending;
  }
}
