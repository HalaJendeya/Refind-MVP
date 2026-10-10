import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../shared/widgets/memory_card.dart';
import '../../shared/widgets/screen_header.dart';
import '../../shared/widgets/state_views.dart';
import '../main/main_controller.dart';
import '../memory/memory_controller.dart';

/// Favorites are not a separate copy: they are the same memories with
/// `isFavorite == true`, so removing a favorite just flips that flag.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final memories = Get.find<MemoryController>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: TabTitle(title: 'Favorites'),
          ),
          Expanded(child: Obx(() => _body(memories))),
        ],
      ),
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

    final favorites = memories.favorites;
    if (favorites.isEmpty) {
      return EmptyState(
        icon: Icons.star_border,
        title: 'No favorites yet',
        message: 'Tap the star on any saved item to keep it close.',
        actionLabel: 'Browse Library',
        onAction: () => Get.find<MainController>().changeTab(1),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final memory = favorites[index];
        return MemoryGridTile(
          memory: memory,
          onTap: () =>
              Get.toNamed(AppRoutes.memoryDetails, arguments: memory.id),
          onUnfavorite: () => memories.toggleFavorite(memory),
        );
      },
    );
  }
}
