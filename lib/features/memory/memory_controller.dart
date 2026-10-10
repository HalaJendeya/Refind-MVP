import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../core/utils/ui_helpers.dart';
import '../../data/models/memory_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/memory_service.dart';

/// Holds the signed-in user's memories in one place.
///
/// It listens to Firestore (a "stream"), so when a memory is added, edited or
/// deleted, `memories` updates by itself and every screen using it rebuilds.
/// Home, Library, Favorites and Search all read from this list.
class MemoryController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final MemoryService _memoryService = Get.find<MemoryService>();

  final RxList<Memory> memories = <Memory>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<Memory>>? _memorySub;

  /// The id of the user whose memories we are showing.
  String? get userId => _authService.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    // Start (or stop) listening whenever someone logs in or out.
    _authSub = _authService.authChanges.listen(_onUserChanged);
    _onUserChanged(_authService.currentUser);
  }

  void _onUserChanged(User? user) {
    _memorySub?.cancel();
    memories.clear();
    errorMessage.value = null;

    if (user == null) {
      isLoading.value = false;
      return;
    }
    _listenToMemories(user.uid);
  }

  void _listenToMemories(String uid) {
    isLoading.value = true;
    _memorySub = _memoryService
        .watchMemories(uid)
        .listen(
          (list) {
            memories.assignAll(list);
            errorMessage.value = null;
            isLoading.value = false;
          },
          onError: (Object error) {
            errorMessage.value =
                'We could not load your memories. Check your connection and try again.';
            isLoading.value = false;
          },
        );
  }

  /// Called by the "Try Again" buttons.
  void retry() {
    final uid = userId;
    if (uid == null) return;
    _memorySub?.cancel();
    _listenToMemories(uid);
  }

  /// Everything that is not archived (what Library and Home show).
  List<Memory> get active => memories.where((m) => !m.isArchived).toList();

  List<Memory> get favorites => active.where((m) => m.isFavorite).toList();

  List<Memory> get archived => memories.where((m) => m.isArchived).toList();

  Memory? byId(String id) {
    for (final memory in memories) {
      if (memory.id == id) return memory;
    }
    return null;
  }

  // ----------------------------------------------------- changing a memory
  // The Firestore stream above refreshes the screens after each change,
  // so these methods only need to write and report errors.

  Future<void> toggleFavorite(Memory memory) async {
    try {
      await _memoryService.setFavorite(
        memory.userId,
        memory.id,
        !memory.isFavorite,
      );
    } catch (_) {
      showError('Could not update favorites. Please try again.');
    }
  }

  Future<void> toggleArchive(Memory memory) async {
    try {
      await _memoryService.setArchived(
        memory.userId,
        memory.id,
        !memory.isArchived,
      );
      showSuccess(
        memory.isArchived ? 'Moved back to your Library' : 'Archived',
      );
    } catch (_) {
      showError('Could not update this item. Please try again.');
    }
  }

  /// Returns true if the memory was deleted.
  Future<bool> deleteMemory(Memory memory) async {
    try {
      await _memoryService.deleteMemory(memory);
      showSuccess('Deleted');
      return true;
    } catch (_) {
      showError('Could not delete this item. Please try again.');
      return false;
    }
  }

  /// Returns true if the changes were saved.
  Future<bool> updateMemory(
    Memory memory, {
    required String title,
    required String content,
    required String category,
    required String intent,
    required List<String> tags,
  }) async {
    try {
      await _memoryService.updateMemory(
        memory.userId,
        memory.id,
        title: title,
        content: content,
        category: category,
        intent: intent,
        tags: tags,
      );
      showSuccess('Changes saved');
      return true;
    } catch (_) {
      showError('Could not save your changes. Please try again.');
      return false;
    }
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _memorySub?.cancel();
    super.onClose();
  }
}
