import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/utils/validators.dart';
import '../../data/models/memory_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/memory_service.dart';
import '../main/main_controller.dart';
import 'widgets/saved_sheet.dart';

/// Saves new memories (link, note, quick save).
/// Images and documents are planned for a later version.
///
/// Flow: screen validates the form -> calls a save method here ->
/// MemoryService writes to Firestore -> we show the "Saved" sheet.
/// The Library updates by itself because MemoryController listens to Firestore.
class SaveController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final MemoryService _memoryService = Get.find<MemoryService>();

  /// True while saving. Screens disable the Save button using this.
  final RxBool isSaving = false.obs;

  String? get _userId => _authService.currentUser?.uid;

  Future<void> saveLink({
    required String url,
    required String title,
    String note = '',
    String category = '',
    String intent = '',
    List<String> tags = const [],
  }) {
    return _save(
      title: title,
      type: MemoryType.link,
      sourceUrl: Validators.normalizeUrl(url),
      content: note,
      category: category,
      intent: intent,
      tags: tags,
    );
  }

  Future<void> saveNote({required String title, required String content}) {
    // A note without a title uses the first line of the text.
    final fallbackTitle = content.trim().split('\n').first;
    final finalTitle = title.trim().isEmpty
        ? _shorten(fallbackTitle)
        : title.trim();
    return _save(
      title: finalTitle,
      type: MemoryType.note,
      content: content.trim(),
    );
  }

  /// Quick Save: one box for either a link or plain text.
  Future<void> quickSave({required String text, String title = ''}) {
    final input = text.trim();
    if (Validators.isValidUrl(input) && !input.contains(' ')) {
      final url = Validators.normalizeUrl(input);
      final fallbackTitle = Uri.tryParse(url)?.host ?? url;
      return _save(
        title: title.trim().isEmpty ? fallbackTitle : title.trim(),
        type: MemoryType.link,
        sourceUrl: url,
      );
    }
    return saveNote(title: title, content: input);
  }

  /// The one place that really writes to Firestore.
  Future<void> _save({
    required String title,
    required String type,
    String content = '',
    String sourceUrl = '',
    String category = '',
    String intent = '',
    List<String> tags = const [],
  }) async {
    final userId = _userId;
    if (userId == null) {
      showError('Please log in to save.');
      return;
    }
    if (isSaving.value) return; // stops double taps from saving twice
    isSaving.value = true;

    try {
      final memory = await _memoryService.addMemory(
        userId: userId,
        title: title,
        type: type,
        content: content,
        sourceUrl: sourceUrl,
        category: category,
        intent: intent,
        tags: tags,
      );
      _showSuccess(memory);
    } catch (_) {
      showError('Could not save. Please check your connection and try again.');
    } finally {
      isSaving.value = false;
    }
  }

  void _showSuccess(Memory memory) {
    // Go back to the main screen, then show the "Saved" sheet on top of it.
    Get.until((route) => route.settings.name == AppRoutes.main);
    showSavedSheet(
      memory: memory,
      onViewLibrary: () {
        Get.back();
        Get.find<MainController>().changeTab(1);
      },
      onBackHome: () {
        Get.back();
        Get.find<MainController>().changeTab(0);
      },
    );
  }

  String _shorten(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return 'Untitled note';
    return clean.length <= 40 ? clean : '${clean.substring(0, 40)}...';
  }
}
