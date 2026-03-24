import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
/// AR/VR Ready: 360° görüntüleyici (URL açma) ve Lidar meta.
class ListingMedia360Placeholder extends StatelessWidget {
  const ListingMedia360Placeholder({
    super.key,
    this.media360Urls = const [],
    this.lidarScanId,
  });

  final List<String> media360Urls;
  final String? lidarScanId;

  @override
  Widget build(BuildContext context) {
    final has360 = media360Urls.isNotEmpty;
    final hasLidar = lidarScanId != null && lidarScanId!.isNotEmpty;

    if (!has360 && !hasLidar) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: AppThemeExtension.of(context).surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppThemeExtension.of(context).border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.panorama_photosphere_select_rounded, size: 20, color: AppThemeExtension.of(context).accent),
              const SizedBox(width: DesignTokens.space2),
              Text(
                '360° & 3D',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppThemeExtension.of(context).textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),
          if (has360)
            Wrap(
              spacing: DesignTokens.space2,
              runSpacing: DesignTokens.space2,
              children: media360Urls.take(3).map((url) => _Chip(label: '360°', url: url)).toList(),
            ),
          if (hasLidar) ...[
            if (has360) const SizedBox(height: DesignTokens.space2),
            const _Chip(label: 'Lidar tarama'),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.url});
  final String label;
  final String? url;

  Future<void> _openUrl(BuildContext context, String? uri) async {
    if (uri == null || uri.isEmpty) return;
    final parsed = Uri.tryParse(uri);
    if (parsed == null) return;
    try {
      if (await canLaunchUrl(parsed)) {
        await launchUrl(parsed);
      } else if (context.mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link açılamadı.'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {
      if (context.mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link açılamadı.'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: url != null ? () => _openUrl(context, url) : null,
      backgroundColor: AppThemeExtension.of(context).surfaceElevated,
      side: BorderSide(color: AppThemeExtension.of(context).accent.withValues(alpha: 0.5)),
    );
  }
}
