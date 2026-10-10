/// Which files the app can upload, and how big they may be.
/// The numbers and types here must match `storage.rules`.
class FileTypes {
  FileTypes._();

  /// Files must be SMALLER than this (10 MB). Same limit as storage.rules.
  static const int maxUploadBytes = 10 * 1024 * 1024;

  /// Document extensions offered by the document picker.
  static const List<String> documentExtensions = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'csv',
  ];

  static const Map<String, String> _documentTypes = {
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'txt': 'text/plain',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'csv': 'text/csv',
  };

  static const Map<String, String> _imageTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'heif': 'image/heif',
    'bmp': 'image/bmp',
  };

  static bool isTooLarge(int bytes) => bytes >= maxUploadBytes;

  /// The MIME type to send with an upload, or null if the app does not
  /// support this kind of file. Images with an unknown extension are treated
  /// as JPEG, because the photo picker only returns pictures.
  static String? contentTypeFor(String fileName, {required bool isImage}) {
    final dot = fileName.lastIndexOf('.');
    final extension = dot == -1
        ? ''
        : fileName.substring(dot + 1).toLowerCase();

    if (isImage) return _imageTypes[extension] ?? 'image/jpeg';
    return _documentTypes[extension];
  }
}
