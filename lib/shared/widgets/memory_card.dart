import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/models/memory_model.dart';
import 'app_chip.dart';

/// Icon shown for each kind of memory.
IconData iconForType(String type) {
  switch (type) {
    case MemoryType.link:
      return Icons.link;
    case MemoryType.image:
      return Icons.image_outlined;
    case MemoryType.document:
      return Icons.description_outlined;
    default:
      return Icons.notes;
  }
}

/// Square thumbnail: the real picture for images, otherwise a type icon.
class MemoryThumb extends StatelessWidget {
  final Memory memory;
  final double size;

  const MemoryThumb({super.key, required this.memory, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size > 80 ? 24 : 20);
    final hasPicture =
        memory.type == MemoryType.image && memory.fileUrl.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPicture
          ? Image.network(
              memory.fileUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _icon(),
            )
          : _icon(),
    );
  }

  Widget _icon() {
    return Icon(
      iconForType(memory.type),
      color: AppColors.textMuted,
      size: size * 0.4,
    );
  }
}

/// One row in a list of memories (Home, Library, Search).
/// It only receives the memory and a tap callback, so it is easy to reuse.
class MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;

  const MemoryCard({super.key, required this.memory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              MemoryThumb(memory: memory),
              const SizedBox(width: 16),
              Expanded(child: _texts()),
              if (memory.isFavorite)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.star, color: AppColors.primary, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _texts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          memory.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.text(weight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            TypeBadge(label: MemoryType.label(memory.type)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                memory.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.text(size: 14, color: AppColors.textMedium),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          timeAgo(memory.createdAt),
          style: AppTheme.text(size: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// Square tile used in the Favorites grid.
class MemoryGridTile extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  final VoidCallback onUnfavorite;

  const MemoryGridTile({
    super.key,
    required this.memory,
    required this.onTap,
    required this.onUnfavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, box) =>
                        MemoryThumb(memory: memory, size: box.maxWidth),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: onUnfavorite,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.star,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            memory.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.text(size: 14, weight: FontWeight.w600),
          ),
          Text(
            memory.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.text(size: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
