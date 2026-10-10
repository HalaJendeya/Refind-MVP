import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/memory_model.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/memory_card.dart';
import '../../../shared/widgets/sheets_and_dialogs.dart';

/// "Saved to your Library" confirmation sheet.
void showSavedSheet({
  required Memory memory,
  required VoidCallback onViewLibrary,
  required VoidCallback onBackHome,
}) {
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
            child: const Icon(Icons.check, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Saved to your Library',
            style: AppTheme.text(size: 22, weight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.chipBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                MemoryThumb(memory: memory, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    memory.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.text(weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'View in Library', onPressed: onViewLibrary),
          const SizedBox(height: 12),
          SecondaryButton(label: 'Back to Home', onPressed: onBackHome),
        ],
      ),
    ),
  );
}
