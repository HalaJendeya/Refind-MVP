import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_helpers.dart';
import '../../shared/widgets/screen_header.dart';

/// Settings. Only Change Password and Privacy Information do something;
/// Language and Theme are shown as in the design but are fixed for now.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenHeader(title: 'Settings'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _section('ACCOUNT'),
            _card([
              _Row(
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: () => Get.toNamed(AppRoutes.changePassword),
              ),
            ]),
            const SizedBox(height: 24),
            _section('PREFERENCES'),
            _card([
              _Row(
                icon: Icons.language,
                label: 'Language',
                value: 'English',
                onTap: () =>
                    showInfo('English is the only language in this version.'),
              ),
              const Divider(height: 1, color: AppColors.border),
              _Row(
                icon: Icons.palette_outlined,
                label: 'Theme',
                value: 'Light',
                onTap: () => showInfo(
                  'Only the light theme is available in this version.',
                ),
              ),
            ]),
            const SizedBox(height: 24),
            _section('PRIVACY'),
            _card([
              _Row(
                icon: Icons.shield_outlined,
                label: 'Privacy Information',
                onTap: () => Get.toNamed(AppRoutes.privacy),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: AppTheme.text(
          size: 12,
          weight: FontWeight.w700,
          color: AppColors.textMuted,
        ).copyWith(letterSpacing: 1),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textMuted),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: AppTheme.text(weight: FontWeight.w600)),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  value!,
                  style: AppTheme.text(size: 14, color: AppColors.textMedium),
                ),
              ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
