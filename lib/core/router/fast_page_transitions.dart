import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Sık açılan CRM rotaları için kısa fade (varsayılan ~300ms yerine).
CustomTransitionPage<T> fastFadePage<T>({
  required LocalKey key,
  String? name,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    name: name,
    transitionDuration: const Duration(milliseconds: 120),
    reverseTransitionDuration: const Duration(milliseconds: 100),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(opacity: curved, child: child);
    },
  );
}
