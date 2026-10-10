/// Small, reusable checks for form fields.
/// Each validator returns an error message, or null when the value is fine.
class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? url(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please paste a URL';
    if (!isValidUrl(text)) return 'Enter a valid URL, e.g. https://example.com';
    return null;
  }

  /// True for http/https addresses that have a real host name.
  static bool isValidUrl(String text) {
    final uri = Uri.tryParse(normalizeUrl(text));
    if (uri == null) return false;
    final isWeb = uri.scheme == 'http' || uri.scheme == 'https';
    return isWeb && uri.host.contains('.');
  }

  /// Adds https:// when the user typed something like "example.com".
  static String normalizeUrl(String text) {
    final trimmed = text.trim();
    if (trimmed.contains('://')) return trimmed;
    return 'https://$trimmed';
  }

  /// "flutter, ui , " -> ["flutter", "ui"]
  static List<String> parseTags(String text) {
    return text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }
}
