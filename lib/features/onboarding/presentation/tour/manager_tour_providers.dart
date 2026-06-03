import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yönetici eğitim turunu yeniden tetiklemek için sinyal sayacı.
/// Ayarlar'daki "Turu tekrar göster" aksiyonu bu değeri artırır; her zaman
/// ağaçta olan [ManagerTourHost] değişimi dinleyip turu yeniden başlatır.
final managerTourReplayProvider = StateProvider<int>((ref) => 0);
