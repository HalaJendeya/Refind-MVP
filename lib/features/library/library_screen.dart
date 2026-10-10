import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/memory_model.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/memory_card.dart';
import '../../shared/widgets/screen_header.dart';
import '../../shared/widgets/sheets_and_dialogs.dart';
import '../../shared/widgets/state_views.dart';
import '../memory/memory_controller.dart';
import '../save/widgets/add_content_sheet.dart';
import '../save/widgets/details_form.dart';
import 'library_controller.dart';

class LibraryScreen extends GetView<LibraryController> {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final memories = Get.find<MemoryController>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 12, 16),
            child: TabTitle(
              title: 'Library',
              trailing: Row(
                children: [
                  IconButton(
                    tooltip: 'Sort',
                    icon: const Icon(
                      Icons.swap_vert,
                      color: AppColors.textDark,
                    ),
                    onPressed: _showSortSheet,
                  ),
                  IconButton(
                    tooltip: 'Search',
                    icon: const Icon(Icons.search, color: AppColors.textDark),
                    onPressed: () => Get.toNamed(AppRoutes.search),
                  ),
                ],
              ),
            ),
          ),
          _typeChips(),
          const SizedBox(height: 12),
          Expanded(child: Obx(() => _body(memories))),
        ],
      ),
    );
  }

  Widget _typeChips() {
    return SizedBox(
      height: 44,
      child: Obx(() {
        final selectedType = controller.typeFilter.value;
        final filterCount = controller.activeFilterCount;

        return ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            AppChip(
              label: 'All Items',
              selected: selectedType.isEmpty,
              onTap: () => controller.typeFilter.value = '',
            ),
            const SizedBox(width: 8),
            for (final type in MemoryType.all) ...[
              AppChip(
                label: '${MemoryType.label(type)}s',
                selected: selectedType == type,
                onTap: () => controller.typeFilter.value = type,
              ),
              const SizedBox(width: 8),
            ],
            AppChip(
              label: filterCount > 0 ? 'Intent ($filterCount)' : 'Intent',
              selected: controller.intentFilter.value.isNotEmpty,
              trailingIcon: Icons.keyboard_arrow_down,
              onTap: _showIntentSheet,
            ),
          ],
        );
      }),
    );
  }

  Widget _body(MemoryController memories) {
    if (memories.isLoading.value) return const LoadingView();
    if (memories.errorMessage.value != null) {
      return ErrorState(
        message: memories.errorMessage.value!,
        onRetry: memories.retry,
      );
    }

    if (memories.active.isEmpty) {
      return EmptyState(
        icon: Icons.bookmark_border,
        title: 'Your Library is empty',
        message: 'Anything you save will show up here.',
        actionLabel: 'Save Something',
        onAction: showAddContentSheet,
      );
    }

    final list = controller.visibleMemories;
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'No matching items',
        message: 'Try removing a filter.',
        actionLabel: 'Clear Filters',
        onAction: controller.clearFilters,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final memory = list[index];
        return MemoryCard(
          memory: memory,
          onTap: () =>
              Get.toNamed(AppRoutes.memoryDetails, arguments: memory.id),
        );
      },
    );
  }

  void _showSortSheet() {
    const labels = {
      LibrarySort.newest: 'Newest first',
      LibrarySort.oldest: 'Oldest first',
      LibrarySort.title: 'Title (A-Z)',
    };

    showAppSheet(
      AppSheet(
        title: 'Sort by',
        child: Builder(
          builder: (sheetContext) => Obx(
            () => Column(
              children: [
                for (final option in LibrarySort.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      labels[option]!,
                      style: AppTheme.text(weight: FontWeight.w600),
                    ),
                    trailing: controller.sort.value == option
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      controller.sort.value = option;
                      closeSheet(sheetContext);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIntentSheet() {
    showAppSheet(
      AppSheet(
        title: 'Filter by intent',
        child: Builder(
          builder: (sheetContext) => Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final intent in memoryIntents)
                      AppChip(
                        label: intent,
                        selected: controller.intentFilter.value == intent,
                        onTap: () => controller.intentFilter.value =
                            controller.intentFilter.value == intent
                            ? ''
                            : intent,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Done',
                  onPressed: () => closeSheet(sheetContext),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
