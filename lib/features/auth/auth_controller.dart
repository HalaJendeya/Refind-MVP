import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/services/auth_service.dart';

/// Handles login, sign up, password reset and logout.
/// It lives for the whole app, so any screen can ask who is logged in.
class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  /// The signed-in user, or null. Updates automatically (Firebase remembers
  /// the session, so the user stays logged in after restarting the app).
  final Rxn<User> user = Rxn<User>();

  /// True while a request is running. Screens use it to disable buttons.
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    user.value = _authService.currentUser;
    user.bindStream(_authService.authChanges);
  }

  bool get isLoggedIn => _authService.currentUser != null;

  String get displayName => user.value?.displayName ?? '';
  String get email => user.value?.email ?? '';

  Future<void> login(String email, String password) async {
    if (isLoading.value) return; // ignore double taps
    isLoading.value = true;
    try {
      await _authService.signIn(email, password);
      Get.offAllNamed(AppRoutes.main);
    } on AuthException catch (e) {
      showError(e.message);
    } catch (_) {
      showError('Could not log in. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String name, String email, String password) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _authService.register(name, email, password);
      Get.offAllNamed(AppRoutes.main);
    } on AuthException catch (e) {
      showError(e.message);
    } catch (_) {
      showError('Could not create your account. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Returns true when the reset email was sent.
  Future<bool> sendPasswordReset(String email) async {
    if (isLoading.value) return false;
    isLoading.value = true;
    try {
      await _authService.sendPasswordReset(email);
      return true;
    } on AuthException catch (e) {
      showError(e.message);
      return false;
    } catch (_) {
      showError('Could not send the reset email. Please try again.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateName(String name) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _authService.updateDisplayName(name);
      // Re-read the user so the new name shows up everywhere.
      await _authService.currentUser?.reload();
      user.value = _authService.currentUser;
      user.refresh();
      showSuccess('Profile updated');
      Get.back();
    } on AuthException catch (e) {
      showError(e.message);
    } catch (_) {
      showError('Could not update your profile.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changePassword(String current, String newPassword) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _authService.changePassword(current, newPassword);
      showSuccess('Password changed');
      Get.back();
    } on AuthException catch (e) {
      showError(e.message);
    } catch (_) {
      showError('Could not change your password.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
      Get.offAllNamed(AppRoutes.login);
    } catch (_) {
      showError('Could not log out. Please try again.');
    }
  }
}
