import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
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
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.primary,
            DesignTokens.secondary,
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: DesignTokens.surfaceDark,
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
            backgroundColor: DesignTokens.primary.withOpacity(0.25),
            child: Text(
              initials,
              style: TextStyle(
                color: DesignTokens.brandWhite,
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
              backgroundColor: DesignTokens.primary.withOpacity(0.25),
              child: Text(
                initials,
                style: TextStyle(
                  color: DesignTokens.brandWhite,
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

