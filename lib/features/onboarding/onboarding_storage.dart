import 'package:shared_preferences/shared_preferences.dart';

/// Remembers on the phone that the user has already seen the onboarding.
class OnboardingStorage {
  OnboardingStorage._();

  static const _key = 'onboarding_done';

  static Future<bool> isDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false; // If storage fails, just show onboarding again.
    }
  }

  static Future<void> markDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {
      // Not critical: the user would only see onboarding once more.
    }
  }
}
