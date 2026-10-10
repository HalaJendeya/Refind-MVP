import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Refind/core/routes/app_routes.dart';
import 'package:Refind/data/services/auth_service.dart';
import 'package:Refind/features/auth/auth_controller.dart';
import 'package:Refind/features/auth/screens/login_screen.dart';
import 'package:Refind/features/splash/splash_screen.dart';
import 'package:Refind/shared/widgets/refind_logo.dart';

/// A stand-in for Firebase Auth: nobody is logged in.
class FakeAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authChanges => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    Get.put<AuthService>(FakeAuthService(), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
  });

  tearDown(Get.reset);

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('ReFindLogo widget', () {
    testWidgets('is a square of the requested size and keeps its proportions', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const Center(child: ReFindLogo(size: 48))));

      expect(tester.getSize(find.byType(ReFindLogo)), const Size(48, 48));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, 48);
      expect(image.height, 48);
      expect(image.fit, BoxFit.contain);
    });

    testWidgets('has a default size and a description for screen readers', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const Center(child: ReFindLogo())));

      expect(tester.getSize(find.byType(ReFindLogo)), const Size(64, 64));
      expect(
        tester.widget<Image>(find.byType(Image)).semanticLabel,
        'ReFind logo',
      );
    });

    testWidgets('the shadow is optional', (tester) async {
      await tester.pumpWidget(wrap(const Center(child: ReFindLogo())));
      expect(
        find.descendant(
          of: find.byType(ReFindLogo),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );

      await tester.pumpWidget(
        wrap(const Center(child: ReFindLogo(withShadow: true))),
      );
      expect(
        find.descendant(
          of: find.byType(ReFindLogo),
          matching: find.byType(DecoratedBox),
        ),
        findsOneWidget,
      );
    });

    test(
      'the asset is registered in pubspec.yaml and is a square picture',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();

        // Fails if the file is missing or not listed under flutter: assets:
        final data = await rootBundle.load(ReFindLogo.assetPath);
        expect(data.lengthInBytes, greaterThan(0));

        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        expect(frame.image.width, frame.image.height);
      },
    );
  });

  group('screens use the logo, not an "R" placeholder', () {
    testWidgets('splash screen', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const SplashScreen(),
          getPages: [
            GetPage(
              name: AppRoutes.login,
              page: () => const Text('login page'),
            ),
            GetPage(
              name: AppRoutes.onboarding,
              page: () => const Text('onboarding page'),
            ),
          ],
        ),
      );

      expect(find.byType(ReFindLogo), findsOneWidget);
      expect(tester.getSize(find.byType(ReFindLogo)), const Size(96, 96));
      expect(find.text('R'), findsNothing);
      expect(find.text('ReFind'), findsOneWidget); // the name is still there

      // Let the splash finish and leave, so no timer is left running.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    });

    testWidgets('login screen', (tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: LoginScreen()));

      expect(find.byType(ReFindLogo), findsOneWidget);
      expect(tester.getSize(find.byType(ReFindLogo)), const Size(48, 48));
      expect(find.text('R'), findsNothing);
      expect(find.text('Welcome back'), findsOneWidget); // layout text kept
    });
  });
}
