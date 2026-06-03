import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/login_entry_persona.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/widgets/auth_entry_persona_selector.dart';
import 'package:emlakmaster_mobile/features/onboarding/domain/onboarding_slide_model.dart';
import 'package:flutter/material.dart';

/// Slayt görseli — [assetPath] verilirse gerçek ekran görüntüsü (tema duyarlı),
/// yoksa veya görsel yüklenemezse güvenli şekilde kodla çizilmiş ürün
/// önizlemesine (mockup) düşer. Böylece PNG'ler henüz eklenmemişken bile
/// uygulama derlenir ve sorunsuz çalışır.
class OnboardingSlideVisual extends StatelessWidget {
  const OnboardingSlideVisual({
    super.key,
    required this.kind,
    required this.accent,
    this.assetPath,
    this.legacyAssetPaths = const [],
  });

  final OnboardingVisualKind kind;
  final Color accent;

  /// Gerçek ekran görüntüsü için temel yol (örn. `assets/onboarding/consultant`).
  /// Çalışma anında tema parlaklığına göre `_light.png` / `_dark.png` eklenir.
  final String? assetPath;
  final List<String> legacyAssetPaths;

  /// Tema parlaklığına göre çözülmüş PNG yolu (örn. `..._dark.png`).
  String? _resolveThemedPath(BuildContext context) {
    final base = assetPath;
    if (base == null || base.isEmpty) return null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suffix = isDark ? '_dark' : '_light';
    return '$base$suffix.png';
  }

  @override
  Widget build(BuildContext context) {
    final mockup = _OnboardingDeviceFrame(
      accent: accent,
      child: _buildScene(context),
    );

    final themedPath = _resolveThemedPath(context);
    if (themedPath == null) return mockup;

    // Gerçek ekran görüntüsü; yükleme/format hatasında mockup'a düşer.
    return _OnboardingScreenshotFrame(
      accent: accent,
      assetPath: themedPath,
      fallback: mockup,
    );
  }

  Widget _buildScene(BuildContext context) {
    return switch (kind) {
      OnboardingVisualKind.welcome => _WelcomeScene(accent: accent),
      OnboardingVisualKind.multiPlatform => _MultiPlatformScene(accent: accent),
      OnboardingVisualKind.managerWorkspace =>
        _ManagerCommandScene(accent: accent),
      OnboardingVisualKind.consultantWorkspace =>
        _ConsultantGunumScene(accent: accent),
      OnboardingVisualKind.callsAndMeetings => _CallsScene(accent: accent),
      OnboardingVisualKind.marketAndListings => _MarketScene(accent: accent),
      OnboardingVisualKind.messagesOfficeReady =>
        _OfficeMessagesScene(accent: accent),
    };
  }
}

class _OnboardingDeviceFrame extends StatelessWidget {
  const _OnboardingDeviceFrame({required this.child, required this.accent});

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(ext.surfaceElevated, accent, 0.08)!,
            ext.surface,
            ext.background,
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl - 2),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: _GlowOrb(color: accent, size: 120, opacity: 0.18),
            ),
            Positioned(
              bottom: -20,
              left: -40,
              child: _GlowOrb(color: accent, size: 90, opacity: 0.1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: constraints.maxWidth > 0
                          ? constraints.maxWidth
                          : 280,
                      height: 300,
                      child: child,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gerçek ekran görüntüsünü premium cihaz çerçevesi içinde gösterir.
/// PNG bulunamaz / bozuksa [fallback] (kod mockup) gösterilir.
class _OnboardingScreenshotFrame extends StatelessWidget {
  const _OnboardingScreenshotFrame({
    required this.accent,
    required this.assetPath,
    required this.fallback,
  });

  final Color accent;
  final String assetPath;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        color: ext.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl - 2),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => fallback,
        ),
      ),
    );
  }
}

// ——— Scenes ———

class _WelcomeScene extends StatelessWidget {
  const _WelcomeScene({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MockStatusBar(),
        const SizedBox(height: 6),
        _SparkBanner(
          icon: Icons.auto_awesome_rounded,
          text: 'Tek hesap · iki operasyon yolu',
          accent: accent,
        ),
        const SizedBox(height: 10),
        const Center(
          child: BrandEmblem(variant: BrandEmblemVariant.mini, size: 44),
        ),
        const SizedBox(height: 6),
        Text(
          'Portivo CRM',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ext.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        IgnorePointer(
          child: AuthEntryPersonaSelector(
            selected: LoginEntryPersona.manager,
            onSelected: (_) {},
            compact: true,
          ),
        ),
        const Spacer(),
        _MockPrimaryButton(label: 'Hemen keşfet', accent: accent),
        const SizedBox(height: 2),
      ],
    );
  }
}

class _MultiPlatformScene extends StatelessWidget {
  const _MultiPlatformScene({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _MockStatusBar(),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _DeviceWithMiniUi(
                icon: Icons.phone_iphone_rounded,
                label: 'iPhone',
                height: 78,
                accent: accent,
                child: _MiniUiStrip(accent: accent, lines: 4),
              ),
              const SizedBox(width: 8),
              _DeviceWithMiniUi(
                icon: Icons.tablet_mac_rounded,
                label: 'iPad',
                height: 92,
                accent: accent,
                child: _MiniUiStrip(accent: accent, lines: 5, wide: true),
              ),
              const SizedBox(width: 8),
              _DeviceWithMiniUi(
                icon: Icons.laptop_mac_rounded,
                label: 'Mac',
                height: 68,
                accent: accent,
                child: _MiniUiStrip(accent: accent, lines: 3, wide: true),
              ),
            ],
          ),
        ),
        _SparkBanner(
          icon: Icons.sync_rounded,
          text: 'Anlık senkron · aynı veri',
          accent: accent,
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _ManagerCommandScene extends StatelessWidget {
  const _ManagerCommandScene({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MockStatusBar(),
        _SceneHeader(
          title: ProductLabels.managerHome,
          subtitle: 'Ofis · risk · performans',
          accent: accent,
        ),
        _StatusPill(
          icon: Icons.verified_rounded,
          text: 'Gelir riski düşük · ekip akışı dengede',
          color: ext.success,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _KpiChip(value: '18', label: 'Çağrı', accent: accent),
            const SizedBox(width: 6),
            _KpiChip(value: '12', label: 'Cevap', accent: accent),
            const SizedBox(width: 6),
            _KpiChip(value: '₺4,2M', label: 'Pipeline', accent: accent),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: _cardDecoration(ext, accent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights_rounded, color: accent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Analitik merkezi',
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    _LiveBadge(accent: ext.success),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Kayapınar 3+1 · yatırım iştahı: Yüksek',
                  style: TextStyle(color: ext.textSecondary, fontSize: 10),
                ),
                const Spacer(),
                _Sparkline(accent: accent, values: const [
                  0.35, 0.55, 0.48, 0.72, 0.68, 0.85, 0.9,
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsultantGunumScene extends StatelessWidget {
  const _ConsultantGunumScene({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MockStatusBar(),
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: accent.withValues(alpha: 0.2),
              child: Text(
                'U',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Günaydın!',
                    style: TextStyle(
                      color: ext.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    ProductLabels.consultantHome,
                    style: TextStyle(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _ScoreRing(score: 87, accent: accent),
          ],
        ),
        const SizedBox(height: 8),
        _MockPrimaryButton(
          label: 'Telefon ile ara',
          accent: accent,
          icon: Icons.phone_rounded,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _OutlineAction(
                icon: Icons.auto_awesome_rounded,
                label: 'Akıllı Görüşme',
                accent: accent,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _OutlineAction(
                icon: Icons.history_rounded,
                label: 'Çağrılar',
                accent: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _KpiChip(value: '6', label: 'Bugün', accent: accent, compact: true),
            const SizedBox(width: 6),
            _KpiChip(value: '3', label: 'Açık', accent: accent, compact: true),
            const SizedBox(width: 6),
            _KpiChip(
              value: '2',
              label: 'Sıcak',
              accent: accent,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(child: _HotLeadCard(accent: accent)),
      ],
    );
  }
}

class _CallsScene extends StatelessWidget {
  const _CallsScene({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MockStatusBar(),
        _SceneHeader(
          title: 'Akıllı Görüşme',
          subtitle: 'Özet · görev · CRM tek akış',
          accent: accent,
          icon: Icons.auto_awesome_rounded,
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _CallCard(
                accent: accent,
                phone: '0536 826 07 13',
                name: 'Ayşe Y. · 3+1 Kayapınar',
                status: 'Ulaşıldı',
                statusColor: accent,
                note: 'AI özet: 5–8M bütçe, 15 gün içinde…',
                ai: true,
              ),
              _CallCard(
                accent: accent,
                phone: '0532 441 22 90',
                name: 'Tekrar aranacak',
                status: 'Bekliyor',
                statusColor: const Color(0xFFE8A87C),
                note: 'Görüşme özeti hazır',
              ),
              _CallCard(
                accent: accent,
                phone: ProductLabels.callCenter,
                name: 'Canlı kuyruk',
                status: '2 aktif',
                statusColor: const Color(0xFF6BCB77),
                icon: Icons.headset_mic_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MarketScene extends StatelessWidget {
  const _MarketScene({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MockStatusBar(),
        _SceneHeader(
          title: 'Piyasa & portföy',
          subtitle: 'İlan · içgörü · içe aktarma',
          accent: accent,
          icon: Icons.trending_up_rounded,
        ),
        Row(
          children: [
            Expanded(
              child: _InsightTile(
                title: 'Talep',
                value: '+12%',
                accent: accent,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _InsightTile(
                title: 'Kayapınar',
                value: 'Orta→Yüksek',
                accent: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Column(
            children: [
              _ListingCard(
                accent: accent,
                title: '3+1 · Kayapınar',
                price: '₺6,8M',
                tag: 'Sıcak',
                gradient: [accent, ext.info],
              ),
              _ListingCard(
                accent: accent,
                title: 'Villa · Bodrum',
                price: '₺24M',
                tag: 'Yeni',
                gradient: [const Color(0xFF5B9BD5), accent],
              ),
              _ListingCard(
                accent: accent,
                title: 'Ofis · Levent',
                price: '₺85K/ay',
                tag: 'Kiralık',
                gradient: [ext.success, accent],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OfficeMessagesScene extends StatelessWidget {
  const _OfficeMessagesScene({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MockStatusBar(),
        Row(
          children: [
            Expanded(
              child: _FeatureTile(
                icon: Icons.apartment_rounded,
                label: ProductLabels.officeDesk,
                accent: accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FeatureTile(
                icon: Icons.forum_rounded,
                label: ProductLabels.messageCenter,
                accent: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: _cardDecoration(ext, accent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ProductLabels.messageCenter,
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                _MessageBubble(
                  isMe: false,
                  text: 'İlanınız güncel mi?',
                  name: 'Ayşe',
                  accent: accent,
                ),
                _MessageBubble(
                  isMe: true,
                  text: 'Yarın gösterebilirim.',
                  accent: accent,
                ),
                const Spacer(),
                Text(
                  'Ekip senkron · 3 okunmamış',
                  style: TextStyle(
                    color: ext.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        _MockPrimaryButton(
          label: 'Rolünü seç ve başla',
          accent: accent,
          icon: Icons.rocket_launch_rounded,
        ),
      ],
    );
  }
}

// ——— Primitives ———

BoxDecoration _cardDecoration(AppThemeExtension ext, Color accent) {
  return BoxDecoration(
    color: ext.card.withValues(alpha: 0.72),
    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
    border: Border.all(color: accent.withValues(alpha: 0.28)),
  );
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
    this.opacity = 0.15,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), Colors.transparent],
        ),
      ),
    );
  }
}

class _MockStatusBar extends StatelessWidget {
  const _MockStatusBar();

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Row(
      children: [
        Text(
          '9:41',
          style: TextStyle(
            color: ext.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Icon(Icons.signal_cellular_alt_rounded,
            size: 12, color: ext.textTertiary),
        const SizedBox(width: 4),
        Icon(Icons.wifi_rounded, size: 12, color: ext.textTertiary),
        const SizedBox(width: 4),
        Icon(Icons.battery_full_rounded, size: 14, color: ext.brandPrimary),
      ],
    );
  }
}

class _SparkBanner extends StatelessWidget {
  const _SparkBanner({
    required this.icon,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.2),
            accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: ext.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceWithMiniUi extends StatelessWidget {
  const _DeviceWithMiniUi({
    required this.icon,
    required this.label,
    required this.height,
    required this.accent,
    required this.child,
  });

  final IconData icon;
  final String label;
  final double height;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              color: ext.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: child,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Icon(icon, size: 12, color: accent),
          Text(
            label,
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniUiStrip extends StatelessWidget {
  const _MiniUiStrip({
    required this.accent,
    required this.lines,
    this.wide = false,
  });

  final Color accent;
  final int lines;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < lines; i++) ...[
          Container(
            height: 4,
            width: wide ? double.infinity : 24,
            decoration: BoxDecoration(
              color: ext.textTertiary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (i < lines - 1) const SizedBox(height: 3),
        ],
      ],
    );
  }
}

class _SceneHeader extends StatelessWidget {
  const _SceneHeader({
    required this.title,
    required this.subtitle,
    required this.accent,
    this.icon,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: ext.textSecondary, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppThemeExtension.of(context).textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.value,
    required this.label,
    required this.accent,
    this.compact = false,
  });

  final String value;
  final String label;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: compact ? 5 : 7,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: ext.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 11 : 12,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: ext.textSecondary, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      ),
      child: Text(
        'Canlı',
        style: TextStyle(
          color: accent,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.accent, required this.values});

  final Color accent;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(values: values, color: accent),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.02)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height * (1 - values[i]);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => false;
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.accent});

  final int score;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 4,
            backgroundColor: ext.border.withValues(alpha: 0.5),
            color: accent,
          ),
          Text(
            '$score',
            style: TextStyle(
              color: ext.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockPrimaryButton extends StatelessWidget {
  const _MockPrimaryButton({
    required this.label,
    required this.accent,
    this.icon,
  });

  final String label;
  final Color accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, Color.lerp(accent, Colors.black, 0.25)!],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppThemeExtension.of(context).onBrand),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: AppThemeExtension.of(context).onBrand,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ext.textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HotLeadCard extends StatelessWidget {
  const _HotLeadCard({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(ext, accent),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_rounded, color: accent, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sıcak müşteri',
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '3+1 Kayapınar · teklif bekliyor',
                  style: TextStyle(color: ext.textSecondary, fontSize: 9),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: ext.textTertiary, size: 18),
        ],
      ),
    );
  }
}

class _CallCard extends StatelessWidget {
  const _CallCard({
    required this.accent,
    required this.phone,
    required this.name,
    required this.status,
    required this.statusColor,
    this.note,
    this.ai = false,
    this.icon,
  });

  final Color accent;
  final String phone;
  final String name;
  final String status;
  final Color statusColor;
  final String? note;
  final bool ai;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(9),
      decoration: _cardDecoration(ext, accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: accent.withValues(alpha: 0.15),
                child: Icon(
                  icon ?? Icons.phone_rounded,
                  size: 14,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phone,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      name,
                      style: TextStyle(color: ext.textSecondary, fontSize: 9),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (ai)
                  Icon(Icons.auto_awesome_rounded,
                      size: 12, color: accent),
                if (ai) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ext.textSecondary,
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(ext, accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: ext.textSecondary, fontSize: 9)),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.accent,
    required this.title,
    required this.price,
    required this.tag,
    required this.gradient,
  });

  final Color accent;
  final String title;
  final String price;
  final String tag;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        decoration: _cardDecoration(ext, accent),
        child: Row(
          children: [
            Container(
              width: 44,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(DesignTokens.radiusMd - 1),
                ),
                gradient: LinearGradient(colors: gradient),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            price,
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusPill),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: accent,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.isMe,
    required this.text,
    required this.accent,
    this.name,
  });

  final bool isMe;
  final String text;
  final Color accent;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 200),
        decoration: BoxDecoration(
          color: isMe
              ? accent.withValues(alpha: 0.25)
              : ext.card.withValues(alpha: 0.9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomLeft: Radius.circular(isMe ? 10 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name != null)
              Text(
                name!,
                style: TextStyle(
                  color: accent,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Text(
              text,
              style: TextStyle(color: ext.textPrimary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(ext, accent),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ext.textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
