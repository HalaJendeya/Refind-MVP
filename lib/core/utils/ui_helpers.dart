import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

/// Snackbars used across the app so messages look the same everywhere.
void showError(String message) => _show(message, AppColors.error);

void showSuccess(String message) => _show(message, AppColors.success);

void showInfo(String message) => _show(message, AppColors.textDark);

/// Closes the PAGE on top of the navigation stack (after a successful
/// save, delete, archive ...).
///
/// Why not `Get.back()`? In GetX 4.7.3 `Get.back()` is ignored when it runs
/// in the same step as a snackbar being shown. This always pops the page.
/// Use it only for pages: for a bottom sheet use `closeSheet(context)`, and
/// for a dialog `Get.back(result: ...)` is fine because no snackbar is involved.
///
/// If there is no page below (it should not happen), it opens the main
/// screen so the user never ends up on a blank screen.
void closePage() {
  final navigator = Get.key.currentState;
  if (navigator != null && navigator.canPop()) {
    navigator.pop();
  } else {
    Get.offAllNamed(AppRoutes.main);
  }
}

void _show(String message, Color color) {
  // GetX queues snackbars: a new one waits until the visible one has gone,
  // so every message is shown, in order.
  //
  // Do NOT call Get.closeAllSnackbars() (or closeCurrentSnackbar()) before
  // this. Its clean-up finishes asynchronously, AFTER the new snackbar was
  // added, and it wipes that new snackbar from the queue, so messages got lost.
  //
  // Side effect to remember: while a snackbar is queued or visible, GetX
  // makes a plain Get.back() do nothing except dismiss the snackbar. Close
  // pages, sheets and dialogs with closePage(), closeSheet(context) or
  // Navigator.pop(context) instead.
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
