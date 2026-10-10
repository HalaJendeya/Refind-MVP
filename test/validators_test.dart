import 'package:flutter_test/flutter_test.dart';
import 'package:refind_mvp/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('accepts a normal email', () {
      expect(Validators.email('alex@example.com'), isNull);
    });

    test('rejects empty and malformed emails', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('alex'), isNotNull);
      expect(Validators.email('alex@example'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('needs at least 6 characters', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
      expect(Validators.password(null), isNotNull);
    });
  });

  group('URL helpers', () {
    test('accepts http/https addresses, with or without the scheme', () {
      expect(Validators.url('https://example.com/page'), isNull);
      expect(Validators.url('example.com'), isNull);
    });

    test('rejects empty text and things that are not web addresses', () {
      expect(Validators.url(''), isNotNull);
      expect(Validators.url('hello'), isNotNull);
      expect(Validators.url('ftp://example.com'), isNotNull);
    });

    test('normalizeUrl adds https only when missing', () {
      expect(Validators.normalizeUrl('example.com'), 'https://example.com');
      expect(Validators.normalizeUrl('http://a.com'), 'http://a.com');
    });
  });

  test('parseTags splits on commas and drops blanks', () {
    expect(Validators.parseTags('flutter, ui , ,design'), [
      'flutter',
      'ui',
      'design',
    ]);
    expect(Validators.parseTags(''), isEmpty);
  });

  test('required rejects blank text', () {
    expect(Validators.required('  ', 'Title'), 'Title is required');
    expect(Validators.required('ok'), isNull);
  });
}
