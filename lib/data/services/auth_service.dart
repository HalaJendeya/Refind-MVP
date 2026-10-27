import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// An auth error with a message that is safe to show to the user.
/// `code` is the Firebase / Google error code, kept for logs and checks.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'AuthFailure($code): $message';
}

/// The email/password flows have always thrown this. It is now an
/// [AuthFailure], so one `on AuthFailure` catch handles every sign-in method.
class AuthException extends AuthFailure {
  AuthException(super.message, {super.code});

  @override
  String toString() => message;
}

/// Talks to Firebase Authentication (email/password and Google).
/// Controllers call this class, so no screen needs to know about
/// FirebaseAuth or GoogleSignIn directly.
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// Optional Web Client ID (Firebase Console > Authentication > Google).
  /// Android normally reads it from google-services.json, so leave it empty
  /// unless that fails: `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`.
  /// It is a public identifier, not a secret.
  static const String _serverClientIdFromEnv = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static String? get _serverClientId =>
      _serverClientIdFromEnv.isEmpty ? null : _serverClientIdFromEnv;

  Future<void>? _googleInit;

  // ─────────────────────────── user state ───────────────────────────────

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  /// Emits a new value every time the user logs in or out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Older name for [authStateChanges], used across the app.
  Stream<User?> get authChanges => authStateChanges;

  // ─────────────────────────── email / password ─────────────────────────

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e), code: e.code);
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await result.user?.updateDisplayName(name.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e), code: e.code);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e), code: e.code);
    }
  }

  Future<void> updateDisplayName(String name) async {
    try {
      await _auth.currentUser?.updateDisplayName(name.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e), code: e.code);
    }
  }

  /// Firebase asks users to type their current password again before
  /// changing it, so we sign in again first ("re-authenticate").
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw AuthException('You need to be logged in to change your password.');
    }
    // Google-only accounts have no ReFind password to re-enter.
    final hasPassword = user.providerData.any(
      (info) => info.providerId == EmailAuthProvider.PROVIDER_ID,
    );
    if (!hasPassword) {
      throw AuthException(
        'Your account signs in with Google, so it has no password to change '
        'here.',
      );
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e), code: e.code);
    }
  }

  // ─────────────────────────── Google ───────────────────────────────────

  /// google_sign_in 7 requires initialize() exactly once before anything else.
  Future<void> _ensureGoogleInitialized() {
    return _googleInit ??= _googleSignIn.initialize(
      serverClientId: _serverClientId,
    );
  }

  /// Returns null if the user closed the Google window.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        return await _auth.signInWithPopup(GoogleAuthProvider());
      }

      await _ensureGoogleInitialized();

      // 1) Show the Google account picker.
      final GoogleSignInAccount account = await _googleSignIn.authenticate();

      // 2) The ID token is a synchronous getter in version 7.
      final String? idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(
          'Could not get your Google details. Please try again.',
          code: 'missing-id-token',
        );
      }

      // 3) Turn it into a Firebase credential and 4) sign in to Firebase.
      // With Firebase's default "one account per email" setting, an email
      // already used by another sign-in method is rejected with
      // account-exists-with-different-credential; it is never merged here.
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw AuthFailure(_googleMessage(e.code), code: e.code.name);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_firebaseMessage(e.code), code: e.code);
    }
  }

  // ─────────────────────────── sign out / reload ────────────────────────

  Future<void> signOut() async {
    // After an app restart Google is not initialised yet, so do it first
    // when this user came from Google; otherwise the account stays cached.
    final usedGoogle =
        _auth.currentUser?.providerData.any(
          (info) => info.providerId == GoogleAuthProvider.PROVIDER_ID,
        ) ??
        false;
    if (!kIsWeb && (_googleInit != null || usedGoogle)) {
      try {
        await _ensureGoogleInitialized();
        await _googleSignIn.signOut();
      } catch (_) {
        // Not signed in with Google; nothing to clear.
      }
    }
    await _auth.signOut();
  }

  /// Fetches the latest name, photo and email from Firebase.
  Future<User?> reloadUser() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser;
  }

  // ─────────────────────────── error messages ───────────────────────────

  /// Turns email/password error codes into short, friendly sentences.
  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'requires-recent-login':
        return 'Please log in again and retry.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase yet.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  /// Messages for Google sign-in errors.
  String _firebaseMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'This email is already registered with another sign-in '
            'method. Log in with that method instead.';
      case 'invalid-credential':
        return 'The sign-in details are invalid or expired. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase yet.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }

  String _googleMessage(GoogleSignInExceptionCode code) {
    switch (code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google sign-in is not set up yet (check SHA-1 and the '
            'Firebase config files).';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'The Google sign-in window cannot open right now.';
      default:
        return 'Could not sign in with Google. Please try again.';
    }
  }
}
