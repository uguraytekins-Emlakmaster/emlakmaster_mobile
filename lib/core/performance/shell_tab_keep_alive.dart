import 'package:flutter/material.dart';

/// Sekme içeriğini canlı tutar; shell [setState] ile gereksiz yeniden oluşturmayı azaltır.
class ShellTabKeepAlive extends StatefulWidget {
  const ShellTabKeepAlive({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ShellTabKeepAlive> createState() => _ShellTabKeepAliveState();
}

class _ShellTabKeepAliveState extends State<ShellTabKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(
      child: widget.child,
    );
  }
}
