import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ana kabuk (danışman / yönetici / müşteri) bir sonraki karede hesap sekmesine geçsin.
/// [AdaptiveShellScaffold] dinler; indeks her kabukta son sekmedir (Ayarlar veya Profil).
enum MainShellShortcut { openAccountTab }

final mainShellShortcutProvider = StateProvider<MainShellShortcut?>((ref) => null);
