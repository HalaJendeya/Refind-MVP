import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Reads this device's Firebase Cloud Messaging (FCM) token and prints it
/// to the Debug Console.
///
/// Firebase must already be started (see [FirebaseService.initialize]).
/// Nothing is stored or sent anywhere yet; this is only for checking the
/// token while developing.
class FcmTokenService {
  FcmTokenService._();

  static StreamSubscription<String>? _refreshSubscription;

  /// Asks for notification permission, prints the current token, and prints
  /// any new token Firebase hands out later. Never throws.
  static Future<void> printDeviceToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Shows the system dialog on Android 13+; older Android
      // versions grant it automatically.
      final settings = await messaging.requestPermission();
      _log('Notification permission: ${settings.authorizationStatus.name}');

      // Listen before asking for the token so a refresh is never missed.
      _refreshSubscription ??= messaging.onTokenRefresh.listen(
        (token) => _log('FCM token refreshed: $token'),
        onError: (Object error) => _log('FCM token refresh failed: $error'),
      );

      final token = await messaging.getToken();
      if (token == null) {
        _log('FCM token is null. Check Google Play services and the network.');
      } else {
        _log('FCM token: $token');
      }
    } catch (error) {
      _log('Could not get FCM token: $error');
    }
  }

  /// Called on logout. Deletes this device's token so the next user gets a
  /// new one (printed again by [printDeviceToken] after they log in).
  /// Never throws.
  static Future<void> clearOnLogout() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      _log('FCM token deleted on logout.');
    } catch (error) {
      _log('Could not delete FCM token: $error');
    }
  }

  static void _log(String message) {
    if (kDebugMode) debugPrint('[FCM] $message');
  }
}
