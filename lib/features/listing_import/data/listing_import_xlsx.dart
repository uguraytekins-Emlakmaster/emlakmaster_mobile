import 'package:excel/excel.dart';

/// İlk sayfa — satır/sütun tablo (CSV ile aynı şekilde [parseFileMock]’a gider).
List<List<dynamic>> decodeXlsxBytesToRows(List<int> bytes) {
  final excel = Excel.decodeBytes(bytes);
  if (excel.tables.isEmpty) return [];
  final sheet = excel.tables.values.first;
  final out = <List<dynamic>>[];
  for (final row in sheet.rows) {
    out.add(
      row.map((cell) {
        final v = cell?.value;
        if (v == null) return '';
        if (v is String) return v;
        return v.toString();
      }).toList(),
    );
  }
  return out;
}
