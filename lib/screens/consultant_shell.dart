import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/pages/customer_list_page.dart';
import 'package:emlakmaster_mobile/shared/widgets/sync_status_banner.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard_page.dart';
import 'package:emlakmaster_mobile/screens/consultant_resurrection_page.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/pages/tasks_page.dart';
import 'package:emlakmaster_mobile/screens/listings_screen.dart';
import 'package:emlakmaster_mobile/screens/placeholder_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Danışman paneli: günlük iş akışına odaklı, sade, güçlü.
/// Sekmeler: Özetim | Müşterilerim | İlanlar | Takip | Ayarlar + Magic Call FAB
class ConsultantShellPage extends StatefulWidget {
  const ConsultantShellPage({super.key});

  @override
  State<ConsultantShellPage> createState() => _ConsultantShellPageState();
}

class _ConsultantShellPageState extends State<ConsultantShellPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const List<_ConsultantNavItem> _navItems = [
    _ConsultantNavItem(Icons.dashboard_rounded, 'Özetim'),
    _ConsultantNavItem(Icons.people_rounded, 'Müşterilerim'),
    _ConsultantNavItem(Icons.home_work_rounded, 'İlanlar'),
    _ConsultantNavItem(Icons.replay_rounded, 'Takip'),
    _ConsultantNavItem(Icons.task_alt_rounded, 'Görevler'),
    _ConsultantNavItem(Icons.settings_rounded, 'Ayarlar'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Column(
        children: [
          const SyncStatusBanner(compact: true),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentIndex = i),
              children: const [
                ConsultantDashboardPage(),
                CustomerListPage(),
                ListingsPage(),
                ConsultantResurrectionPage(),
                TasksPage(),
                SettingsPlaceholderPage(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _currentIndex == 0 ? const _MagicCallFab() : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 22,
                            color: isSelected
                                ? const Color(0xFF00FF41)
                                : Colors.white54,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF00FF41)
                                  : Colors.white54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
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
    );
  }
}

class _ConsultantNavItem {
  final IconData icon;
  final String label;
  const _ConsultantNavItem(this.icon, this.label);
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
            color: const Color(0xFF00FF41),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FF41).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_in_talk_rounded, color: Colors.black, size: 22),
              SizedBox(width: 10),
              Text(
                'Magic Call & AI Wizard',
                style: TextStyle(
                  color: Colors.black,
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
