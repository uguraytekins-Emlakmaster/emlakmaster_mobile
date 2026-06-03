import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Benim Günüm" eğitim turunu yeniden tetiklemek için sinyal sayacı.
/// Ayarlar'daki "Turu tekrar göster" aksiyonu bu değeri artırır; canlı yüzey
/// (ConsultantDailySurface) değişimi dinleyip turu yeniden başlatır.
final consultantTourReplayProvider = StateProvider<int>((ref) => 0);
