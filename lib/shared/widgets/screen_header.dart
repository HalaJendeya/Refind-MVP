import 'package:flutter/material.dart';

import '../../core/utils/ui_helpers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Header for sub screens: back arrow + title. Use it as `Scaffold.appBar`.
class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData backIcon;
  final List<Widget> actions;
  final VoidCallback? onBack;

  const ScreenHeader({
    super.key,
    required this.title,
    this.backIcon = Icons.arrow_back,
    this.actions = const [],
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: Icon(backIcon, color: AppColors.textDark),
        onPressed: onBack ?? closePage,
      ),
      title: Text(
        title,
        style: AppTheme.text(size: 18, weight: FontWeight.w700),
      ),
      actions: actions,
    );
  }
}

/// Big page title used at the top of main tabs ("Library", "Favorites" ...).
class TabTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const TabTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.text(
                  size: 30,
                  weight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle!,
                    style: AppTheme.text(size: 14, color: AppColors.textMedium),
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
