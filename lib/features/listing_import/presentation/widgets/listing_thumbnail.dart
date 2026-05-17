import 'package:cached_network_image/cached_network_image.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';

/// İlan grid küçük görseli — önbellek + shimmer placeholder.
class ListingThumbnail extends StatelessWidget {
  const ListingThumbnail({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 16 / 9,
  });

  final String imageUrl;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        memCacheWidth: 640,
        memCacheHeight: 360,
        placeholder: (_, __) => ColoredBox(
          color: ext.surfaceElevated,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ext.accent.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: ext.surfaceElevated,
          child: const Icon(Icons.image_not_supported_outlined),
        ),
      ),
    );
  }
}
