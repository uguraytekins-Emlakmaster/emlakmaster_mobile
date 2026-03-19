// Web'de dart:io File yok; imza uyumu için stub.
// Bu sınıf sadece derleme için kullanılır; web'de File ile çağrı yapılmamalı.

class File {
  File(String path);
  Future<List<int>> readAsBytes() async =>
      throw UnsupportedError('File is not supported on web. Use bytes APIs.');
}
