import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refind/data/models/memory_model.dart';
import 'package:refind/data/services/memory_service.dart';

/// These tests run MemoryService against an in-memory fake Firestore.
/// They check our own logic (paths, fields, per-user separation).
/// They do NOT test Firebase security rules - those only run on Firebase.
void main() {
  late FakeFirebaseFirestore db;
  late MemoryService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = MemoryService(db: db);
  });

  Future<Memory> addNote(String userId, String title) {
    return service.addMemory(
      userId: userId,
      title: title,
      type: MemoryType.note,
      content: 'body of $title',
    );
  }

  test('addMemory writes to users/{uid}/memories', () async {
    final memory = await addNote('alice', 'First');

    final doc = await db
        .collection('users')
        .doc('alice')
        .collection('memories')
        .doc(memory.id)
        .get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['title'], 'First');
    expect(doc.data()!['userId'], 'alice');
    expect(doc.data()!['isFavorite'], false);
  });

  test('watchMemories returns the newest memory first', () async {
    await addNote('alice', 'Old');
    await Future.delayed(const Duration(milliseconds: 5));
    await addNote('alice', 'New');

    final list = await service.watchMemories('alice').first;
    expect(list.map((m) => m.title), ['New', 'Old']);
  });

  test('a user only sees their own memories', () async {
    await addNote('alice', 'Alice secret');
    await addNote('bob', 'Bob secret');

    final aliceList = await service.watchMemories('alice').first;
    final bobList = await service.watchMemories('bob').first;

    expect(aliceList.map((m) => m.title), ['Alice secret']);
    expect(bobList.map((m) => m.title), ['Bob secret']);
  });

  test('setFavorite persists and can be undone', () async {
    final memory = await addNote('alice', 'Fav');

    await service.setFavorite('alice', memory.id, true);
    var list = await service.watchMemories('alice').first;
    expect(list.single.isFavorite, isTrue);

    await service.setFavorite('alice', memory.id, false);
    list = await service.watchMemories('alice').first;
    expect(list.single.isFavorite, isFalse);
  });

  test(
    'updateMemory edits the same document and does not duplicate it',
    () async {
      final memory = await addNote('alice', 'Before');

      await service.updateMemory(
        'alice',
        memory.id,
        title: 'After',
        content: 'new body',
        category: 'Work',
        intent: 'Read',
        tags: ['a', 'b'],
      );

      final list = await service.watchMemories('alice').first;
      expect(list, hasLength(1));
      expect(list.single.id, memory.id);
      expect(list.single.title, 'After');
      expect(list.single.tags, ['a', 'b']);
      expect(list.single.createdAt, memory.createdAt);
    },
  );

  test('setArchived hides nothing in the service but flips the flag', () async {
    final memory = await addNote('alice', 'Arch');
    await service.setArchived('alice', memory.id, true);

    final list = await service.watchMemories('alice').first;
    expect(list.single.isArchived, isTrue);
  });

  test('deleteMemory removes only that memory', () async {
    final keep = await addNote('alice', 'Keep');
    final remove = await addNote('alice', 'Remove');

    await service.deleteMemory(remove);

    final list = await service.watchMemories('alice').first;
    expect(list.map((m) => m.id), [keep.id]);
  });
}
