import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../shared/widgets/memory_card.dart';
import '../../shared/widgets/screen_header.dart';
import '../../shared/widgets/state_views.dart';
import '../memory/memory_controller.dart';

/// Memories the user archived. Open one to move it back to the Library.
class ArchivedScreen extends StatelessWidget {
  const ArchivedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final memories = Get.find<MemoryController>();

    return Scaffold(
      appBar: const ScreenHeader(title: 'Archived Items'),
      body: SafeArea(
        child: Obx(() {
          if (memories.isLoading.value) return const LoadingView();
          if (memories.errorMessage.value != null) {
            return ErrorState(
              message: memories.errorMessage.value!,
              onRetry: memories.retry,
            );
          }

          final archived = memories.archived;
          if (archived.isEmpty) {
            return const EmptyState(
              icon: Icons.archive_outlined,
              title: 'Nothing archived',
              message:
                  'Archive an item from its options menu to hide it from your Library.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: archived.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final memory = archived[index];
              return MemoryCard(
                memory: memory,
                onTap: () =>
                    Get.toNamed(AppRoutes.memoryDetails, arguments: memory.id),
              );
            },
          );
        }),
      ),
    );
  }
}
