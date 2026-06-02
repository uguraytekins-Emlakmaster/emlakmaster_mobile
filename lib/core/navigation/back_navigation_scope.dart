import 'package:flutter/material.dart';

/// Sekme içi geri önceliği: klavye → arama → seçim → filtre → özel.
typedef BackNavigationCallback = bool Function();

/// Aktif sekme sayfasının sistem geri davranışını kabuğa bildirir.
class BackNavigationScope extends InheritedWidget {
  const BackNavigationScope({
    super.key,
    required super.child,
    this.onDismissKeyboard,
    this.onExitSearch,
    this.onClearSelection,
    this.onCloseFilters,
    this.onCustomBack,
  });

  final BackNavigationCallback? onDismissKeyboard;
  final BackNavigationCallback? onExitSearch;
  final BackNavigationCallback? onClearSelection;
  final BackNavigationCallback? onCloseFilters;
  final BackNavigationCallback? onCustomBack;

  static BackNavigationScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BackNavigationScope>();
  }

  /// Öncelik sırasına göre geri tüketildi mi?
  static bool maybeHandle(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) return false;
    return scope._handle();
  }

  bool _handle() {
    final steps = <BackNavigationCallback?>[
      onDismissKeyboard,
      onExitSearch,
      onClearSelection,
      onCloseFilters,
      onCustomBack,
    ];
    for (final step in steps) {
      if (step != null && step()) return true;
    }
    return false;
  }

  @override
  bool updateShouldNotify(BackNavigationScope oldWidget) {
    return onDismissKeyboard != oldWidget.onDismissKeyboard ||
        onExitSearch != oldWidget.onExitSearch ||
        onClearSelection != oldWidget.onClearSelection ||
        onCloseFilters != oldWidget.onCloseFilters ||
        onCustomBack != oldWidget.onCustomBack;
  }
}

/// Sekme köküne kolay kayıt — [AdaptiveShellScaffold] ile birlikte kullanın.
class ShellTabBackRegistrar extends StatefulWidget {
  const ShellTabBackRegistrar({
    super.key,
    required this.child,
    this.onExitSearch,
    this.onClearSelection,
    this.onCloseFilters,
    this.onCustomBack,
  });

  final Widget child;
  final BackNavigationCallback? onExitSearch;
  final BackNavigationCallback? onClearSelection;
  final BackNavigationCallback? onCloseFilters;
  final BackNavigationCallback? onCustomBack;

  @override
  State<ShellTabBackRegistrar> createState() => _ShellTabBackRegistrarState();
}

class _ShellTabBackRegistrarState extends State<ShellTabBackRegistrar> {
  /// Yalnızca gerçek bir [EditableText] (klavye) odaktayken true.
  ///
  /// `primaryFocus.hasFocus`, metin alanı olmasa bile rotanın FocusScope'u
  /// odakta olduğu için neredeyse her zaman true döner; sadece `hasFocus`
  /// kontrolü geri basışını sessizce yutar. Bu yüzden odağın bir
  /// [EditableText] olup olmadığını doğrularız.
  bool _dismissKeyboard() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || !focus.hasFocus) return false;
    final ctx = focus.context;
    if (ctx == null ||
        ctx.findAncestorWidgetOfExactType<EditableText>() == null) {
      return false;
    }
    focus.unfocus();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BackNavigationScope(
      onDismissKeyboard: _dismissKeyboard,
      onExitSearch: widget.onExitSearch,
      onClearSelection: widget.onClearSelection,
      onCloseFilters: widget.onCloseFilters,
      onCustomBack: widget.onCustomBack,
      child: widget.child,
    );
  }
}
