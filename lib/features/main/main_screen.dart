import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../favorites/favorites_screen.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../profile/profile_screen.dart';
import '../save/widgets/add_content_sheet.dart';
import 'main_controller.dart';

/// The app after login: four tabs and a big "+" button in the middle.
class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.tabIndex.value;

      return Scaffold(
        // IndexedStack keeps every tab alive, so scroll positions are kept.
        body: IndexedStack(
          index: index,
          children: const [
            HomeScreen(),
            LibraryScreen(),
            FavoritesScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: index,
          onTabSelected: controller.changeTab,
          onAddPressed: showAddContentSheet,
        ),
      );
    });
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;

  const _BottomNav({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _item(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _item(1, Icons.bookmark_border, Icons.bookmark, 'Library'),
              _addButton(),
              _item(2, Icons.star_border, Icons.star, 'Favorites'),
              _item(3, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon, IconData activeIcon, String label) {
    final selected = currentIndex == index;
    final color = selected ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.text(
                size: 10,
                weight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addButton() {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: onAddPressed,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: AppColors.white, size: 32),
          ),
        ),
      ),
    );
  }
}
