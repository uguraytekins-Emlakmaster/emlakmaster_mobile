import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/login_entry_persona.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/widgets/auth_entry_persona_selector.dart';
import 'package:emlakmaster_mobile/features/onboarding/domain/onboarding_slide_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Slayt görsel alanı — telefon çerçevesi içinde ürün arayüzü önizlemesi.
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
  final String? assetPath;
  final List<String> legacyAssetPaths;

  @override
  Widget build(BuildContext context) {
    final mock = _buildMock(context);
    return _OnboardingDeviceFrame(
      accent: accent,
      child: _OnboardingAssetLayer(
        primaryPath: assetPath,
        legacyPaths: legacyAssetPaths,
        accent: accent,
        mock: mock,
      ),
    );
  }

  Widget _buildMock(BuildContext context) {
    return switch (kind) {
      OnboardingVisualKind.welcome => _WelcomePreview(accent: accent),
      OnboardingVisualKind.managerWorkspace =>
        _ShellNavPreview.manager(accent: accent),
      OnboardingVisualKind.consultantWorkspace =>
        _ShellNavPreview.consultant(accent: accent),
      OnboardingVisualKind.callsAndMeetings => _CallsPreview(accent: accent),
      OnboardingVisualKind.marketAndListings => _MarketPreview(accent: accent),
      OnboardingVisualKind.messagesOfficeReady =>
        _OfficeMessagesPreview(accent: accent),
    };
  }
}

/// PNG varsa üstte ekran görüntüsü; yoksa tam mock. İkisi varsa görüntü + altta mock şeridi.
class _OnboardingAssetLayer extends StatefulWidget {
  const _OnboardingAssetLayer({
    required this.primaryPath,
    required this.legacyPaths,
    required this.accent,
    required this.mock,
  });

  final String? primaryPath;
  final List<String> legacyPaths;
  final Color accent;
  final Widget mock;

  @override
  State<_OnboardingAssetLayer> createState() => _OnboardingAssetLayerState();
}

class _OnboardingAssetLayerState extends State<_OnboardingAssetLayer> {
  /// null = henüz taranmadı; '' = PNG yok; dolu = kullanılacak asset yolu.
  String? _resolvedPath;

  @override
  void initState() {
    super.initState();
    _resolveAsset();
  }

  @override
  void didUpdateWidget(covariant _OnboardingAssetLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryPath != widget.primaryPath ||
        oldWidget.legacyPaths != widget.legacyPaths) {
      _resolvedPath = null;
      _resolveAsset();
    }
  }

  Future<void> _resolveAsset() async {
    final candidates = <String>[
      if (widget.primaryPath != null) widget.primaryPath!,
      ...widget.legacyPaths,
    ];
    for (final path in candidates) {
      try {
        await rootBundle.load(path);
        if (!mounted) return;
        setState(() => _resolvedPath = path);
        return;
      } catch (_) {
        continue;
      }
    }
    if (mounted) setState(() => _resolvedPath = '');
  }

  @override
  Widget build(BuildContext context) {
    final path = _resolvedPath;
    if (path == null || path.isEmpty) {
      return widget.mock;
    }

    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 7,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  path,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        ext.background.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          flex: 4,
          child: Opacity(opacity: 0.92, child: widget.mock),
        ),
      ],
    );
  }
}

class _OnboardingDeviceFrame extends StatelessWidget {
  const _OnboardingDeviceFrame({
    required this.child,
    required this.accent,
  });

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ext.surfaceElevated,
            ext.surface,
            ext.background,
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl - 2),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: child,
        ),
      ),
    );
  }
}

class _WelcomePreview extends StatelessWidget {
  const _WelcomePreview({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      children: [
        _MockStatusBar(accent: accent),
        const SizedBox(height: DesignTokens.space4),
        const BrandEmblem(variant: BrandEmblemVariant.mini, size: 56),
        const SizedBox(height: DesignTokens.space3),
        Text(
          'EmlakMaster',
          style: TextStyle(
            color: ext.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        IgnorePointer(
          child: AuthEntryPersonaSelector(
            selected: LoginEntryPersona.manager,
            onSelected: (_) {},
            compact: true,
          ),
        ),
        const Spacer(),
        _MockPrimaryButton(label: 'Giriş yap', accent: accent),
        const SizedBox(height: DesignTokens.space2),
      ],
    );
  }
}

class _ShellNavPreview extends StatelessWidget {
  const _ShellNavPreview._({
    required this.accent,
    required this.title,
    required this.navItems,
    required this.activeIndex,
    required this.bodyLines,
  });

  factory _ShellNavPreview.manager({required Color accent}) {
    return _ShellNavPreview._(
      accent: accent,
      title: ProductLabels.managerWorkspace,
      activeIndex: 0,
      navItems: const [
        _NavMock(Icons.dashboard_rounded, ProductLabels.managerHome),
        _NavMock(Icons.military_tech_rounded, ProductLabels.warRoom),
        _NavMock(Icons.call_rounded, ProductLabels.callCenter),
        _NavMock(Icons.analytics_rounded, ProductLabels.reports),
        _NavMock(Icons.settings_rounded, ProductLabels.settings),
      ],
      bodyLines: const [
        'Bugünkü çağrılar',
        'Açık görevler',
        'Ekip performansı',
      ],
    );
  }

  factory _ShellNavPreview.consultant({required Color accent}) {
    return _ShellNavPreview._(
      accent: accent,
      title: ProductLabels.consultantWorkspace,
      activeIndex: 0,
      navItems: const [
        _NavMock(Icons.dashboard_rounded, ProductLabels.consultantHome),
        _NavMock(Icons.call_rounded, ProductLabels.myCalls),
        _NavMock(Icons.people_rounded, ProductLabels.myCustomers),
        _NavMock(Icons.home_work_rounded, ProductLabels.listings),
        _NavMock(Icons.replay_rounded, ProductLabels.followUp),
        _NavMock(Icons.task_alt_rounded, ProductLabels.myTasks),
      ],
      bodyLines: const [
        'Akıllı Görüşme',
        'Günün randevuları',
        'Takip bekleyen',
      ],
    );
  }

  final Color accent;
  final String title;
  final List<_NavMock> navItems;
  final int activeIndex;
  final List<String> bodyLines;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MockStatusBar(accent: accent),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 52,
                decoration: BoxDecoration(
                  color: ext.card.withValues(alpha: 0.85),
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: ext.border.withValues(alpha: 0.7)),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: navItems.length,
                  itemBuilder: (context, i) {
                    final item = navItems[i];
                    final selected = i == activeIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? accent.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              item.icon,
                              size: 18,
                              color: selected ? accent : ext.textTertiary,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _shortNav(item.label),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 7,
                                height: 1.1,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? ext.textPrimary
                                    : ext.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ext.card.withValues(alpha: 0.6),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusMd),
                    border:
                        Border.all(color: ext.border.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final line in bodyLines) ...[
                        _MockMetricRow(label: line, accent: accent),
                        const SizedBox(height: 6),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent.withValues(alpha: 0.22),
                              accent.withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusSm),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: accent, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                navItems[activeIndex].label,
                                style: TextStyle(
                                  color: ext.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _shortNav(String label) {
    if (label.length <= 8) return label;
    if (label.contains(' ')) {
      return label.split(' ').first;
    }
    return label.length > 9 ? '${label.substring(0, 8)}…' : label;
  }
}

class _CallsPreview extends StatelessWidget {
  const _CallsPreview({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MockStatusBar(accent: accent),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akıllı Görüşme',
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Tek dokunuşla arama başlat',
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: ext.textTertiary),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              _CallLogTile(
                name: 'Müşteri — görüşme özeti',
                meta: 'Kayıt tamamlandı',
                accent: accent,
                icon: Icons.check_circle_outline_rounded,
              ),
              _CallLogTile(
                name: ProductLabels.myCalls,
                meta: '3 bekleyen geri arama',
                accent: accent,
                icon: Icons.phone_in_talk_rounded,
              ),
              _CallLogTile(
                name: ProductLabels.callCenter,
                meta: 'Canlı kuyruk: 2',
                accent: accent,
                icon: Icons.headset_mic_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MarketPreview extends StatelessWidget {
  const _MarketPreview({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MockStatusBar(accent: accent),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MiniChartCard(
                title: 'Piyasa',
                accent: accent,
                bars: const [0.4, 0.7, 0.55, 0.9, 0.65],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniChartCard(
                title: 'Bölge',
                accent: accent,
                bars: const [0.6, 0.5, 0.8, 0.45, 0.75],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ext.card.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: ext.border.withValues(alpha: 0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.home_work_rounded, color: accent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      ProductLabels.listings,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    _Chip(label: 'İçe aktar', accent: accent),
                  ],
                ),
                const SizedBox(height: 10),
                _ListingRow(accent: accent, title: '3+1 · Kadıköy', price: '₺12,4M'),
                _ListingRow(accent: accent, title: 'Villa · Bodrum', price: '₺28M'),
                _ListingRow(accent: accent, title: 'Ofis · Levent', price: '₺45K/ay'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OfficeMessagesPreview extends StatelessWidget {
  const _OfficeMessagesPreview({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MockStatusBar(accent: accent),
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: ext.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            border: Border.all(color: ext.success.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_done_rounded, color: ext.success, size: 18),
              const SizedBox(width: 8),
              Text(
                'Senkron aktif',
                style: TextStyle(
                  color: ext.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _MockPrimaryButton(label: 'Başla — rolünü seç', accent: accent),
        const SizedBox(height: 4),
        Text(
          'Yönetici veya Danışman olarak giriş',
          textAlign: TextAlign.center,
          style: TextStyle(color: ext.textTertiary, fontSize: 10),
        ),
      ],
    );
  }
}

// ——— Shared mock primitives ———

class _NavMock {
  const _NavMock(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _MockStatusBar extends StatelessWidget {
  const _MockStatusBar({required this.accent});
  final Color accent;

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
        Icon(Icons.signal_cellular_alt_rounded, size: 12, color: ext.textTertiary),
        const SizedBox(width: 4),
        Icon(Icons.wifi_rounded, size: 12, color: ext.textTertiary),
        const SizedBox(width: 4),
        Icon(Icons.battery_full_rounded, size: 14, color: accent),
      ],
    );
  }
}

class _MockPrimaryButton extends StatelessWidget {
  const _MockPrimaryButton({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppThemeExtension.of(context).onBrand,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MockMetricRow extends StatelessWidget {
  const _MockMetricRow({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: ext.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: 36,
          height: 6,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}

class _CallLogTile extends StatelessWidget {
  const _CallLogTile({
    required this.name,
    required this.meta,
    required this.accent,
    required this.icon,
  });

  final String name;
  final String meta;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ext.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: ext.border.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: accent.withValues(alpha: 0.15),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  meta,
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

class _MiniChartCard extends StatelessWidget {
  const _MiniChartCard({
    required this.title,
    required this.accent,
    required this.bars,
  });

  final String title;
  final Color accent;
  final List<double> bars;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      height: 72,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ext.card.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: ext.border.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final h in bars)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      height: 28 * h,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.35 + h * 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListingRow extends StatelessWidget {
  const _ListingRow({
    required this.accent,
    required this.title,
    required this.price,
  });

  final Color accent;
  final String title;
  final String price;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.home_rounded, size: 16, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: ext.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            price,
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 9,
          fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ext.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: ext.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ext.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
