import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/client_portal_tokens.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Müşteri iletişim kanalları — yalnızca gerçek url_launcher aksiyonları.
abstract final class ClientPortalContactActions {
  ClientPortalContactActions._();

  static Future<void> openWhatsApp() async {
    AppFeedback.lightImpact();
    await _open(
      Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent('Merhaba, EmlakMaster müşterisiyim. Görüşmek istiyorum.')}',
      ),
    );
  }

  static Future<void> openPhone() async {
    AppFeedback.lightImpact();
    await _open(Uri(scheme: 'tel', path: '+908503021234'));
  }

  static Future<void> openEmail() async {
    AppFeedback.lightImpact();
    await _open(
      Uri(
        scheme: 'mailto',
        path: 'info@example.com',
        queryParameters: {'subject': 'EmlakMaster müşteri'},
      ),
    );
  }

  static Future<void> _open(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Hafif client yüzey — blur/glow yok (mobil FPS).
class ClientPortalSurface extends StatelessWidget {
  const ClientPortalSurface({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: ClientPortalTokens.horizontal),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.surface.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ext.border.withValues(alpha: 0.32)),
        ),
        child: child,
      ),
    );
  }
}

class ClientContactChannelTile extends StatelessWidget {
  const ClientContactChannelTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent,
    this.highlightLabel,
    this.trailingIcon = Icons.open_in_new_rounded,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accent;
  final String? highlightLabel;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tone = accent ?? ext.accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalTokens.horizontal,
        0,
        ClientPortalTokens.horizontal,
        8,
      ),
      child: Material(
        color: ext.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlightLabel != null
                    ? tone.withValues(alpha: 0.42)
                    : ext.border.withValues(alpha: 0.32),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: tone.withValues(alpha: 0.14),
                      border: Border.all(color: tone.withValues(alpha: 0.28)),
                    ),
                    child: Icon(icon, color: tone, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: ext.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            if (highlightLabel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: tone.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: tone.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  highlightLabel!,
                                  style: TextStyle(
                                    color: tone,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: ext.textSecondary,
                            fontSize: 11.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(trailingIcon, size: 18, color: ext.textTertiary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ClientVirtualTourCard extends StatelessWidget {
  const ClientVirtualTourCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.previewLabel = 'Harici · Örnek',
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String previewLabel;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalTokens.horizontal,
        0,
        ClientPortalTokens.horizontal,
        10,
      ),
      child: Material(
        color: ext.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ext.border.withValues(alpha: 0.32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 92,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ext.accent.withValues(alpha: 0.24),
                        ext.surfaceElevated.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.threesixty_rounded,
                          color: ext.accent.withValues(alpha: 0.85),
                          size: 36,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ext.surface.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ext.info.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            previewLabel,
                            style: TextStyle(
                              color: ext.info,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: ext.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: ext.textSecondary,
                                fontSize: 11.5,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: ext.accent,
                        size: 34,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ClientProfileMenuRow extends StatelessWidget {
  const ClientProfileMenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tone = destructive ? ext.danger : ext.accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalTokens.horizontal,
        0,
        ClientPortalTokens.horizontal,
        8,
      ),
      child: Material(
        color: ext.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ext.border.withValues(alpha: 0.32)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(icon, color: tone, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: destructive ? ext.danger : ext.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: ext.textSecondary,
                            fontSize: 11,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing ??
                      Icon(
                        Icons.chevron_right_rounded,
                        color: ext.textTertiary,
                        size: 20,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ClientCompactInfoStrip extends StatelessWidget {
  const ClientCompactInfoStrip({super.key, required this.cells});

  final List<(String value, String label)> cells;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return ClientPortalSurface(
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 28,
                  color: ext.border.withValues(alpha: 0.28),
                ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cells[i].$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      cells[i].$2,
                      style: TextStyle(
                        color: ext.textTertiary,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

double clientPortalDockBottomReserve(BuildContext context) {
  final ts = MediaQuery.textScalerOf(context);
  final ratio =
      ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
  return 112 * ratio.clamp(1.0, 1.38);
}
