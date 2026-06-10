import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
class ListingImportShimmer extends StatefulWidget {
  const ListingImportShimmer({super.key});

  @override
  State<ListingImportShimmer> createState() => _ListingImportShimmerState();
}

class _ListingImportShimmerState extends State<ListingImportShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    AppLifecyclePowerService.isInBackground.addListener(_syncAnimationState);
    _syncAnimationState();
  }

  void _syncAnimationState() {
    if (AppLifecyclePowerService.shouldReduceMotion) {
      _c.stop();
      _c.value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    AppLifecyclePowerService.isInBackground.removeListener(_syncAnimationState);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final base = Color.lerp(
          AppThemeExtension.of(context).card.withValues(alpha: 0.45),
          AppThemeExtension.of(context).surfaceElevated.withValues(alpha: 0.75),
          (t * 2 % 1),
        )!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => Container(
            height: 112,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
          ),
        );
      },
    );
  }
}
