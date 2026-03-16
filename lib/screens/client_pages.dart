import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Müşteri paneli: Arama (Search-focused). Placeholder — ilan arama UI buraya taşınacak.
class ClientSearchPage extends StatelessWidget {
  const ClientSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ClientPlaceholder(
      icon: Icons.search_rounded,
      title: 'İlan Ara',
      subtitle: 'Konum, fiyat ve özelliklere göre arama yapın. Favorilere ekleyebilir, danışmanla iletişime geçebilirsiniz.',
    );
  }
}

/// Müşteri: Favoriler. Placeholder — kayıtlı favori ilanlar listesi.
class ClientFavoritesPage extends StatelessWidget {
  const ClientFavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ClientPlaceholder(
      icon: Icons.favorite_rounded,
      title: 'Favorilerim',
      subtitle: 'Kaydettiğiniz ilanlar burada listelenecek.',
    );
  }
}

/// Müşteri: Mesajlar. Placeholder — danışmanla doğrudan iletişim.
class ClientMessagesPage extends StatelessWidget {
  const ClientMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ClientPlaceholder(
      icon: Icons.chat_rounded,
      title: 'Mesajlar',
      subtitle: 'Danışmanlarla mesajlaşma burada görünecek.',
    );
  }
}

/// Müşteri: Sanal tur erişimi. Placeholder — virtual tour links/content.
class ClientVirtualTourPage extends StatelessWidget {
  const ClientVirtualTourPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ClientPlaceholder(
      icon: Icons.video_camera_back_rounded,
      title: 'Sanal Tur',
      subtitle: 'Sanal tur linkleri ve kayıtlarınız burada.',
    );
  }
}

/// Müşteri: Profil / Hesap. Placeholder — ayarlar, çıkış.
class ClientProfilePage extends StatelessWidget {
  const ClientProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ClientPlaceholder(
      icon: Icons.person_rounded,
      title: 'Profil',
      subtitle: 'Hesap bilgileri ve tercihler.',
    );
  }
}

class _ClientPlaceholder extends StatelessWidget {
  const _ClientPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final textColor = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    final secondary = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;

    return Container(
      color: isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.space6),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
                    border: Border.all(color: DesignTokens.borderDark.withOpacity(0.5)),
                  ),
                  child: Icon(icon, size: 56, color: DesignTokens.primary.withOpacity(0.9)),
                ),
                const SizedBox(height: DesignTokens.space5),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.space2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: secondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
