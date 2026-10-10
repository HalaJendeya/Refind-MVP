import 'package:get/get.dart';

import '../../data/models/memory_model.dart';
import '../memory/memory_controller.dart';

enum LibrarySort { newest, oldest, title }

/// Filtering and sorting for the Library screen.
/// The data itself comes from MemoryController (which listens to Firestore).
class LibraryController extends GetxController {
  final MemoryController _memories = Get.find<MemoryController>();

  /// '' means "all types"; otherwise one of MemoryType.
  final RxString typeFilter = ''.obs;

  /// '' means "any intent"; otherwise Learn, Buy, Try ...
  final RxString intentFilter = ''.obs;

  final Rx<LibrarySort> sort = LibrarySort.newest.obs;

  /// Number of active filters (shown as a badge on the Filter button).
  int get activeFilterCount {
    var count = 0;
    if (typeFilter.value.isNotEmpty) count++;
    if (intentFilter.value.isNotEmpty) count++;
    return count;
  }

  /// The memories to display. Reading `.obs` values here makes any
  /// `Obx` that calls it rebuild when a filter or the data changes.
  List<Memory> get visibleMemories {
    var list = _memories.active.where((memory) {
      final typeOk =
          typeFilter.value.isEmpty || memory.type == typeFilter.value;
      final intentOk =
          intentFilter.value.isEmpty || memory.intent == intentFilter.value;
      return typeOk && intentOk;
    }).toList();

    switch (sort.value) {
      case LibrarySort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case LibrarySort.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case LibrarySort.title:
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
    }
    return list;
  }

  void clearFilters() {
    typeFilter.value = '';
    intentFilter.value = '';
  }
}
