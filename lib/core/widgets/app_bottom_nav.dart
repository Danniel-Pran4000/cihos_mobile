import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../theme/app_colors.dart';

/// The five-tab navigation bar with Beranda (Home) in the center,
/// where the selected tab has a circle surrounding its icon.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current});

  final AppTab current;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.navBar,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (final tab in AppTab.values)
                Expanded(
                  child: _NavItem(
                    tab: tab,
                    isActive: tab == current,
                    onTap: () {
                      if (tab != current) context.go(tab.route);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AppTab {
  appointments(
    label: 'Jadwal',
    outlineIcon: Icons.calendar_month_outlined,
    fillIcon: Icons.calendar_month,
    route: AppRoutes.appointments,
  ),
  health(
    label: 'Sehat-mu',
    outlineIcon: Icons.favorite_outline,
    fillIcon: Icons.favorite,
    route: AppRoutes.health,
  ),
  home(
    label: 'Beranda',
    outlineIcon: Icons.home_outlined,
    fillIcon: Icons.home,
    route: AppRoutes.home,
  ),
  history(
    label: 'Riwayat',
    outlineIcon: Icons.history_outlined,
    fillIcon: Icons.history,
    route: AppRoutes.history,
  ),
  profile(
    label: 'Profil',
    outlineIcon: Icons.person_outline,
    fillIcon: Icons.person,
    route: AppRoutes.profile,
  );

  const AppTab({
    required this.label,
    required this.outlineIcon,
    required this.fillIcon,
    required this.route,
  });

  final String label;
  final IconData outlineIcon;
  final IconData fillIcon;
  final String route;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final AppTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular container that surrounds the active icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.accentSoft : Colors.transparent,
            ),
            child: Center(
              child: Icon(
                isActive ? tab.fillIcon : tab.outlineIcon,
                size: isActive ? 20 : 22,
                color: isActive
                    ? AppColors.white
                    : AppColors.accentSoft.withValues(alpha: 0.65),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tab.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive
                  ? AppColors.accentSoft
                  : AppColors.accentSoft.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
