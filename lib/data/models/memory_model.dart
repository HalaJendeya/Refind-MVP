import 'package:cloud_firestore/cloud_firestore.dart';

/// The kinds of things a user can save.
class MemoryType {
  MemoryType._();

  static const String link = 'link';
  static const String note = 'note';
  static const String image = 'image';
  static const String document = 'document';

  static const List<String> all = [link, note, image, document];

  static String label(String type) {
    switch (type) {
      case link:
        return 'Link';
      case note:
        return 'Note';
      case image:
        return 'Image';
      case document:
        return 'Document';
      default:
        return 'Item';
    }
  }
}

/// One saved item. Stored at `users/{userId}/memories/{id}` in Firestore.
class Memory {
  final String id;
  final String userId;
  final String title;
  final String content; // note text, or the "why I saved this" note
  final String type; // one of MemoryType
  final String sourceUrl;
  final String fileUrl;
  final String fileName;
  final String category;
  final String intent;
  final List<String> tags;
  final bool isFavorite;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Memory({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.content = '',
    this.sourceUrl = '',
    this.fileUrl = '',
    this.fileName = '',
    this.category = '',
    this.intent = '',
    this.tags = const [],
    this.isFavorite = false,
    this.isArchived = false,
  });

  /// Reads a Firestore document into a Memory. Missing fields get safe defaults.
  factory Memory.fromMap(String id, Map<String, dynamic> data) {
    return Memory(
      id: id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      type: data['type'] as String? ?? MemoryType.note,
      sourceUrl: data['sourceUrl'] as String? ?? '',
      fileUrl: data['fileUrl'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      category: data['category'] as String? ?? '',
      intent: data['intent'] as String? ?? '',
      tags: List<String>.from(data['tags'] as List? ?? const []),
      isFavorite: data['isFavorite'] as bool? ?? false,
      isArchived: data['isArchived'] as bool? ?? false,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  /// Converts the Memory into the map we store in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'type': type,
      'sourceUrl': sourceUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'category': category,
      'intent': intent,
      'tags': tags,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Memory copyWith({
    String? title,
    String? content,
    String? category,
    String? intent,
    List<String>? tags,
    bool? isFavorite,
    bool? isArchived,
    DateTime? updatedAt,
  }) {
    return Memory(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type,
      sourceUrl: sourceUrl,
      fileUrl: fileUrl,
      fileName: fileName,
      category: category ?? this.category,
      intent: intent ?? this.intent,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// The website name for links, e.g. "youtube.com". Empty for other types.
  String get domain {
    if (sourceUrl.isEmpty) return '';
    final uri = Uri.tryParse(sourceUrl);
    final host = uri?.host ?? '';
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  /// Second line of a card: the website, the file name, or a note hint.
  String get subtitle {
    if (domain.isNotEmpty) return domain;
    if (fileName.isNotEmpty) return fileName;
    return MemoryType.label(type);
  }

  /// Simple text search used by the Search and Library screens.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final searchable = [
      title,
      content,
      sourceUrl,
      fileName,
      category,
      intent,
      ...tags,
    ].join(' ').toLowerCase();
    return searchable.contains(q);
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    // A brand new document has a null server timestamp for a moment.
    return DateTime.now();
  }
}
