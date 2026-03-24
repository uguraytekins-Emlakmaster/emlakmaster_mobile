/// Kaynak: URL, dosya veya manuel giriş.
enum ImportSourceType {
  url,
  file,
  manual,
}

extension ImportSourceTypeWire on ImportSourceType {
  String get wireValue {
    switch (this) {
      case ImportSourceType.url:
        return 'url';
      case ImportSourceType.file:
        return 'file';
      case ImportSourceType.manual:
        return 'manual';
    }
  }
}

ImportSourceType importSourceTypeFromWire(String? raw) {
  switch (raw) {
    case 'url':
      return ImportSourceType.url;
    case 'file':
    case 'extension':
      return ImportSourceType.file;
    case 'manual':
      return ImportSourceType.manual;
    default:
      return ImportSourceType.url;
  }
}
