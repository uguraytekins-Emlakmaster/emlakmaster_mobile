import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_capture_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handoff sonrası kabuk üst şeridi — Çağrılarım sekmesinde gövde banner kullanılır.
class PostCallCaptureShellStrip extends ConsumerWidget {
  const PostCallCaptureShellStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SafeArea(
      bottom: false,
      left: false,
      right: false,
      child: PostCallCaptureBanner(insetPadding: false),
    );
  }
}
