import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/sheets_and_dialogs.dart';

/// The "Add Content" sheet opened by the + button.
/// Links and notes work. Images and documents are shown (to match the design)
/// but only display a "coming soon" message for now.
void showAddContentSheet() {
  showAppSheet(
    AppSheet(
      title: 'Add Content',
      child: Column(
        children: [
          _screenOption(Icons.link, 'Add Link', AppRoutes.addLink),
          _comingSoonOption(
            icon: Icons.image_outlined,
            label: 'Add Image',
            message: 'Image uploads are coming soon',
          ),
          _comingSoonOption(
            icon: Icons.description_outlined,
            label: 'Add Document',
            message: 'Document uploads are coming soon',
          ),
          _screenOption(Icons.notes, 'Add Note', AppRoutes.addNote),
          const SizedBox(height: 4),
          const SheetCancelButton(),
        ],
      ),
    ),
  );
}

/// An option that opens a screen.
Widget _screenOption(IconData icon, String label, String route) {
  return SheetOption(
    icon: icon,
    label: label,
    // SheetOption closes the sheet first, then runs this.
    onTap: () => Get.toNamed(route),
  );
}

/// An option that only shows a friendly message. No picker, no upload.
Widget _comingSoonOption({
  required IconData icon,
  required String label,
  required String message,
}) {
  return SheetOption(
    icon: icon,
    label: label,
    onTap: () => _showComingSoonSheet(icon: icon, message: message),
  );
}

void _showComingSoonSheet({required IconData icon, required String message}) {
  showAppSheet(
    AppSheet(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.text(size: 22, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'For now, you can save links and notes. '
            'We are working on this and it will arrive in a future update.',
            textAlign: TextAlign.center,
            style: AppTheme.text(
              size: 14,
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (context) => PrimaryButton(
              label: 'Got it',
              onPressed: () => closeSheet(context),
            ),
          ),
        ],
      ),
    ),
  );
}
