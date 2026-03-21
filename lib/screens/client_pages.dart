import 'package:emlakmaster_mobile/core/services/auth_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Müşteri: Arama — kriter girip danışmana talep iletir.
class ClientSearchPage extends StatefulWidget {
  const ClientSearchPage({super.key});

  @override
  State<ClientSearchPage> createState() => _ClientSearchPageState();
}

class _ClientSearchPageState extends State<ClientSearchPage> {
  final _query = TextEditingController();
  String _type = 'Konut';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final onSurface = theme.colorScheme.onSurface;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;

    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.space5),
          children: [
            Text(
              'Ne arıyorsunuz?',
              style: theme.textTheme.titleLarge?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tercihlerinizi yazın; danışmanınız size uygun ilanları seçip geri dönecek.',
              style: TextStyle(color: onSurface.withValues(alpha: 0.75), fontSize: 14),
            ),
            const SizedBox(height: DesignTokens.space5),
            Text('Tür', style: TextStyle(color: onSurface.withValues(alpha: 0.8), fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Konut', 'Arsa', 'İşyeri'].map((t) {
                final sel = _type == t;
                return FilterChip(
                  label: Text(t),
                  selected: sel,
                  onSelected: (_) => setState(() => _type = t),
                  selectedColor: DesignTokens.primary.withValues(alpha: 0.25),
                  checkmarkColor: DesignTokens.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: DesignTokens.space4),
            TextField(
              controller: _query,
              maxLines: 4,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                hintText: 'Örn: 3+1, Kayapınar, 4–6 M TL bütçe…',
                hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.45)),
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  borderSide: BorderSide(color: border),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space5),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                final q = _query.text.trim();
                if (q.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Lütfen arama kriterlerinizi yazın.'),
                      backgroundColor: DesignTokens.danger,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  return;
                }
                showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: DesignTokens.success, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Talebiniz alındı',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '“$_type · $q” bilgisi danışmanınıza iletilmek üzere kaydedildi. En kısa sürede sizinle iletişime geçilecek.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: onSurface.withValues(alpha: 0.8), height: 1.45),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: FilledButton.styleFrom(
                            backgroundColor: DesignTokens.primary,
                            foregroundColor: DesignTokens.inputTextOnGold,
                          ),
                          child: const Text('Tamam'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.primary,
                foregroundColor: DesignTokens.inputTextOnGold,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Danışmanıma gönder'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Müşteri: Favoriler — örnek portföy + bilgi.
class ClientFavoritesPage extends StatelessWidget {
  const ClientFavoritesPage({super.key});

  static const _samples = [
    ('3+1 Daire · Bağlar', 'Geniş balkon, güney cephe'),
    ('Arsa · Yenişehir', 'İmarlı, yola cephe'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final onSurface = theme.colorScheme.onSurface;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;

    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.space5),
          children: [
            Text(
              'Favorilerim',
              style: theme.textTheme.titleLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Uygulamada favori kaydı açıldığında ilanlarınız burada listelenecek. Şimdilik örnek portföyümüzden ilham alabilirsiniz.',
              style: TextStyle(color: onSurface.withValues(alpha: 0.75), fontSize: 14),
            ),
            const SizedBox(height: DesignTokens.space5),
            ..._samples.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: surface,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(s.$1),
                            content: Text(
                              '${s.$2}\n\nDetay ve randevu için ofisimizi arayabilir veya mesaj sekmesinden yazabilirsiniz.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Kapat'),
                              ),
                            ],
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                      child: Container(
                        padding: const EdgeInsets.all(DesignTokens.space4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                          border: Border.all(color: border.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.home_work_rounded, color: DesignTokens.primary, size: 36),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.$1, style: TextStyle(color: onSurface, fontWeight: FontWeight.w700)),
                                  Text(s.$2, style: TextStyle(color: onSurface.withValues(alpha: 0.65), fontSize: 13)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: onSurface.withValues(alpha: 0.4)),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

/// Müşteri: Mesajlar — iletişim kanalları.
class ClientMessagesPage extends StatelessWidget {
  const ClientMessagesPage({super.key});

  Future<void> _open(Uri u) async {
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final onSurface = theme.colorScheme.onSurface;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;

    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.space5),
          children: [
            Text(
              'İletişim',
              style: theme.textTheme.titleLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Danışmanınızla görüşmek için aşağıdaki seçeneklerden birini kullanın.',
              style: TextStyle(color: onSurface.withValues(alpha: 0.75), fontSize: 14),
            ),
            const SizedBox(height: DesignTokens.space5),
            _msgTile(
              context,
              surface: surface,
              border: border,
              onSurface: onSurface,
              icon: Icons.chat_rounded,
              title: 'WhatsApp ile yazın',
              subtitle: 'Hızlı mesaj için WhatsApp açılır',
              onTap: () {
                HapticFeedback.lightImpact();
                _open(Uri.parse('https://wa.me/?text=${Uri.encodeComponent('Merhaba, EmlakMaster müşterisiyim. Görüşmek istiyorum.')}'));
              },
            ),
            const SizedBox(height: 12),
            _msgTile(
              context,
              surface: surface,
              border: border,
              onSurface: onSurface,
              icon: Icons.phone_rounded,
              title: 'Telefon',
              subtitle: 'Ofis hattını arayın',
              onTap: () {
                HapticFeedback.lightImpact();
                _open(Uri(scheme: 'tel', path: '+908503021234'));
              },
            ),
            const SizedBox(height: 12),
            _msgTile(
              context,
              surface: surface,
              border: border,
              onSurface: onSurface,
              icon: Icons.email_rounded,
              title: 'E-posta',
              subtitle: 'info@rainbowgayrimenkul.com (örnek)',
              onTap: () {
                HapticFeedback.lightImpact();
                _open(Uri(scheme: 'mailto', path: 'info@example.com', queryParameters: {'subject': 'EmlakMaster müşteri'}));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _msgTile(
    BuildContext context, {
    required Color surface,
    required Color border,
    required Color onSurface,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(color: border.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: DesignTokens.primary.withValues(alpha: 0.2),
                child: Icon(icon, color: DesignTokens.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: onSurface, fontWeight: FontWeight.w700)),
                    Text(subtitle, style: TextStyle(color: onSurface.withValues(alpha: 0.65), fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, size: 20, color: onSurface.withValues(alpha: 0.45)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Müşteri: Sanal tur — örnek 360 içerikler.
class ClientVirtualTourPage extends StatelessWidget {
  const ClientVirtualTourPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final onSurface = theme.colorScheme.onSurface;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;

    final tours = [
      ('Örnek daire turu', 'YouTube üzerinde 360° örnek', 'https://www.youtube.com/results?search_query=360+apartment+tour'),
      ('Boş dağıtım', 'Mimari gezinti örneği', 'https://www.youtube.com/results?search_query=real+estate+virtual+tour'),
    ];

    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.space5),
          children: [
            Text(
              'Sanal tur',
              style: theme.textTheme.titleLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Aşağıdaki bağlantılar harici sitede örnek sanal tur içerikleri açar.',
              style: TextStyle(color: onSurface.withValues(alpha: 0.75), fontSize: 14),
            ),
            const SizedBox(height: DesignTokens.space5),
            ...tours.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: surface,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    child: InkWell(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        final u = Uri.parse(t.$3);
                        if (await canLaunchUrl(u)) {
                          await launchUrl(u, mode: LaunchMode.externalApplication);
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bağlantı açılamadı.')),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(DesignTokens.space5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                          border: Border.all(color: border.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: DesignTokens.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.threesixty_rounded, color: DesignTokens.primary, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.$1, style: TextStyle(color: onSurface, fontWeight: FontWeight.w700)),
                                  Text(t.$2, style: TextStyle(color: onSurface.withValues(alpha: 0.65), fontSize: 13)),
                                ],
                              ),
                            ),
                            const Icon(Icons.play_circle_fill_rounded, color: DesignTokens.primary, size: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

/// Müşteri: Profil — hesap ve çıkış.
class ClientProfilePage extends ConsumerWidget {
  const ClientProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final avatarLetter = () {
      final label = user?.email ?? user?.displayName ?? 'M';
      return label.isNotEmpty ? label[0].toUpperCase() : '?';
    }();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final onSurface = theme.colorScheme.onSurface;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;

    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.space5),
          children: [
            Text(
              'Profil',
              style: theme.textTheme.titleLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DesignTokens.space5),
            Container(
              padding: const EdgeInsets.all(DesignTokens.space5),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                border: Border.all(color: border.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: DesignTokens.primary.withValues(alpha: 0.2),
                    child: Text(
                      avatarLetter,
                      style: const TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w800, fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email ?? 'Giriş yapılmamış',
                          style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Müşteri hesabı',
                          style: TextStyle(color: onSurface.withValues(alpha: 0.65), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                side: BorderSide(color: border.withValues(alpha: 0.5)),
              ),
              tileColor: surface,
              leading: const Icon(Icons.privacy_tip_outlined, color: DesignTokens.primary),
              title: Text('KVKK & gizlilik', style: TextStyle(color: onSurface)),
              subtitle: Text('Verileriniz nasıl kullanılır?', style: TextStyle(color: onSurface.withValues(alpha: 0.65), fontSize: 12)),
              trailing: Icon(Icons.chevron_right_rounded, color: onSurface.withValues(alpha: 0.4)),
              onTap: () {
                HapticFeedback.lightImpact();
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Gizlilik'),
                    content: const SingleChildScrollView(
                      child: Text(
                        'Kişisel verileriniz yalnızca hizmet sunumu ve yasal yükümlülükler kapsamında işlenir. '
                        'Detaylı bilgi için ofisimizle iletişime geçebilirsiniz.',
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: DesignTokens.space6),
            if (user != null)
              OutlinedButton.icon(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await AuthService.instance.signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Çıkış yap'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DesignTokens.danger,
                  side: const BorderSide(color: DesignTokens.danger),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
