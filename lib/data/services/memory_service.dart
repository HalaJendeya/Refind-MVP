import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/utils/file_types.dart';
import '../models/memory_model.dart';

/// All Firestore and Storage work for memories lives here.
///
/// Data layout:  users/{userId}/memories/{memoryId}
/// Every method takes a userId, so one user can never touch another
/// user's memories through this class. (Security rules enforce it on the server too.)
class MemoryService {
  final FirebaseFirestore _db;
  final FirebaseStorage? _injectedStorage;

  MemoryService({FirebaseFirestore? db, FirebaseStorage? storage})
    : _db = db ?? FirebaseFirestore.instance,
      _injectedStorage = storage;

  // Created lazily so tests that never upload do not need Firebase Storage.
  FirebaseStorage get _storageInstance =>
      _injectedStorage ?? FirebaseStorage.instance;

  /// Firestore saves a change on the phone first and syncs it when online.
  /// While offline the Future would wait for the server forever, so we stop
  /// waiting after a few seconds. The change stays queued and syncs later,
  /// and the live list already shows it.
  Future<void> _writeOrQueue(Future<void> write) async {
    try {
      await write.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Queued by Firestore; nothing else to do.
    }
  }

  CollectionReference<Map<String, dynamic>> _memories(String userId) {
    return _db.collection('users').doc(userId).collection('memories');
  }

  /// Live list of the user's memories, newest first.
  Stream<List<Memory>> watchMemories(String userId) {
    return _memories(
      userId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Memory.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Saves a new memory and returns it with its generated id.
  Future<Memory> addMemory({
    required String userId,
    required String title,
    required String type,
    String content = '',
    String sourceUrl = '',
    String fileUrl = '',
    String fileName = '',
    String category = '',
    String intent = '',
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final doc = _memories(userId).doc();
    final memory = Memory(
      id: doc.id,
      userId: userId,
      title: title,
      type: type,
      content: content,
      sourceUrl: sourceUrl,
      fileUrl: fileUrl,
      fileName: fileName,
      category: category,
      intent: intent,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );
    await _writeOrQueue(doc.set(memory.toMap()));
    return memory;
  }

  /// Updates only the fields the user can edit. Does not create a new document.
  Future<void> updateMemory(
    String userId,
    String memoryId, {
    required String title,
    required String content,
    required String category,
    required String intent,
    required List<String> tags,
  }) {
    return _writeOrQueue(
      _memories(userId).doc(memoryId).update({
        'title': title,
        'content': content,
        'category': category,
        'intent': intent,
        'tags': tags,
        'updatedAt': Timestamp.now(),
      }),
    );
  }

  Future<void> setFavorite(String userId, String memoryId, bool value) {
    return _writeOrQueue(
      _memories(userId).doc(memoryId).update({
        'isFavorite': value,
        'updatedAt': Timestamp.now(),
      }),
    );
  }

  Future<void> setArchived(String userId, String memoryId, bool value) {
    return _writeOrQueue(
      _memories(userId).doc(memoryId).update({
        'isArchived': value,
        'updatedAt': Timestamp.now(),
      }),
    );
  }

  /// Deletes the document and, for images/documents, the uploaded file too.
  Future<void> deleteMemory(Memory memory) async {
    await _writeOrQueue(_memories(memory.userId).doc(memory.id).delete());
    if (memory.fileUrl.isNotEmpty) {
      try {
        await _storageInstance.refFromURL(memory.fileUrl).delete();
      } catch (_) {
        // The memory is already gone. A leftover file is not worth an error.
      }
    }
  }

  /// Uploads a local file to Firebase Storage and returns its download URL.
  Future<String> uploadFile(
    String userId,
    File file,
    String fileName, {
    required bool isImage,
  }) async {
    // storage.rules only accepts known file types, so we always say which
    // type we are sending instead of hoping Firebase guesses correctly.
    final contentType = FileTypes.contentTypeFor(fileName, isImage: isImage);
    if (contentType == null) {
      throw ArgumentError('This file type is not supported: $fileName');
    }

    final path =
        'users/$userId/memories/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storageInstance.ref(path);
    // Uploads need a real connection, so unlike Firestore we report a timeout.
    await ref
        .putFile(file, SettableMetadata(contentType: contentType))
        .timeout(const Duration(seconds: 90));
    return ref.getDownloadURL();
  }
}
