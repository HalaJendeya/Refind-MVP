import 'dart:async';

import 'package:better_share_handler/better_share_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/main/main_controller.dart';
import '../routes/app_routes.dart';

class ShareIntentService extends GetxService {
  StreamSubscription<SharedMedia>? _subscription;

  String? _pendingUrl;

  // Some devices deliver the same share twice (once as the "initial" share
  // and once on the stream). These two fields let us ignore the repeat.
  String? _lastHandledUrl;
  DateTime? _lastHandledAt;

  @override
  void onInit() {
    super.onInit();
    _listenForShares();
  }

  Future<void> _listenForShares() async {
    try {
      final handler = ShareHandler.instance;

      // Check whether a share launched the app.
      final initialMedia = await handler.getInitialSharedMedia();

      if (initialMedia != null) {
        _handleSharedMedia(initialMedia);
        await handler.resetInitialSharedMedia();
      }

      // Listen for shares received while the app is running.
      _subscription = handler.sharedMediaStream.listen(_handleSharedMedia);
    } catch (error) {
      // Sharing is a bonus feature. If it cannot start, the app still works.
      debugPrint('Share listener could not start: $error');
    }
  }

  void _handleSharedMedia(SharedMedia media) {
    handleSharedText(media.content ?? '');
  }

  /// Called with the text another app shared. Public so tests can call it
  /// without the Android plugin.
  @visibleForTesting
  void handleSharedText(String content) {
    final url = _extractUrl(content);

    if (url == null || _isRepeatOfLastShare(url)) return;

    _pendingUrl = url;

    // Don't interrupt the splash screen while it decides where to go.
    if (_isLoggedIn && Get.currentRoute != AppRoutes.splash) {
      openPendingIfLoggedIn();
    }
  }

  bool _isRepeatOfLastShare(String url) {
    final now = DateTime.now();
    final lastAt = _lastHandledAt;

    final isRepeat =
        url == _lastHandledUrl &&
        lastAt != null &&
        now.difference(lastAt) < const Duration(seconds: 5);

    if (!isRepeat) {
      _lastHandledUrl = url;
      _lastHandledAt = now;
    }
    return isRepeat;
  }

  String? _extractUrl(String content) {
    final match = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    ).firstMatch(content);

    if (match == null) return null;

    final url = match.group(0)!.replaceFirst(RegExp(r'[),.!?;:]+$'), '');

    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }

    return url;
  }

  bool get _isLoggedIn {
    return Get.isRegistered<AuthController>() &&
        Get.find<AuthController>().isLoggedIn;
  }

  /// MainController lives exactly as long as the main screen, so it tells us
  /// whether the main screen is in the navigation stack.
  bool get _isMainScreenOpen {
    return Get.isRegistered<MainController>() ||
        Get.currentRoute == AppRoutes.main;
  }

  /// Opens the Add Link screen for a shared URL, on TOP of the main screen.
  /// (Opening it with offAllNamed would remove the main screen, and the
  /// "Saved" sheet needs the main screen to go back to.)
  void openPendingIfLoggedIn() {
    if (!_isLoggedIn ||
        _pendingUrl == null ||
        Get.currentRoute == AppRoutes.splash) {
      return;
    }

    final url = _pendingUrl!;
    _pendingUrl = null;
    final arguments = {'sharedUrl': url};

    if (Get.currentRoute == AppRoutes.addLink) {
      // Add Link is already open: replace it instead of stacking a second one.
      Get.offNamed(AppRoutes.addLink, arguments: arguments);
      return;
    }

    if (!_isMainScreenOpen) {
      Get.offAllNamed(AppRoutes.main);
    }
    Get.toNamed(AppRoutes.addLink, arguments: arguments);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
