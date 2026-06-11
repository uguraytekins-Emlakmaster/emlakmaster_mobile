import 'package:flutter/widgets.dart';

/// Eğitim turunun işaret edebileceği kararlı arayüz hedefleri.
/// Her ekran kendi önemli widget'ını [TourTarget] ile sarar; tur, hedefi
/// [TourRegistry] üzerinden çözer. Hedef o an ağaçta değilse adım atlanır.
enum TourTargetId {
  gunumCommandDeck,
  gunumQuickAccess,
  customersHeader,
  callsHeader,
  tasksHeader,
  shellBottomNav,
  settingsHeader,
  // Yönetici / admin kabuğu turu hedefleri.
  managerCommandDeck,
  managerOfficeMomentum,
  managerOperations,
  managerWarRoom,
  managerCommandCenter,
  managerReports,
}

/// Hedef [GlobalKey]'lerini id bazında tutan hafif kayıt defteri (singleton).
/// Pasif sekmeler unmount olduğunda ilgili kayıt otomatik düşer; böylece tur
/// yalnızca o an ekranda olan hedeflere işaret eder.
class TourRegistry {
  TourRegistry._();

  static final TourRegistry instance = TourRegistry._();

  final Map<TourTargetId, GlobalKey> _keys = <TourTargetId, GlobalKey>{};

  void register(TourTargetId id, GlobalKey key) {
    _keys[id] = key;
  }

  void unregister(TourTargetId id, GlobalKey key) {
    if (identical(_keys[id], key)) {
      _keys.remove(id);
    }
  }

  /// Yalnızca o an mount edilmiş (currentContext != null) hedefin anahtarını döndürür.
  GlobalKey? keyFor(TourTargetId id) {
    final key = _keys[id];
    if (key == null) return null;
    if (key.currentContext == null) return null;
    return key;
  }
}

/// Çocuğunu bir [GlobalKey] ile sarar ve [TourRegistry]'ye [id] altında kaydeder.
/// Görsel/davranışsal etkisi yoktur; yalnızca tur hedefi olarak konumlandırır.
class TourTarget extends StatefulWidget {
  const TourTarget({
    super.key,
    required this.id,
    required this.child,
  });

  final TourTargetId id;
  final Widget child;

  @override
  State<TourTarget> createState() => _TourTargetState();
}

class _TourTargetState extends State<TourTarget> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    TourRegistry.instance.register(widget.id, _key);
  }

  @override
  void didUpdateWidget(covariant TourTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      TourRegistry.instance.unregister(oldWidget.id, _key);
      TourRegistry.instance.register(widget.id, _key);
    }
  }

  @override
  void dispose() {
    TourRegistry.instance.unregister(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
