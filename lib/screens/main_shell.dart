import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/pages/customer_list_page.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/screens/dashboard_screen.dart';
import 'package:emlakmaster_mobile/screens/listings_screen.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key});

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  /// Kullanıcı dostu menü: Ana Sayfa, İlanlar, Müşteriler, Profil (en beğenilen sıra).
  static const List<_NavItem> _navItems = [
    _NavItem(Icons.home_rounded, 'Ana Sayfa'),
    _NavItem(Icons.home_work_rounded, 'İlanlar'),
    _NavItem(Icons.people_rounded, 'Müşteriler'),
    _NavItem(Icons.person_rounded, 'Profil'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: DesignTokens.durationNormal,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = AppThemeExtension.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = ext.surface;
    final borderColor = ext.border;
    final navInactiveColor = ext.foregroundMuted;
    final brand = ext.brandPrimary;
    final flags = ref.watch(featureFlagsProvider).valueOrNull;
    final voiceCrmEnabled = flags?[AppConstants.keyFeatureVoiceCrm] ?? true;

    return Scaffold(
      backgroundColor: ext.background,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          DashboardPage(),
          ListingsPage(),
          CustomerListPage(),
          SettingsPage(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _currentIndex == 0 && voiceCrmEnabled ? const _MagicCallFab() : null,
      bottomNavigationBar: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(top: BorderSide(color: borderColor.withValues(alpha: 0.65))),
            boxShadow: [
              BoxShadow(
                color: ext.shadowColor.withValues(alpha: isDark ? 0.55 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 4),
            child: SizedBox(
              height: 72,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space2, vertical: DesignTokens.space2),
                child: Row(
                  children: List.generate(_navItems.length, (i) {
                    final item = _navItems[i];
                    final isSelected = _currentIndex == i;
                    return Expanded(
                      child: _PremiumNavItem(
                        icon: item.icon,
                        label: item.label,
                        isSelected: isSelected,
                        brand: brand,
                        activeColor: brand,
                        inactiveColor: navInactiveColor,
                        onTap: () => _onNavTap(i),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumNavItem extends StatelessWidget {
  const _PremiumNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.brand,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color brand;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        splashColor: brand.withValues(alpha: 0.12),
        highlightColor: brand.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: DesignTokens.durationNormal,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.space2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            color: isSelected ? brand.withValues(alpha: 0.14) : Colors.transparent,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: brand.withValues(alpha: 0.42),
                      blurRadius: 14,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: DesignTokens.durationFast,
                curve: Curves.easeOutBack,
                child: Icon(
                  icon,
                  size: 26,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.2,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _MagicCallFab extends StatelessWidget {
  const _MagicCallFab();

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 72),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(AppRouter.routeCall);
        },
        child: Container(
          width: 220,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: ext.brandPrimary,
            boxShadow: DesignTokens.neomorphicGlowAntiqueGold(intensity: 0.25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_in_talk_rounded, color: ext.onBrand, size: 22),
              const SizedBox(width: 10),
              Text(
                'Magic Call & AI Wizard',
                style: TextStyle(
                  color: ext.onBrand,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
