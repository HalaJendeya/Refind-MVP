import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_helpers.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/memory_card.dart';
import '../../shared/widgets/screen_header.dart';
import '../../shared/widgets/state_views.dart';
import '../auth/auth_controller.dart';
import '../main/main_controller.dart';
import '../memory/memory_controller.dart';
import '../save/widgets/add_content_sheet.dart';
import '../save/widgets/quick_save_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final memories = Get.find<MemoryController>();
    final main = Get.find<MainController>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          Obx(
            () => TabTitle(
              title: 'Home',
              subtitle: 'What would you like to save today?',
              trailing: _Avatar(
                initials: initialsOf(auth.displayName, auth.email),
                onTap: () => main.changeTab(3),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SearchField(onTap: () => Get.toNamed(AppRoutes.search)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recently Saved',
                style: AppTheme.text(size: 20, weight: FontWeight.w700),
              ),
              TextLinkButton(
                label: 'View All',
                onPressed: () => main.changeTab(1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => _recentSection(memories)),
          const SizedBox(height: 28),
          _QuickSaveCard(onPressed: showQuickSaveSheet),
        ],
      ),
    );
  }

  Widget _recentSection(MemoryController memories) {
    if (memories.isLoading.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: LoadingView(),
      );
    }
    if (memories.errorMessage.value != null) {
      return ErrorState(
        message: memories.errorMessage.value!,
        onRetry: memories.retry,
      );
    }

    final recent = memories.active.take(3).toList();
    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: EmptyState(
          icon: Icons.bookmark_add_outlined,
          title: 'Nothing saved yet',
          message:
              'Save your first link, note, image or document and find it again here.',
          actionLabel: 'Save Something',
          onAction: showAddContentSheet,
        ),
      );
    }

    return Column(
      children: [
        for (final memory in recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MemoryCard(
              memory: memory,
              onTap: () =>
                  Get.toNamed(AppRoutes.memoryDetails, arguments: memory.id),
            ),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final VoidCallback onTap;

  const _Avatar({required this.initials, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: AppTheme.text(
            size: 18,
            weight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _QuickSaveCard extends StatelessWidget {
  final VoidCallback onPressed;

  const _QuickSaveCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.bookmark_border,
              color: AppColors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Save',
            style: AppTheme.text(size: 18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Paste a link or text and save it in one tap.',
            textAlign: TextAlign.center,
            style: AppTheme.text(size: 14, color: AppColors.textMedium),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Save to ReFind', onPressed: onPressed),
        ],
      ),
    );
  }
}
