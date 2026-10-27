import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Refind/core/routes/app_routes.dart';
import 'package:Refind/data/services/auth_service.dart';
import 'package:Refind/features/auth/auth_controller.dart';
import 'package:Refind/features/auth/screens/login_screen.dart';

// The real Login screen and AuthController; only Firebase/Google is faked.

class FakeUserCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  /// What the next Google sign-in does. Defaults to "user cancelled".
  Future<UserCredential?> Function() onGoogle = () async => null;
  int googleCalls = 0;
  int emailCalls = 0;
  int signOutCalls = 0;

  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authChanges => const Stream.empty();

  @override
  Future<UserCredential?> signInWithGoogle() {
    googleCalls++;
    return onGoogle();
  }

  @override
  Future<void> signIn(String email, String password) async => emailCalls++;

  @override
  Future<void> signOut() async => signOutCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeAuthService auth;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    Get.reset();
    auth = FakeAuthService();
    Get.put<AuthService>(auth, permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
  });

  tearDown(Get.reset);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// GetX keeps its snackbar queue in static memory; let it drain.
  Future<void> endSnackbars(WidgetTester tester) async {
    for (var i = 0; i < 2; i++) {
      await tester.pump(const Duration(seconds: 4));
    }
    await tester.pumpAndSettle();
  }

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.login,
        getPages: [
          GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
          GetPage(
            name: AppRoutes.main,
            page: () => const Scaffold(body: Text('main page')),
          ),
        ],
      ),
    );
    await settle(tester);
  }

  final googleButton = find.text('Continue with Google');

  testWidgets('cancelling Google sign-in stays on login with no error', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await settle(tester);

    expect(auth.googleCalls, 1);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('main page'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(Get.find<AuthController>().isGoogleLoading.value, isFalse);
  });

  testWidgets('a Google error is shown and the user stays on login', (
    tester,
  ) async {
    auth.onGoogle = () async => throw const AuthFailure(
      'Google sign-in is not set up yet.',
      code: 'clientConfigurationError',
    );
    await pumpLogin(tester);

    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await settle(tester);

    expect(find.text('Google sign-in is not set up yet.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(Get.find<AuthController>().isGoogleLoading.value, isFalse);
    await endSnackbars(tester);
  });

  testWidgets('a successful Google sign-in opens the main app', (tester) async {
    auth.onGoogle = () async => FakeUserCredential();
    await pumpLogin(tester);

    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await settle(tester);

    expect(find.text('main page'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets(
    'while Google is loading, more taps and email login are ignored',
    (tester) async {
      final pending = Completer<UserCredential?>();
      auth.onGoogle = () => pending.future;
      await pumpLogin(tester);

      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(googleButton, warnIfMissed: false);
      await Get.find<AuthController>().login('a@b.com', 'secret1');
      expect(auth.googleCalls, 1);
      expect(auth.emailCalls, 0);

      pending.complete(null);
      await settle(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('email login still works and opens the main app', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.ensureVisible(find.text('Log In'));
    await tester.tap(find.text('Log In'));
    await settle(tester);

    expect(auth.emailCalls, 1);
    expect(find.text('main page'), findsOneWidget);
  });

  testWidgets('logout signs out and returns to login', (tester) async {
    auth.onGoogle = () async => FakeUserCredential();
    await pumpLogin(tester);
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await settle(tester);

    await Get.find<AuthController>().logout();
    await settle(tester);

    expect(auth.signOutCalls, 1);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  test('AuthException is an AuthFailure, so one catch handles both', () {
    final error = AuthException('Incorrect email or password.');
    expect(error, isA<AuthFailure>());
    expect(error.toString(), 'Incorrect email or password.');
  });

  testWidgets('the login screen offers no Apple sign-in', (tester) async {
    await pumpLogin(tester);
    expect(find.text('Continue with Apple'), findsNothing);
  });
}
