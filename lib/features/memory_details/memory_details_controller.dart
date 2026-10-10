import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/routes/app_routes.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/models/memory_model.dart';
import '../../shared/widgets/sheets_and_dialogs.dart';
import '../memory/memory_controller.dart';

/// Logic for the Memory Details screen: which memory is open,
/// and what the buttons do (open, favorite, edit, archive, delete).
class MemoryDetailsController extends GetxController {
  final MemoryController _memories = Get.find<MemoryController>();

  /// The id was passed in `Get.toNamed(route, arguments: memory.id)`.
  late final String memoryId = Get.arguments as String;

  /// Always the latest version of the memory (null once it is deleted).
  Memory? get memory => _memories.byId(memoryId);

  Future<void> toggleFavorite() async {
    final current = memory;
    if (current != null) await _memories.toggleFavorite(current);
  }

  /// Opens the original link, or the uploaded image/document, in the browser.
  Future<void> openOriginal() async {
    final current = memory;
    if (current == null) return;

    final address = current.sourceUrl.isNotEmpty
        ? current.sourceUrl
        : current.fileUrl;
    final uri = Uri.tryParse(address);
    if (uri == null || address.isEmpty) {
      showError('There is nothing to open for this item.');
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) showError('Could not open this link.');
    } catch (_) {
      showError('Could not open this link.');
    }
  }

  void edit() => Get.toNamed(AppRoutes.editMemory, arguments: memoryId);

  Future<void> toggleArchive() async {
    final current = memory;
    if (current == null) return;
    await _memories.toggleArchive(current);
    Get.back();
  }

  Future<void> confirmAndDelete() async {
    final current = memory;
    if (current == null) return;

    final confirmed = await confirmDialog(
      title: 'Delete this item?',
      message: 'This permanently removes "${current.title}" from your Library.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;

    final deleted = await _memories.deleteMemory(current);
    if (deleted) Get.back(); // leave the details screen
  }
}
