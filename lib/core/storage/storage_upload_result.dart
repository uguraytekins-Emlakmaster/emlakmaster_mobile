/// Storage yükleme sonucu + istemci tarafı izlenebilirlik.
class StorageUploadResult {
  const StorageUploadResult({
    required this.downloadUrl,
    required this.storagePath,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedAt,
  });

  final String downloadUrl;
  final String storagePath;
  final String mimeType;
  final int sizeBytes;
  final DateTime uploadedAt;
}
