import 'package:get/get.dart';

import '../../data/models/memory_model.dart';
import '../memory/memory_controller.dart';

/// Basic text search. Firestore has no built-in full-text search, so we
/// match the typed words against the memories we already loaded.
/// (It is plain keyword matching, not AI or semantic search.)
///
/// Named MemorySearchController because Flutter already has a class
/// called SearchController.
class MemorySearchController extends GetxController {
  final MemoryController _memories = Get.find<MemoryController>();

  final RxString query = ''.obs;

  bool get hasQuery => query.value.trim().isNotEmpty;

  /// Memories whose title, notes, link, file name, category, intent or tags
  /// contain the typed text. Empty when nothing has been typed.
  List<Memory> get results {
    if (!hasQuery) return [];
    return _memories.active
        .where((memory) => memory.matches(query.value))
        .toList();
  }

  void updateQuery(String text) => query.value = text;
}
