import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
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
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
    final surfaceColor = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final borderColor = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final navInactiveColor = isDark ? DesignTokens.textTertiaryDark : DesignTokens.textTertiaryLight;
    final flags = ref.watch(featureFlagsProvider).valueOrNull;
    final voiceCrmEnabled = flags?[AppConstants.keyFeatureVoiceCrm] ?? true;
    return Scaffold(
      backgroundColor: bgColor,
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
            border: Border(top: BorderSide(color: borderColor)),
            boxShadow: isDark ? DesignTokens.neomorphicEmbossDark : null,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_navItems.length, (i) {
                  final item = _navItems[i];
                  final isSelected = _currentIndex == i;
                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onNavTap(i),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                size: 24,
                                color: isSelected
                                    ? DesignTokens.antiqueGold
                                    : navInactiveColor,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected
                                      ? DesignTokens.antiqueGold
                                      : navInactiveColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 72),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRouter.routeCall);
        },
        child: Container(
          width: 220,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: DesignTokens.antiqueGold,
            boxShadow: DesignTokens.neomorphicGlowAntiqueGold(intensity: 0.25),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_in_talk_rounded, color: DesignTokens.inputTextOnGold, size: 22),
              SizedBox(width: 10),
              Text(
                'Magic Call & AI Wizard',
                style: TextStyle(
                  color: DesignTokens.inputTextOnGold,
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
