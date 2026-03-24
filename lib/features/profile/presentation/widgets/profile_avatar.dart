import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/skeleton_loader.dart';
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.size = 40,
    this.imageUrl,
    this.fallbackText,
  });

  final double size;
  final String? imageUrl;
  final String? fallbackText;

  @override
  Widget build(BuildContext context) {
    final initials = (fallbackText ?? '?').trim().isEmpty
        ? '?'
        : fallbackText!.trim().substring(0, 1).toUpperCase();

    final border = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemeExtension.of(context).accent,
            AppThemeExtension.of(context).accent,
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppThemeExtension.of(context).surface,
        ),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          border,
          CircleAvatar(
            radius: size / 2 - 3,
            backgroundColor: AppThemeExtension.of(context).accent.withValues(alpha: 0.25),
            child: Text(
              initials,
              style: TextStyle(
                color: AppThemeExtension.of(context).onAccentLight,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.4,
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        border,
        ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: size - 4,
            height: size - 4,
            fit: BoxFit.cover,
            placeholder: (context, url) => SkeletonLoader(
              width: size - 4,
              height: size - 4,
              borderRadius: BorderRadius.circular(size),
            ),
            errorWidget: (context, url, error) => CircleAvatar(
              radius: size / 2 - 3,
              backgroundColor: AppThemeExtension.of(context).accent.withValues(alpha: 0.25),
              child: Text(
                initials,
                style: TextStyle(
                  color: AppThemeExtension.of(context).onAccentLight,
                  fontWeight: FontWeight.w600,
                  fontSize: size * 0.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

