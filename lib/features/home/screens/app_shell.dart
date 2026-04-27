import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/vc_copy.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goToBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = VcCopy.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceParchment,
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.surfaceWarmSand)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                _NavItem(
                  label: copy.t('home'),
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  active: navigationShell.currentIndex == 0,
                  onTap: () => _goToBranch(0),
                ),
                _NavItem(
                  label: copy.t('requests'),
                  icon: Icons.description_outlined,
                  activeIcon: Icons.description_rounded,
                  active: navigationShell.currentIndex == 1,
                  onTap: () => _goToBranch(1),
                ),
                _ChatbotNavItem(onTap: () => context.push('/chatbot')),
                _NavItem(
                  label: copy.t('notices'),
                  icon: Icons.campaign_outlined,
                  activeIcon: Icons.campaign_rounded,
                  active: navigationShell.currentIndex == 3,
                  onTap: () => _goToBranch(3),
                ),
                _NavItem(
                  label: copy.t('community'),
                  icon: Icons.people_outline,
                  activeIcon: Icons.people_rounded,
                  active: navigationShell.currentIndex == 4,
                  onTap: () => _goToBranch(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatbotNavItem extends StatelessWidget {
  const _ChatbotNavItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: 'Chatbot',
        child: InkWell(
          onTap: onTap,
          child: Transform.translate(
            offset: const Offset(0, -12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.shadowMedium,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chatbot',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.tab.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  active ? activeIcon : icon,
                  color: active ? AppColors.brandGreen : AppColors.inkLight,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (active ? AppTextStyles.tab : AppTextStyles.tabInactive)
                          .copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
