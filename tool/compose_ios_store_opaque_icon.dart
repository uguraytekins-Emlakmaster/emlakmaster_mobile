// Şeffaf MASTER → App Store uyumlu opak RGB PNG (alfa yok).
// Çalıştır: dart run tool/compose_ios_store_opaque_icon.dart
import 'dart:io';

import 'package:image/image.dart' as img;

const _defaultFg = 'assets/branding/emlak_master_app_icon_MASTER.png';
const _defaultOut = 'assets/branding/emlak_master_app_icon_IOS_STORE_OPAQUE.png';

/// Arka plan #050508 — adaptive_icon_background ile aynı.
const _bgR = 5, _bgG = 5, _bgB = 8;

void main(List<String> args) {
  final fgPath = args.isNotEmpty ? args[0] : _defaultFg;
  final outPath = args.length > 1 ? args[1] : _defaultOut;

  final decoded = img.decodePng(File(fgPath).readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('PNG okunamadı: $fgPath');
    exit(1);
  }
  if (decoded.width != 1024 || decoded.height != 1024) {
    stderr.writeln('Beklenen 1024×1024, gelen: ${decoded.width}×${decoded.height}');
    exit(1);
  }

  final fg = decoded.convert(numChannels: 4);
  final base = img.Image(width: 1024, height: 1024, numChannels: 4);
  for (var y = 0; y < 1024; y++) {
    for (var x = 0; x < 1024; x++) {
      base.setPixelRgba(x, y, _bgR, _bgG, _bgB, 255);
    }
  }
  img.compositeImage(base, fg);

  final rgb = base.convert(numChannels: 3);
  File(outPath).writeAsBytesSync(img.encodePng(rgb));
  stdout.writeln('Opak mağaza ikonu: $outPath (RGB, alfa yok)');
}
