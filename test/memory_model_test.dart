import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refind_mvp/data/models/memory_model.dart';

void main() {
  final created = DateTime(2026, 1, 2, 3, 4, 5);

  Memory sampleLink() => Memory(
    id: 'abc',
    userId: 'user1',
    title: 'Flutter Animation Tutorial',
    type: MemoryType.link,
    sourceUrl: 'https://www.youtube.com/watch?v=1',
    content: 'Need this for the new project',
    category: 'Learning',
    intent: 'Learn',
    tags: const ['flutter', 'animation'],
    isFavorite: true,
    createdAt: created,
    updatedAt: created,
  );

  group('Memory serialization', () {
    test('toMap then fromMap gives back the same data', () {
      final original = sampleLink();
      final copy = Memory.fromMap('abc', original.toMap());

      expect(copy.title, original.title);
      expect(copy.userId, 'user1');
      expect(copy.type, MemoryType.link);
      expect(copy.sourceUrl, original.sourceUrl);
      expect(copy.tags, ['flutter', 'animation']);
      expect(copy.isFavorite, isTrue);
      expect(copy.isArchived, isFalse);
      expect(copy.createdAt, created);
    });

    test('dates are stored as Firestore Timestamps', () {
      final map = sampleLink().toMap();
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('fromMap uses safe defaults for missing fields', () {
      final memory = Memory.fromMap('x', {});

      expect(memory.title, '');
      expect(memory.type, MemoryType.note);
      expect(memory.tags, isEmpty);
      expect(memory.isFavorite, isFalse);
    });
  });

  group('Memory helpers', () {
    test('domain strips www. and works for non-links', () {
      expect(sampleLink().domain, 'youtube.com');
      final note = Memory.fromMap('n', {
        'type': MemoryType.note,
        'title': 'Hi',
      });
      expect(note.domain, '');
      expect(note.subtitle, 'Note');
    });

    test('copyWith changes only the given fields', () {
      final changed = sampleLink().copyWith(title: 'New', isFavorite: false);

      expect(changed.title, 'New');
      expect(changed.isFavorite, isFalse);
      expect(changed.sourceUrl, sampleLink().sourceUrl);
      expect(changed.id, 'abc');
    });
  });

  group('Memory.matches (search)', () {
    test('is case-insensitive and checks title', () {
      expect(sampleLink().matches('FLUTTER'), isTrue);
    });

    test('checks notes, tags, category, intent and url', () {
      final memory = sampleLink();
      expect(memory.matches('new project'), isTrue);
      expect(memory.matches('animation'), isTrue);
      expect(memory.matches('learning'), isTrue);
      expect(memory.matches('youtube'), isTrue);
    });

    test('an empty query matches everything, a wrong word matches nothing', () {
      expect(sampleLink().matches('   '), isTrue);
      expect(sampleLink().matches('zebra'), isFalse);
    });
  });
}
