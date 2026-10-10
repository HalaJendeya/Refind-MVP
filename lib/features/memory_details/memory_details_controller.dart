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

  /// True while a delete is running. The screen shows "Deleting..." instead
  /// of the memory (which disappears from the list as soon as it is deleted).
  final RxBool isDeleting = false.obs;

  /// True while an archive is running. Stops a second tap.
  final RxBool isArchiving = false.obs;

  // True while the "Are you sure?" dialog is open (stops a second dialog).
  bool _isAskingToDelete = false;

  /// Always the latest version of the memory (null once it is deleted).
  Memory? get memory => _memories.byId(memoryId);

  /// The screen must not be left (system Back) while we are still working,
  /// otherwise we would close the WRONG page when the work finishes.
  bool get isBusy => isDeleting.value || isArchiving.value;

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

  /// Archives the memory (or moves it back to the Library).
  /// On success we go back to the previous screen and show a message.
  /// On failure we stay here (the error message was already shown).
  Future<void> toggleArchive() async {
    final current = memory;
    if (current == null || isBusy) return;

    isArchiving.value = true;
    var worked = false;
    try {
      worked = await _memories.toggleArchive(current);
    } finally {
      isArchiving.value = false;
    }
    if (!worked) return;

    closePage();
    showSuccess(current.isArchived ? 'Moved back to your Library' : 'Archived');
  }

  /// Asks for confirmation, deletes, then goes back and shows a message.
  /// While deleting the screen shows "Deleting...". If it fails, the screen
  /// shows the memory again and an error message.
  Future<void> confirmAndDelete() async {
    final current = memory;
    if (current == null || isBusy || _isAskingToDelete) return;

    _isAskingToDelete = true;
    bool confirmed;
    try {
      confirmed = await confirmDialog(
        title: 'Delete this item?',
        message:
            'This permanently removes "${current.title}" from your Library.',
        confirmLabel: 'Delete',
        isDestructive: true,
      );
    } finally {
      _isAskingToDelete = false;
    }
    if (!confirmed) return;

    isDeleting.value = true;
    final deleted = await _memories.deleteMemory(current);
    if (!deleted) {
      isDeleting.value = false; // show the memory again; error already shown
      return;
    }

    // Leave isDeleting on: the screen keeps showing "Deleting..." until it closes.
    closePage();
    showSuccess('Deleted');
  }
}
