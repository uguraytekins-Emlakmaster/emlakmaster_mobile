// Kaynak PNG'den mağaza ikonu: degrade arka planı kaldırır, 1024×1024 şeffaf PNG üretir.
// Çalıştır: dart run tool/process_app_icon.dart <girdi.png> <çıktı.png>
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('Kullanım: dart run tool/process_app_icon.dart <girdi.png> <çıktı.png>');
    exit(64);
  }
  final inPath = args[0];
  final outPath = args[1];
  final raw = File(inPath).readAsBytesSync();
  final decoded = img.decodeImage(raw);
  if (decoded == null) {
    stderr.writeln('PNG okunamadı: $inPath');
    exit(1);
  }

  final im = decoded.convert(numChannels: 4);
  final marker = img.ColorUint8.rgba(255, 0, 255, 255);
  const threshold = 22.0;

  // Köşelerden taşma: degrade arka planı Lab mesafesiyle seç (plugin fillFlood).
  for (final seed in [
    [0, 0],
    [im.width - 1, 0],
    [0, im.height - 1],
    [im.width - 1, im.height - 1],
    [im.width ~/ 2, 0],
    [im.width ~/ 2, im.height - 1],
    [0, im.height ~/ 2],
    [im.width - 1, im.height ~/ 2],
  ]) {
    final x = seed[0], y = seed[1];
    if (x < 0 || y < 0 || x >= im.width || y >= im.height) continue;
    img.fillFlood(im, x: x, y: y, color: marker, threshold: threshold);
  }

  // Kenar şeridinden ek tohumlar (ince çerçeve / vignette için).
  const strip = 6;
  for (var x = 0; x < im.width; x++) {
    for (var s = 0; s < strip; s++) {
      img.fillFlood(im, x: x, y: s, color: marker, threshold: threshold);
      img.fillFlood(im, x: x, y: im.height - 1 - s, color: marker, threshold: threshold);
    }
  }
  for (var y = 0; y < im.height; y++) {
    for (var s = 0; s < strip; s++) {
      img.fillFlood(im, x: s, y: y, color: marker, threshold: threshold);
      img.fillFlood(im, x: im.width - 1 - s, y: y, color: marker, threshold: threshold);
    }
  }

  for (var y = 0; y < im.height; y++) {
    for (var x = 0; x < im.width; x++) {
      final p = im.getPixel(x, y);
      if (p.r.toInt() == 255 && p.g.toInt() == 0 && p.b.toInt() == 255) {
        im.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  // İçerik boyutu (alfa > 16) — güvenli alan için orantılı yerleştirme.
  var minX = im.width, minY = im.height, maxX = 0, maxY = 0;
  for (var y = 0; y < im.height; y++) {
    for (var x = 0; x < im.width; x++) {
      if (im.getPixel(x, y).a.toInt() > 16) {
        minX = min(minX, x);
        minY = min(minY, y);
        maxX = max(maxX, x);
        maxY = max(maxY, y);
      }
    }
  }
  if (maxX <= minX) {
    stderr.writeln('Ön plan bulunamadı (tüm görüntü şeffaf olabilir).');
    exit(1);
  }
  final crop = img.copyCrop(
    im,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );

  const canvas = 1024;
  // ~%82 güvenli görünür alan (iOS/Android maske); kenarlarda hafif nefes.
  const targetFrac = 0.82;
  final longSide = max(crop.width, crop.height);
  final scale = (canvas * targetFrac) / longSide;
  final nw = max(1, (crop.width * scale).round());
  final nh = max(1, (crop.height * scale).round());
  final scaled = img.copyResize(
    crop,
    width: nw,
    height: nh,
    interpolation: img.Interpolation.cubic,
  );

  final out = img.Image(width: canvas, height: canvas, numChannels: 4);
  for (var y = 0; y < canvas; y++) {
    for (var x = 0; x < canvas; x++) {
      out.setPixelRgba(x, y, 0, 0, 0, 0);
    }
  }
  img.compositeImage(
    out,
    scaled,
    dstX: (canvas - nw) ~/ 2,
    dstY: (canvas - nh) ~/ 2,
  );

  File(outPath).writeAsBytesSync(img.encodePng(out));
  stdout.writeln('Yazıldı: $outPath (${canvas}x$canvas, şeffaf arka plan)');
  stdout.writeln('iOS App Store opak: dart run tool/compose_ios_store_opaque_icon.dart && dart run flutter_launcher_icons');
}
