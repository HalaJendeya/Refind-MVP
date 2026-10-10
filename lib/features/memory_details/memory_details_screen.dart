import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/models/memory_model.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/memory_card.dart';
import '../../shared/widgets/sheets_and_dialogs.dart';
import '../../shared/widgets/state_views.dart';
import 'memory_details_controller.dart';

class MemoryDetailsScreen extends GetView<MemoryDetailsController> {
  const MemoryDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return PopScope(
        // Block system Back while deleting/archiving. Otherwise the screen
        // that finishes the work could close the wrong page.
        canPop: !controller.isBusy,
        child: Scaffold(body: _body()),
      );
    });
  }

  Widget _body() {
    // A deleted memory disappears from the list immediately, so check the
    // "deleting" flag first and show progress instead of an empty screen.
    if (controller.isDeleting.value) return const _DeletingView();

    final memory = controller.memory;
    if (memory == null) return const _NotAvailableView();

    return Stack(
      children: [
        _content(memory),
        if (controller.isArchiving.value)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.primaryLight,
            ),
          ),
      ],
    );
  }

  Widget _content(Memory memory) {
    final canOpen = memory.sourceUrl.isNotEmpty || memory.fileUrl.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _header(memory),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _chips(memory),
                    const SizedBox(height: 16),
                    Text(
                      memory.title,
                      style: AppTheme.text(
                        size: 28,
                        weight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _metaLine(memory),
                      style: AppTheme.text(
                        size: 14,
                        color: AppColors.textMedium,
                      ),
                    ),
                    if (memory.sourceUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _linkRow(memory.sourceUrl),
                    ],
                    if (memory.type == MemoryType.document &&
                        memory.fileName.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        memory.fileName,
                        style: AppTheme.text(size: 14, weight: FontWeight.w600),
                      ),
                    ],
                    if (memory.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _contentSection(memory),
                    ],
                    if (memory.tags.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _tags(memory.tags),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (canOpen) _openButton(memory),
      ],
    );
  }

  Widget _header(Memory memory) {
    final isImage =
        memory.type == MemoryType.image && memory.fileUrl.isNotEmpty;

    return Stack(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          color: AppColors.primaryLight,
          child: isImage
              ? Image.network(
                  memory.fileUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _headerIcon(memory),
                )
              : _headerIcon(memory),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                AppIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Back',
                  onPressed: closePage,
                ),
                const Spacer(),
                AppIconButton(
                  icon: memory.isFavorite ? Icons.star : Icons.star_border,
                  color: AppColors.primary,
                  tooltip: memory.isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: controller.toggleFavorite,
                ),
                const SizedBox(width: 8),
                AppIconButton(
                  icon: Icons.more_vert,
                  tooltip: 'More options',
                  onPressed: () => _showOptions(memory),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerIcon(Memory memory) {
    return Center(
      child: Icon(iconForType(memory.type), size: 64, color: AppColors.primary),
    );
  }

  Widget _chips(Memory memory) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (memory.intent.isNotEmpty) _pill(memory.intent, filled: true),
        if (memory.category.isNotEmpty) _pill(memory.category, filled: false),
      ],
    );
  }

  Widget _pill(String label, {required bool filled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: filled ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTheme.text(
          size: 14,
          weight: FontWeight.w600,
          color: filled ? AppColors.white : AppColors.textMedium,
        ),
      ),
    );
  }

  String _metaLine(Memory memory) {
    final saved = DateFormat('d MMM yyyy').format(memory.createdAt);
    return '${memory.subtitle} • ${MemoryType.label(memory.type)} • Saved $saved';
  }

  Widget _linkRow(String url) {
    return GestureDetector(
      onTap: controller.openOriginal,
      child: Row(
        children: [
          const Icon(Icons.link, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              url,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.text(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentSection(Memory memory) {
    // For notes the text IS the memory. For other types it is "why I saved this".
    final heading = memory.type == MemoryType.note
        ? 'NOTE'
        : 'WHY YOU SAVED THIS';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: AppTheme.text(
            size: 13,
            weight: FontWeight.w700,
            color: AppColors.textMedium,
          ).copyWith(letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: SelectableText(
            memory.content,
            style: AppTheme.text(color: AppColors.textMedium, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _tags(List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TAGS',
          style: AppTheme.text(
            size: 13,
            weight: FontWeight.w700,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in tags)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#$tag',
                  style: AppTheme.text(size: 14, color: AppColors.textMedium),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _openButton(Memory memory) {
    final isLink = memory.sourceUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          label: isLink ? 'Open Original' : 'Open File',
          icon: Icons.open_in_new,
          onPressed: controller.openOriginal,
        ),
      ),
    );
  }

  void _showOptions(Memory memory) {
    showAppSheet(
      AppSheet(
        title: 'Options',
        child: Column(
          children: [
            SheetOption(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: controller.edit,
            ),
            SheetOption(
              icon: memory.isArchived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
              label: memory.isArchived ? 'Move back to Library' : 'Archive',
              onTap: controller.toggleArchive,
            ),
            SheetOption(
              icon: Icons.delete_outline,
              label: 'Delete',
              color: AppColors.error,
              onTap: controller.confirmAndDelete,
            ),
            const SizedBox(height: 4),
            const SheetCancelButton(),
          ],
        ),
      ),
    );
  }
}

/// Shown while a delete is running.
class _DeletingView extends StatelessWidget {
  const _DeletingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 20),
          Text('Deleting...', style: AppTheme.text(weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Shown if the memory no longer exists (for example it was deleted on
/// another device) so the user is never left on an empty screen.
class _NotAvailableView extends StatelessWidget {
  const _NotAvailableView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppIconButton(
                icon: Icons.arrow_back,
                tooltip: 'Back',
                onPressed: closePage,
              ),
            ),
          ),
          const Expanded(
            child: EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'This item is no longer available',
              message: 'It may have been deleted.',
            ),
          ),
        ],
      ),
    );
  }
}
