import 'dart:async';

import 'package:flutter/material.dart';

/// Arama kutusu — her tuşta değil, gecikmeli [onQueryChanged] (tam sayfa rebuild önlemi).
class DebouncedSearchController {
  DebouncedSearchController({
    this.debounce = const Duration(milliseconds: 280),
    required this.onQueryChanged,
  }) : controller = TextEditingController() {
    controller.addListener(_onTextChanged);
  }

  final Duration debounce;
  final void Function(String query) onQueryChanged;
  final TextEditingController controller;
  Timer? _timer;

  void _onTextChanged() {
    _timer?.cancel();
    _timer = Timer(debounce, () {
      onQueryChanged(controller.text.trim());
    });
  }

  void dispose() {
    _timer?.cancel();
    controller.removeListener(_onTextChanged);
    controller.dispose();
  }
}
