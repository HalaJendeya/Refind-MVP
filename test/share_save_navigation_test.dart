import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Refind/core/routes/app_routes.dart';
import 'package:Refind/core/services/share_intent_service.dart';
import 'package:Refind/core/utils/ui_helpers.dart';
import 'package:Refind/data/models/memory_model.dart';
import 'package:Refind/data/services/auth_service.dart';
import 'package:Refind/data/services/memory_service.dart';
import 'package:Refind/features/auth/auth_controller.dart';
import 'package:Refind/features/main/main_controller.dart';
import 'package:Refind/features/save/save_controller.dart';
import 'package:Refind/shared/widgets/app_buttons.dart';

// ---------------------------------------------------------------- fakes
// Small stand-ins so these tests do not need a real Firebase project.

class FakeUser implements User {
  @override
  final String uid;

  FakeUser(this.uid);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  @override
  User? get currentUser => FakeUser('alice');

  @override
  Stream<User?> get authChanges => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthController extends GetxController implements AuthController {
  bool loggedIn = true;

  @override
  bool get isLoggedIn => loggedIn;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FailingMemoryService extends MemoryService {
  FailingMemoryService() : super(db: FakeFirebaseFirestore());

  @override
  Future<Memory> addMemory({
    required String userId,
    required String title,
    required String type,
    String content = '',
    String sourceUrl = '',
    String fileUrl = '',
    String fileName = '',
    String category = '',
    String intent = '',
    List<String> tags = const [],
  }) {
    throw Exception('no connection');
  }
}

// ---------------------------------------------------------------- fake pages

class FakeMainPage extends StatelessWidget {
  const FakeMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final main = Get.find<MainController>();
    return Scaffold(body: Obx(() => Text('main tab ${main.tabIndex.value}')));
  }
}

class FakeAddLinkPage extends StatelessWidget {
  const FakeAddLinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('add link page'),
          ElevatedButton(
            onPressed: () => Get.find<SaveController>().saveNote(
              title: 'My note',
              content: 'hello',
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

void main() {
  late FakeFirebaseFirestore db;
  late FakeAuthController fakeAuthController;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    Get.reset();
    db = FakeFirebaseFirestore();
    fakeAuthController = FakeAuthController();
    Get.put<AuthService>(FakeAuthService(), permanent: true);
    Get.put<MemoryService>(MemoryService(db: db), permanent: true);
    Get.put<AuthController>(fakeAuthController, permanent: true);
  });

  tearDown(Get.reset);

  /// Builds an app with the real route names and the real controllers.
  Future<void> pumpApp(WidgetTester tester, {required String initialRoute}) {
    return tester.pumpWidget(
      GetMaterialApp(
        initialRoute: initialRoute,
        getPages: [
          GetPage(
            name: AppRoutes.main,
            page: () => const FakeMainPage(),
            binding: BindingsBuilder(() => Get.lazyPut(() => MainController())),
          ),
          GetPage(
            name: AppRoutes.addLink,
            page: () => const FakeAddLinkPage(),
            binding: BindingsBuilder(() => Get.lazyPut(() => SaveController())),
          ),
        ],
      ),
    );
  }

  /// Lets animations and short timers finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Puts a success snackbar on screen, as many actions in the app do.
  Future<void> showVisibleSnackbar(WidgetTester tester) async {
    showSuccess('Saved');
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// GetX keeps its snackbar queue in static memory, so let every snackbar
  /// finish before the next test starts.
  Future<void> endSnackbars(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4)); // the 3 s timer fires
    await tester.pumpAndSettle(); // the hide animation finishes
  }

  /// Opens Add Link on top of main, as the share flow now does.
  Future<void> openAddLinkOnTopOfMain(WidgetTester tester) async {
    await pumpApp(tester, initialRoute: AppRoutes.main);
    await settle(tester);
    Get.toNamed(AppRoutes.addLink);
    await settle(tester);
  }

  group('saved sheet buttons', () {
    testWidgets('View in Library works while a snackbar is visible', (
      tester,
    ) async {
      await openAddLinkOnTopOfMain(tester);

      await tester.tap(find.text('Save'));
      await settle(tester);
      expect(find.text('Saved to your Library'), findsOneWidget);

      // Snackbars are on screen while the buttons are tapped. closeSheet must
      // close this sheet no matter what, and the tab must change.
      await showVisibleSnackbar(tester);

      await tester.tap(find.text('View in Library'));
      await settle(tester);

      expect(find.text('Saved to your Library'), findsNothing);
      expect(find.text('main tab 1'), findsOneWidget);
      await endSnackbars(tester);
    });

    testWidgets('Back to Home works while a snackbar is visible', (
      tester,
    ) async {
      await openAddLinkOnTopOfMain(tester);
      Get.find<MainController>().changeTab(2);

      await tester.tap(find.text('Save'));
      await settle(tester);
      await showVisibleSnackbar(tester);

      await tester.tap(find.text('Back to Home'));
      await settle(tester);

      expect(find.text('Saved to your Library'), findsNothing);
      expect(find.text('main tab 0'), findsOneWidget);
      await endSnackbars(tester);
    });

    testWidgets('closes even in the instant a snackbar was just shown', (
      tester,
    ) async {
      await openAddLinkOnTopOfMain(tester);
      await tester.tap(find.text('Save'));
      await settle(tester);
      expect(find.text('Saved to your Library'), findsOneWidget);

      // This is the one moment GetX 4.7.3 reports "snackbar open" (right after
      // showSuccess, in the same step). A plain Get.back() is ignored then.
      final button = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'View in Library'),
      );
      showSuccess('Saved');
      expect(Get.isSnackbarOpen, isTrue);
      button.onPressed!();
      await settle(tester);

      expect(find.text('Saved to your Library'), findsNothing);
      expect(find.text('main tab 1'), findsOneWidget);
      await endSnackbars(tester);
    });

    testWidgets('safety net: main screen missing, no blank screen', (
      tester,
    ) async {
      // The old share flow left only Add Link in the stack.
      await pumpApp(tester, initialRoute: AppRoutes.addLink);
      await settle(tester);
      expect(Get.isRegistered<MainController>(), isFalse);

      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(find.text('Saved to your Library'), findsOneWidget);
      expect(find.text('main tab 0'), findsOneWidget); // main was opened

      await tester.tap(find.text('View in Library'));
      await settle(tester);

      expect(find.text('Saved to your Library'), findsNothing);
      expect(find.text('main tab 1'), findsOneWidget);
    });
  });

  group('saving', () {
    testWidgets('a real save failure shows an error and no success sheet', (
      tester,
    ) async {
      Get.delete<MemoryService>(force: true);
      Get.put<MemoryService>(FailingMemoryService(), permanent: true);
      await openAddLinkOnTopOfMain(tester);

      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(find.text('Saved to your Library'), findsNothing);
      expect(find.textContaining('Could not save'), findsOneWidget);
      expect(find.text('add link page'), findsOneWidget); // still here
      await endSnackbars(tester);
    });

    testWidgets('saving twice with one controller writes only once', (
      tester,
    ) async {
      await openAddLinkOnTopOfMain(tester);
      final controller = Get.find<SaveController>();

      await controller.saveNote(title: 'Once', content: 'text');
      await controller.saveNote(title: 'Once', content: 'text');
      await settle(tester);

      final docs = await db
          .collection('users')
          .doc('alice')
          .collection('memories')
          .get();
      expect(docs.docs, hasLength(1));
    });
  });

  group('share flow', () {
    late ShareIntentService share;

    setUp(() {
      share = ShareIntentService();
    });

    testWidgets('opens Add Link on top of main, keeping main underneath', (
      tester,
    ) async {
      await pumpApp(tester, initialRoute: AppRoutes.main);
      await settle(tester);

      share.handleSharedText('Look at this https://example.com/page.');
      await settle(tester);
      expect(find.text('add link page'), findsOneWidget);
      expect(Get.currentRoute, AppRoutes.addLink);

      Get.back(); // Add Link closes and main is still there
      await settle(tester);
      expect(Get.currentRoute, AppRoutes.main);
      expect(find.text('main tab 0'), findsOneWidget);
      expect(Get.key.currentState!.canPop(), isFalse); // exactly one main
    });

    testWidgets('a repeated delivery of the same share is ignored', (
      tester,
    ) async {
      await pumpApp(tester, initialRoute: AppRoutes.main);
      await settle(tester);

      share.handleSharedText('https://example.com/a');
      await settle(tester);
      Get.back();
      await settle(tester);

      share.handleSharedText('https://example.com/a'); // same share again
      await settle(tester);
      expect(Get.currentRoute, AppRoutes.main);
    });

    testWidgets('a second, different share replaces Add Link (no duplicates)', (
      tester,
    ) async {
      await pumpApp(tester, initialRoute: AppRoutes.main);
      await settle(tester);

      share.handleSharedText('https://example.com/a');
      await settle(tester);
      share.handleSharedText('https://example.com/b');
      await settle(tester);
      expect(Get.currentRoute, AppRoutes.addLink);

      Get.back(); // one Back returns to main, so only one Add Link existed
      await settle(tester);
      expect(Get.currentRoute, AppRoutes.main);
      expect(Get.key.currentState!.canPop(), isFalse);
    });

    testWidgets('logged out: waits, then opens after login', (tester) async {
      await pumpApp(tester, initialRoute: AppRoutes.main);
      await settle(tester);

      fakeAuthController.loggedIn = false;
      share.handleSharedText('https://example.com/a');
      await settle(tester);
      expect(Get.currentRoute, AppRoutes.main); // nothing opened yet

      fakeAuthController.loggedIn = true; // the user logs in
      share.openPendingIfLoggedIn();
      await settle(tester);
      expect(Get.currentRoute, AppRoutes.addLink);
    });

    testWidgets('the plugin failing to start does not crash the app', (
      tester,
    ) async {
      // There is no Android plugin in tests, so onInit hits an error.
      Get.put<ShareIntentService>(ShareIntentService());
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  });
}
