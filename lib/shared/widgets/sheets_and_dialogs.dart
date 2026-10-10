import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'app_buttons.dart';

/// White rounded container with the small grab handle. Wrap sheet content in it.
class AppSheet extends StatelessWidget {
  final String? title;
  final Widget child;

  const AppSheet({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: 20),
              Text(
                title!,
                style: AppTheme.text(size: 22, weight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

/// Opens a bottom sheet with our rounded style.
Future<T?> showAppSheet<T>(Widget sheet) {
  return Get.bottomSheet<T>(
    Material(
      color: AppColors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: sheet,
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

/// Closes the sheet that [context] belongs to.
///
/// Why not `Get.back()`? In GetX 4.7.3 `Get.back()` only dismisses a visible
/// snackbar and returns, so the sheet would stay open while a message is on
/// screen. Popping through the sheet's own context always closes this sheet,
/// whether or not a snackbar is showing.
///
/// Pages are closed with `closePage()`, dialogs with `Navigator.pop(context)`.
void closeSheet(BuildContext context) {
  final route = ModalRoute.of(context);
  if (route == null) return;

  if (route.isCurrent) {
    Navigator.of(context).pop();
  } else {
    // Something else was opened on top; remove only this sheet.
    Navigator.of(context).removeRoute(route);
  }
}

/// One tappable row in a sheet menu (icon + label).
/// Tapping it closes the sheet first, then runs [onTap].
class SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const SheetOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          closeSheet(context);
          onTap();
        },
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color == AppColors.error
                      ? const Color(0xFFFFE4E8)
                      : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color == AppColors.error ? color : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: AppTheme.text(weight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks "Are you sure?" and returns true when the user confirms.
Future<bool> confirmDialog({
  required String title,
  required String message,
  required String confirmLabel,
  bool isDestructive = false,
}) async {
  final result = await Get.dialog<bool>(
    // Builder gives the buttons the dialog's own context, so they can close
    // exactly this dialog (Get.back would do nothing while a snackbar shows).
    Builder(
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: AppTheme.text(size: 20, weight: FontWeight.w700),
        ),
        content: Text(
          message,
          style: AppTheme.text(
            size: 14,
            color: AppColors.textMedium,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: AppTheme.text(
                weight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              confirmLabel,
              style: AppTheme.text(
                weight: FontWeight.w600,
                color: isDestructive ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

/// Simple "Cancel" bar used at the bottom of sheets.
class SheetCancelButton extends StatelessWidget {
  const SheetCancelButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TextButton(
        onPressed: () => closeSheet(context),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.chipBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text('Cancel', style: AppTheme.text(weight: FontWeight.w600)),
      ),
    );
  }
}

/// Convenience: a primary button used in sheets.
Widget sheetPrimary(
  String label,
  VoidCallback onTap, {
  bool isLoading = false,
}) {
  return PrimaryButton(label: label, onPressed: onTap, isLoading: isLoading);
}
