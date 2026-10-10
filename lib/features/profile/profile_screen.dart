import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_helpers.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/sheets_and_dialogs.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          Center(
            child: Text(
              'Profile',
              style: AppTheme.text(size: 18, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 24),
          Obx(() => _userInfo(auth)),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Edit Profile',
            onPressed: () => Get.toNamed(AppRoutes.editProfile),
          ),
          const SizedBox(height: 20),
          _MenuRow(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => Get.toNamed(AppRoutes.settings),
          ),
          _MenuRow(
            icon: Icons.archive_outlined,
            label: 'Archived Items',
            onTap: () => Get.toNamed(AppRoutes.archived),
          ),
          _MenuRow(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () => showInfo(
              'Help & Support is not available in this version yet.',
            ),
          ),
          _MenuRow(
            icon: Icons.logout,
            label: 'Log Out',
            color: AppColors.error,
            onTap: () => _confirmLogout(auth),
          ),
        ],
      ),
    );
  }

  Widget _userInfo(AuthController auth) {
    final name = auth.displayName.isEmpty ? 'ReFind user' : auth.displayName;

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initialsOf(auth.displayName, auth.email),
            style: AppTheme.text(
              size: 36,
              weight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(name, style: AppTheme.text(size: 24, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          auth.email,
          style: AppTheme.text(size: 14, color: AppColors.textMedium),
        ),
        const SizedBox(height: 4),
        Text(
          'Your personal ReFind account',
          style: AppTheme.text(size: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(AuthController auth) async {
    final confirmed = await confirmDialog(
      title: 'Log out?',
      message: 'You will need to log in again to see your memories.',
      confirmLabel: 'Log Out',
      isDestructive: true,
    );
    if (confirmed) await auth.logout();
  }
}

/// One row of the profile / settings menu.
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color == AppColors.error ? color : AppColors.textMuted,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: AppTheme.text(weight: FontWeight.w600, color: color),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: color == AppColors.error ? color : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
