import 'package:flutter/material.dart';

/// Shell sekmesi — yalnızca [isActive] iken [child] mount edilir.
///
/// IndexedStack + KeepAlive tüm ziyaret edilen sekmeleri ağaçta tutup
/// Firestore/Riverpod aboneliklerini açık bırakıyordu. Pasif sekmede child
/// unmount olur; veri SWR önbelleğinden anında geri gelir.
class ShellLazyTab extends StatefulWidget {
  const ShellLazyTab({
    super.key,
    required this.isActive,
    required this.child,
  });

  final bool isActive;
  final Widget child;

  @override
  State<ShellLazyTab> createState() => _ShellLazyTabState();
}

class _ShellLazyTabState extends State<ShellLazyTab> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.expand();
    }
    return RepaintBoundary(child: widget.child);
  }
}
