import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:refind/core/utils/file_types.dart';

void main() {
  group('size limit', () {
    test('files of exactly 10 MB or more are too large', () {
      expect(FileTypes.isTooLarge(10 * 1024 * 1024 - 1), isFalse);
      expect(FileTypes.isTooLarge(10 * 1024 * 1024), isTrue);
      expect(FileTypes.isTooLarge(50 * 1024 * 1024), isTrue);
    });
  });

  group('contentTypeFor', () {
    test('every document extension the picker offers has a content type', () {
      for (final extension in FileTypes.documentExtensions) {
        expect(
          FileTypes.contentTypeFor('file.$extension', isImage: false),
          isNotNull,
          reason: extension,
        );
      }
    });

    test('is not case sensitive and handles common images', () {
      expect(
        FileTypes.contentTypeFor('REPORT.PDF', isImage: false),
        'application/pdf',
      );
      expect(
        FileTypes.contentTypeFor('photo.JPG', isImage: true),
        'image/jpeg',
      );
      expect(FileTypes.contentTypeFor('pic.png', isImage: true), 'image/png');
      expect(FileTypes.contentTypeFor('pic.heic', isImage: true), 'image/heic');
    });

    test('unknown image extension falls back to JPEG', () {
      expect(FileTypes.contentTypeFor('scan', isImage: true), 'image/jpeg');
    });

    test('unsupported documents return null', () {
      expect(FileTypes.contentTypeFor('virus.exe', isImage: false), isNull);
      expect(FileTypes.contentTypeFor('noextension', isImage: false), isNull);
    });
  });

  test('storage.rules allows every document content type the app can send', () {
    final rules = File('storage.rules').readAsStringSync();

    for (final extension in FileTypes.documentExtensions) {
      final type = FileTypes.contentTypeFor('f.$extension', isImage: false)!;
      expect(
        rules,
        contains("'$type'"),
        reason: 'missing $type for .$extension',
      );
    }
    expect(rules, contains("matches('image/.*')"));
    expect(rules, contains('10 * 1024 * 1024'));
  });
}
