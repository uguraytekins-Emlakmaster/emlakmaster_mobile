import 'package:flutter/foundation.dart';

/// Sesli giriş desteklenen platformlar (web hariç).
bool get voiceInputPlatformSupported {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS ||
    TargetPlatform.android ||
    TargetPlatform.macOS =>
      true,
    _ => false,
  };
}
