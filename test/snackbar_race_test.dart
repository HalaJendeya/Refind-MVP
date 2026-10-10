import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Refind/core/utils/ui_helpers.dart';
import 'package:Refind/shared/widgets/screen_header.dart';
import 'package:Refind/shared/widgets/sheets_and_dialogs.dart';

// Tests for the snackbar helpers (showError / showSuccess / showInfo) and for
// closing pages, sheets and dialogs while a snackbar is on screen.
//
// Background: in GetX 4.7.3 a plain Get.back() is ignored while GetX thinks a
// snackbar is open. That is why every close in the app goes through
// closePage(), closeSheet(context) or Navigator.pop(context).

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(Get.reset);
  tearDown(Get.reset);

  // ---------------------------------------------------------------- helpers

  /// Pumps time in small steps and remembers which texts were ever on screen.
  Future<Set<String>> watch(
    WidgetTester tester,
    List<String> texts, {
    int steps = 60,
  }) async {
    final seen = <String>{};
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      for (final text in texts) {
        if (find.text(text).evaluate().isNotEmpty) seen.add(text);
      }
    }
    return seen;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// GetX keeps its snackbar queue in static memory: let everything finish.
  Future<void> endSnackbars(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  }

  /// A tiny app: '/home' has a button that runs [onOpen]; '/page' is a page
  /// with a normal header (back arrow).
  Future<void> pumpApp(WidgetTester tester, {VoidCallback? onOpen}) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/home',
        getPages: [
          GetPage(
            name: '/home',
            page: () => Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('home page'),
                    ElevatedButton(
                      onPressed: onOpen,
                      child: const Text('open'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GetPage(
            name: '/page',
            page: () => const Scaffold(
              appBar: ScreenHeader(title: 'Some page'),
              body: Text('page body'),
            ),
          ),
        ],
      ),
    );
    await settle(tester);
  }

  /// Shows a success snackbar and waits until it is clearly on screen.
  Future<void> showMessageAndWait(WidgetTester tester) async {
    showSuccess('A message');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('A message'), findsOneWidget);
    // The situation under test: GetX considers a snackbar open.
    expect(Get.isSnackbarOpen, isTrue);
  }

  // -------------------------------------------------- the race condition

  group('snackbar messages', () {
    testWidgets('two messages in a row are both displayed', (tester) async {
      await pumpApp(tester);

      showError('First message');
      showSuccess('Second message');
      final seen = await watch(tester, ['First message', 'Second message']);

      expect(seen, contains('First message'));
      expect(seen, contains('Second message'));
      await endSnackbars(tester);
    });

    testWidgets('three messages in a row all appear, in order', (tester) async {
      await pumpApp(tester);

      showInfo('Message 1');
      showInfo('Message 2');
      showInfo('Message 3');

      final order = <String>[];
      for (var i = 0; i < 150; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        for (final text in ['Message 1', 'Message 2', 'Message 3']) {
          if (find.text(text).evaluate().isNotEmpty && !order.contains(text)) {
            order.add(text);
          }
        }
      }

      expect(order, ['Message 1', 'Message 2', 'Message 3']);
      await endSnackbars(tester);
    });

    testWidgets('a message shown alone still appears and then goes away', (
      tester,
    ) async {
      await pumpApp(tester);

      showSuccess('Only message');
      final seen = await watch(tester, ['Only message'], steps: 20);
      expect(seen, contains('Only message'));

      await endSnackbars(tester);
      expect(find.text('Only message'), findsNothing);
      // After it ends GetX no longer reports a snackbar, so nothing is stuck.
      expect(Get.isSnackbarOpen, isFalse);
    });

    testWidgets('after two messages end, nothing is left open', (tester) async {
      await pumpApp(tester);

      showSuccess('One');
      showSuccess('Two');
      await endSnackbars(tester);

      expect(find.text('One'), findsNothing);
      expect(find.text('Two'), findsNothing);
      expect(Get.isSnackbarOpen, isFalse);
    });
  });

  // ------------------------------------------------ closing while a snackbar shows

  group('pages', () {
    testWidgets('the header back arrow works right after a snackbar', (
      tester,
    ) async {
      await pumpApp(tester);
      Get.toNamed('/page');
      await settle(tester);
      expect(find.text('page body'), findsOneWidget);

      await showMessageAndWait(tester);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle(tester);

      expect(find.text('page body'), findsNothing);
      expect(find.text('home page'), findsOneWidget);
      await endSnackbars(tester);
    });

    testWidgets('closePage works in the same step a snackbar is shown', (
      tester,
    ) async {
      await pumpApp(tester);
      Get.toNamed('/page');
      await settle(tester);

      showSuccess('Done');
      expect(Get.isSnackbarOpen, isTrue);
      closePage();
      await settle(tester);

      expect(find.text('home page'), findsOneWidget);
      await endSnackbars(tester);
    });

    testWidgets('closePage works while a snackbar is already showing', (
      tester,
    ) async {
      await pumpApp(tester);
      Get.toNamed('/page');
      await settle(tester);

      await showMessageAndWait(tester);
      closePage();
      await settle(tester);

      expect(find.text('home page'), findsOneWidget);
      await endSnackbars(tester);
    });
  });

  group('bottom sheets', () {
    testWidgets('Cancel closes the sheet while a snackbar is showing', (
      tester,
    ) async {
      await pumpApp(
        tester,
        onOpen: () => showAppSheet(
          const AppSheet(title: 'Menu', child: SheetCancelButton()),
        ),
      );
      await tester.tap(find.text('open'));
      await settle(tester);
      expect(find.text('Menu'), findsOneWidget);

      await showMessageAndWait(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(find.text('Menu'), findsNothing);
      expect(find.text('home page'), findsOneWidget);
      await endSnackbars(tester);
    });

    testWidgets('a sheet option closes the sheet and runs once', (
      tester,
    ) async {
      var taps = 0;
      await pumpApp(
        tester,
        onOpen: () => showAppSheet(
          AppSheet(
            title: 'Menu',
            child: SheetOption(
              icon: Icons.edit,
              label: 'Do it',
              onTap: () => taps++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await settle(tester);

      await showMessageAndWait(tester);
      await tester.tap(find.text('Do it'));
      await settle(tester);

      expect(taps, 1);
      expect(find.text('Menu'), findsNothing);
      await endSnackbars(tester);
    });

    testWidgets('closeSheet closes only its own sheet', (tester) async {
      await pumpApp(
        tester,
        onOpen: () => showAppSheet(
          AppSheet(
            title: 'Menu',
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => closeSheet(context),
                child: const Text('Close me'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await settle(tester);

      await showMessageAndWait(tester);
      await tester.tap(find.text('Close me'));
      await settle(tester);

      expect(find.text('Menu'), findsNothing);
      expect(find.text('home page'), findsOneWidget); // page below still open
      await endSnackbars(tester);
    });
  });

  group('dialogs', () {
    Future<bool?> openDialog(WidgetTester tester) async {
      bool? result;
      var answered = false;
      await pumpApp(
        tester,
        onOpen: () async {
          result = await confirmDialog(
            title: 'Are you sure?',
            message: 'This cannot be undone.',
            confirmLabel: 'Yes, do it',
          );
          answered = true;
        },
      );
      await tester.tap(find.text('open'));
      await settle(tester);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(answered, isFalse);
      return result;
    }

    testWidgets('confirming returns true while a snackbar is showing', (
      tester,
    ) async {
      await openDialog(tester);
      await showMessageAndWait(tester);

      await tester.tap(find.text('Yes, do it'));
      await settle(tester);

      expect(find.text('Are you sure?'), findsNothing);
      expect(find.text('home page'), findsOneWidget);
      await endSnackbars(tester);
    });

    testWidgets('the dialog returns the right answer for each button', (
      tester,
    ) async {
      final results = <bool>[];
      await pumpApp(
        tester,
        onOpen: () async {
          results.add(
            await confirmDialog(
              title: 'Are you sure?',
              message: 'Message',
              confirmLabel: 'Yes, do it',
            ),
          );
        },
      );

      // Confirm.
      await tester.tap(find.text('open'));
      await settle(tester);
      await showMessageAndWait(tester);
      await tester.tap(find.text('Yes, do it'));
      await settle(tester);

      // Cancel.
      await endSnackbars(tester);
      await tester.tap(find.text('open'));
      await settle(tester);
      await showMessageAndWait(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(results, [true, false]);
      expect(find.text('Are you sure?'), findsNothing);
      await endSnackbars(tester);
    });
  });
}
