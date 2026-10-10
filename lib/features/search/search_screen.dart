import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/memory_card.dart';
import '../../shared/widgets/state_views.dart';
import '../memory/memory_controller.dart';
import 'search_controller.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _textController = TextEditingController();
  final MemorySearchController _search = Get.find<MemorySearchController>();
  final MemoryController _memories = Get.find<MemoryController>();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 24, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                  ),
                  Expanded(
                    child: SearchField(
                      hint: 'Search your memories...',
                      controller: _textController,
                      onChanged: _search.updateQuery,
                      autofocus: true,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(child: Obx(_body)),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_memories.isLoading.value) return const LoadingView();
    if (_memories.errorMessage.value != null) {
      return ErrorState(
        message: _memories.errorMessage.value!,
        onRetry: _memories.retry,
      );
    }

    if (!_search.hasQuery) {
      return const EmptyState(
        icon: Icons.search,
        title: 'Search your memories',
        message:
            'Type a word from the title, note, link, file name, category or tags.',
      );
    }

    final results = _search.results;
    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No results',
        message:
            'Nothing matches "${_search.query.value.trim()}". Try a different word.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '${results.length} ${results.length == 1 ? 'result' : 'results'} for "${_search.query.value.trim()}"',
          style: AppTheme.text(weight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        for (final memory in results)
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
