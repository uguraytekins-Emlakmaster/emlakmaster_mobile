import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Danışman eğitim turunu yeniden tetiklemek için sinyal sayacı.
/// Ayarlar'daki "Turu tekrar göster" aksiyonu bu değeri artırır; her zaman
/// ağaçta olan [ConsultantTourHost] değişimi dinleyip turu yeniden başlatır.
final consultantTourReplayProvider = StateProvider<int>((ref) => 0);
