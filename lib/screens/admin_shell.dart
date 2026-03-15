import 'package:emlakmaster_mobile/features/manager_command_center/presentation/pages/command_center_page.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/pages/war_room_page.dart';
import 'package:emlakmaster_mobile/shared/widgets/sync_status_banner.dart';
import 'package:emlakmaster_mobile/screens/dashboard_screen.dart';
import 'package:emlakmaster_mobile/screens/placeholder_pages.dart';
import 'package:emlakmaster_mobile/screens/admin_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Yönetici paneli: yönetici ve operasyon için tam yetkili, dünya standartında tek ekran.
/// Sekmeler: Dashboard | War Room | Çağrı Merkezi | Ekonomi & Piyasa | Raporlar & Ekip | Ayarlar
class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const List<_AdminNavItem> _navItems = [
    _AdminNavItem(Icons.dashboard_rounded, 'Dashboard'),
    _AdminNavItem(Icons.military_tech_rounded, 'War Room'),
    _AdminNavItem(Icons.call_rounded, 'Çağrı Merkezi'),
    _AdminNavItem(Icons.trending_up_rounded, 'Ekonomi'),
    _AdminNavItem(Icons.analytics_rounded, 'Raporlar'),
    _AdminNavItem(Icons.settings_rounded, 'Ayarlar'),
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
                DashboardPage(),
                WarRoomPage(),
                CommandCenterPage(),
                AdminEconomyPage(),
                AdminReportsPage(),
                SettingsPlaceholderPage(),
              ],
            ),
          ),
        ],
      ),
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

class _AdminNavItem {
  final IconData icon;
  final String label;
  const _AdminNavItem(this.icon, this.label);
}
