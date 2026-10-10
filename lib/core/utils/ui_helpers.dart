import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

/// Snackbars used across the app so messages look the same everywhere.
void showError(String message) => _show(message, AppColors.error);

void showSuccess(String message) => _show(message, AppColors.success);

void showInfo(String message) => _show(message, AppColors.textDark);

void _show(String message, Color color) {
  Get.closeAllSnackbars();
  Get.rawSnackbar(
    message: message,
    backgroundColor: color,
    borderRadius: 12,
    margin: const EdgeInsets.all(16),
    snackPosition: SnackPosition.TOP,
    duration: const Duration(seconds: 3),
  );
}

/// "2h ago", "Yesterday", "3 days ago"... for memory cards.
String timeAgo(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays == 1) return 'Yesterday';
  if (difference.inDays < 7) return '${difference.inDays} days ago';
  if (difference.inDays < 30) return '${difference.inDays ~/ 7} weeks ago';
  if (difference.inDays < 365) return '${difference.inDays ~/ 30} months ago';
  return '${difference.inDays ~/ 365} years ago';
}

/// First letters of a name, e.g. "Amira Vale" -> "AV".
String initialsOf(String? name, [String? fallbackEmail]) {
  final source = (name != null && name.trim().isNotEmpty)
      ? name
      : (fallbackEmail ?? '');
  final parts = source
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'R';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
