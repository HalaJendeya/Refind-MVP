import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Refind/core/routes/app_routes.dart';
import 'package:Refind/core/utils/ui_helpers.dart';
import 'package:Refind/data/models/memory_model.dart';
import 'package:Refind/data/services/auth_service.dart';
import 'package:Refind/data/services/memory_service.dart';
import 'package:Refind/features/auth/auth_controller.dart';
import 'package:Refind/features/auth/screens/forgot_password_screen.dart';
import 'package:Refind/features/auth/screens/signup_screen.dart';
import 'package:Refind/features/library/library_controller.dart';
import 'package:Refind/features/library/library_screen.dart';
import 'package:Refind/features/memory/memory_controller.dart';
import 'package:Refind/features/memory_details/edit_memory_screen.dart';
import 'package:Refind/features/memory_details/memory_details_controller.dart';
import 'package:Refind/features/memory_details/memory_details_screen.dart';
import 'package:Refind/features/profile/change_password_screen.dart';
import 'package:Refind/features/profile/edit_profile_screen.dart';
import 'package:Refind/features/save/save_controller.dart';
import 'package:Refind/features/save/screens/add_note_screen.dart';
import 'package:Refind/features/save/widgets/add_content_sheet.dart';
import 'package:Refind/features/search/search_controller.dart';
import 'package:Refind/features/search/search_screen.dart';

// These tests use the REAL screens, controllers and routes. Only Firebase is
// replaced by fakes, so a test can make a delete slow or make a save fail.

// ---------------------------------------------------------------- fakes

class FakeUser implements User {
  @override
  final String uid;
  @override
  final String? displayName = 'Alex';
  @override
  final String? email = 'alex@example.com';

  FakeUser(this.uid);

  @override
  Future<void> reload() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  /// Set this to make the next profile/password call fail.
  AuthException? failWith;
  String? newName;
  String? newPassword;

  @override
  User? get currentUser => FakeUser('alice');

  @override
  Stream<User?> get authChanges => const Stream.empty();

  @override
  Future<void> updateDisplayName(String name) async {
    if (failWith != null) throw failWith!;
    newName = name;
  }

  @override
  Future<void> changePassword(String current, String newPassword) async {
    if (failWith != null) throw failWith!;
    this.newPassword = newPassword;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A MemoryService where a test can hold an operation open or make it fail.
class ControllableMemoryService extends MemoryService {
  ControllableMemoryService() : super(db: FakeFirebaseFirestore());

  Completer<void>? deleteGate;
  Completer<void>? archiveGate;
  Completer<void>? updateGate;
  bool failDelete = false;
  bool failArchive = false;
  bool failUpdate = false;
  int deleteCalls = 0;
  int archiveCalls = 0;

  @override
  Future<void> deleteMemory(Memory memory) async {
    deleteCalls++;
    if (failDelete) throw Exception('delete failed');
    await deleteGate?.future;
    return super.deleteMemory(memory);
  }

  @override
  Future<void> setArchived(String userId, String memoryId, bool value) async {
    archiveCalls++;
    if (failArchive) throw Exception('archive failed');
    await archiveGate?.future;
    return super.setArchived(userId, memoryId, value);
  }

  @override
  Future<void> updateMemory(
    String userId,
    String memoryId, {
    required String title,
    required String content,
    required String category,
    required String intent,
    required List<String> tags,
  }) async {
    if (failUpdate) throw Exception('update failed');
    await updateGate?.future;
    return super.updateMemory(
      userId,
      memoryId,
      title: title,
      content: content,
      category: category,
      intent: intent,
      tags: tags,
    );
  }
}

class FakeMainPage extends StatelessWidget {
  const FakeMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('main page'));
  }
}

void main() {
  late FakeAuthService auth;
  late ControllableMemoryService service;
  late String memoryId;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    Get.reset();
    auth = FakeAuthService();
    service = ControllableMemoryService();
    Get.put<AuthService>(auth, permanent: true);
    Get.put<MemoryService>(service, permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<MemoryController>(MemoryController(), permanent: true);

    final memory = await service.addMemory(
      userId: 'alice',
      title: 'Flutter Guide',
      type: MemoryType.link,
      sourceUrl: 'https://example.com',
    );
    memoryId = memory.id;
  });

  tearDown(Get.reset);

  // ---------------------------------------------------------------- helpers

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// GetX keeps its snackbar queue in static memory, so let every snackbar
  /// finish before the next test starts.
  Future<void> endSnackbars(WidgetTester tester) async {
    // Messages are queued, so wait long enough for several in a row.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 4));
    }
    await tester.pumpAndSettle();
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.main,
        getPages: [
          GetPage(name: AppRoutes.main, page: () => const FakeMainPage()),
          GetPage(
            name: AppRoutes.memoryDetails,
            page: () => const MemoryDetailsScreen(),
            binding: BindingsBuilder(
              () => Get.lazyPut(() => MemoryDetailsController()),
            ),
          ),
          GetPage(
            name: AppRoutes.editMemory,
            page: () => const EditMemoryScreen(),
          ),
          GetPage(
            name: AppRoutes.editProfile,
            page: () => const EditProfileScreen(),
          ),
          GetPage(
            name: AppRoutes.changePassword,
            page: () => const ChangePasswordScreen(),
          ),
          GetPage(name: AppRoutes.signup, page: () => const SignupScreen()),
          GetPage(
            name: AppRoutes.forgotPassword,
            page: () => const ForgotPasswordScreen(),
          ),
          GetPage(
            name: AppRoutes.search,
            page: () => const SearchScreen(),
            binding: BindingsBuilder(
              () => Get.lazyPut(() => MemorySearchController()),
            ),
          ),
          GetPage(
            name: AppRoutes.addNote,
            page: () => const AddNoteScreen(),
            binding: BindingsBuilder(() => Get.lazyPut(() => SaveController())),
          ),
          // The Library is a tab in the real app; this gives the test a route to it.
          GetPage(
            name: '/library-test',
            page: () => const LibraryScreen(),
            binding: BindingsBuilder(
              () => Get.lazyPut(() => LibraryController()),
            ),
          ),
        ],
      ),
    );
    await settle(tester); // lets MemoryController load the memory
  }

  Future<void> openDetails(WidgetTester tester) async {
    await pumpApp(tester);
    Get.toNamed(AppRoutes.memoryDetails, arguments: memoryId);
    await settle(tester);
    expect(find.text('Flutter Guide'), findsWidgets);
  }

  Future<void> openEdit(WidgetTester tester) async {
    await openDetails(tester);
    Get.toNamed(AppRoutes.editMemory, arguments: memoryId);
    await settle(tester);
    expect(find.text('Edit Memory'), findsOneWidget);
  }

  MemoryDetailsController details() => Get.find<MemoryDetailsController>();

  // ----------------------------------------------------------------- delete

  group('delete memory', () {
    testWidgets('shows Deleting..., then closes the page and says Deleted', (
      tester,
    ) async {
      await openDetails(tester);
      service.deleteGate = Completer<void>();

      unawaited(details().confirmAndDelete());
      await settle(tester);
      expect(find.text('Delete this item?'), findsOneWidget);

      // Asking again while the dialog is open must not open a second dialog.
      unawaited(details().confirmAndDelete());
      await settle(tester);
      expect(find.text('Delete this item?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await settle(tester);

      // Waiting for the server: a progress screen, never a blank one.
      expect(find.text('Deleting...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Repeated delete taps do nothing while a delete is running.
      unawaited(details().confirmAndDelete());
      await settle(tester);
      expect(find.text('Delete this item?'), findsNothing);

      // System Back is blocked while deleting.
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('Deleting...'), findsOneWidget);

      service.deleteGate!.complete();
      await settle(tester);

      expect(service.deleteCalls, 1);
      expect(Get.currentRoute, AppRoutes.main);
      expect(find.text('main page'), findsOneWidget);
      expect(find.text('Deleting...'), findsNothing);
      expect(find.text('Deleted'), findsOneWidget);
      await endSnackbars(tester);
    });

    testWidgets('a failed delete keeps the screen usable and shows an error', (
      tester,
    ) async {
      await openDetails(tester);
      service.failDelete = true;

      unawaited(details().confirmAndDelete());
      await settle(tester);
      await tester.tap(find.text('Delete'));
      await settle(tester);

      expect(Get.currentRoute, AppRoutes.memoryDetails);
      expect(find.text('Deleting...'), findsNothing);
      expect(find.text('Flutter Guide'), findsWidgets);
      expect(
        find.text('Could not delete this item. Please try again.'),
        findsOneWidget,
      );
      expect(details().isDeleting.value, isFalse);
      await endSnackbars(tester);

      // And the user can try again.
      service.failDelete = false;
      unawaited(details().confirmAndDelete());
      await settle(tester);
      expect(find.text('Delete this item?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
    });

    testWidgets('cancelling the dialog deletes nothing', (tester) async {
      await openDetails(tester);

      unawaited(details().confirmAndDelete());
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(service.deleteCalls, 0);
      expect(Get.currentRoute, AppRoutes.memoryDetails);
      expect(find.text('Flutter Guide'), findsWidgets);
    });

    testWidgets('an item deleted elsewhere shows a message, not a blank page', (
      tester,
    ) async {
      await openDetails(tester);

      // Deleted from another device: it just disappears from the list.
      await service.deleteMemory(Get.find<MemoryController>().byId(memoryId)!);
      await settle(tester);

      expect(find.text('This item is no longer available'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle(tester);
      expect(Get.currentRoute, AppRoutes.main);
    });
  });

  // ---------------------------------------------------------------- archive

  group('archive memory', () {
    testWidgets('goes back to the previous screen and says Archived', (
      tester,
    ) async {
      await openDetails(tester);

      unawaited(details().toggleArchive());
      await settle(tester);

      expect(Get.currentRoute, AppRoutes.main);
      expect(find.text('Archived'), findsOneWidget);
      expect(Get.find<MemoryController>().byId(memoryId)!.isArchived, isTrue);
      await endSnackbars(tester);
    });

    testWidgets('a failed archive keeps the screen usable and shows an error', (
      tester,
    ) async {
      await openDetails(tester);
      service.failArchive = true;

      unawaited(details().toggleArchive());
      await settle(tester);

      expect(Get.currentRoute, AppRoutes.memoryDetails);
      expect(find.text('Flutter Guide'), findsWidgets);
      expect(
        find.text('Could not update this item. Please try again.'),
        findsOneWidget,
      );
      expect(details().isArchiving.value, isFalse);
      expect(Get.find<MemoryController>().byId(memoryId)!.isArchived, isFalse);
      await endSnackbars(tester);
    });

    testWidgets('repeated taps archive only once and show progress', (
      tester,
    ) async {
      await openDetails(tester);
      service.archiveGate = Completer<void>();

      unawaited(details().toggleArchive());
      unawaited(details().toggleArchive());
      await settle(tester);

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(service.archiveCalls, 1);

      service.archiveGate!.complete();
      await settle(tester);
      expect(Get.currentRoute, AppRoutes.main);
      await endSnackbars(tester);
    });

    testWidgets('moving an archived item back says so', (tester) async {
      await service.setArchived('alice', memoryId, true);
      await openDetails(tester);

      unawaited(details().toggleArchive());
      await settle(tester);

      expect(Get.currentRoute, AppRoutes.main);
      expect(find.text('Moved back to your Library'), findsOneWidget);
      await endSnackbars(tester);
    });
  });

  // ------------------------------------------------------------------- edit

  group('edit memory', () {
    testWidgets('saves, goes back to the previous screen and says Saved', (
      tester,
    ) async {
      await openEdit(tester);

      await tester.enterText(find.byType(TextFormField).first, 'New title');
      await tester.tap(find.text('Save Changes'));
      await settle(tester);

      expect(Get.currentRoute, AppRoutes.memoryDetails);
      expect(find.text('Edit Memory'), findsNothing);
      expect(find.text('Changes saved'), findsOneWidget);
      expect(Get.find<MemoryController>().byId(memoryId)!.title, 'New title');
      await endSnackbars(tester);
    });

    testWidgets('a failed save stays on the edit screen with an error', (
      tester,
    ) async {
      await openEdit(tester);
      service.failUpdate = true;

      await tester.enterText(find.byType(TextFormField).first, 'New title');
      await tester.tap(find.text('Save Changes'));
      await settle(tester);

      expect(find.text('Edit Memory'), findsOneWidget);
      expect(Get.currentRoute, AppRoutes.editMemory);
      expect(
        find.text('Could not save your changes. Please try again.'),
        findsOneWidget,
      );
      // The button is usable again (not stuck on a spinner).
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Save Changes'), findsOneWidget);
      await endSnackbars(tester);
    });

    testWidgets('does not close before the save finishes', (tester) async {
      await openEdit(tester);
      service.updateGate = Completer<void>();

      await tester.enterText(find.byType(TextFormField).first, 'New title');
      await tester.tap(find.text('Save Changes'));
      await tester.pump(const Duration(milliseconds: 300));

      // Still saving: stays open, and system Back is blocked.
      expect(find.text('Edit Memory'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('Edit Memory'), findsOneWidget);

      service.updateGate!.complete();
      await settle(tester);
      expect(Get.currentRoute, AppRoutes.memoryDetails);
      await endSnackbars(tester);
    });
  });

  // ---------------------------------------------------- profile & password

  group('profile and password', () {
    testWidgets('profile update goes back and says Profile updated', (
      tester,
    ) async {
      await pumpApp(tester);
      Get.toNamed(AppRoutes.editProfile);
      await settle(tester);

      await tester.enterText(find.byType(TextFormField).first, 'New Name');
      await tester.tap(find.text('Save Changes'));
      await settle(tester);

      expect(auth.newName, 'New Name');
      expect(Get.currentRoute, AppRoutes.main);
      expect(find.text('Profile updated'), findsOneWidget);
      await endSnackbars(tester);
    });

    testWidgets('a failed profile update stays on the screen', (tester) async {
      await pumpApp(tester);
      Get.toNamed(AppRoutes.editProfile);
      await settle(tester);
      auth.failWith = AuthException('No internet connection.');

      await tester.enterText(find.byType(TextFormField).first, 'New Name');
      await tester.tap(find.text('Save Changes'));
      await settle(tester);

      expect(Get.currentRoute, AppRoutes.editProfile);
      expect(find.text('No internet connection.'), findsOneWidget);
      expect(find.text('Profile updated'), findsNothing);
      await endSnackbars(tester);
    });

    testWidgets('password change goes back and says Password changed', (
      tester,
    ) async {
      await pumpApp(tester);
      Get.toNamed(AppRoutes.changePassword);
      await settle(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'oldpass1');
      await tester.enterText(fields.at(1), 'newpass12');
      await tester.enterText(fields.at(2), 'newpass12');
      await tester.tap(find.text('Update Password'));
      await settle(tester);

      expect(auth.newPassword, 'newpass12');
      expect(Get.currentRoute, AppRoutes.main);
      expect(find.text('Password changed'), findsOneWidget);
      await endSnackbars(tester);
    });

    testWidgets('a wrong current password stays on the screen', (tester) async {
      await pumpApp(tester);
      Get.toNamed(AppRoutes.changePassword);
      await settle(tester);
      auth.failWith = AuthException('Incorrect email or password.');

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'wrong');
      await tester.enterText(fields.at(1), 'newpass12');
      await tester.enterText(fields.at(2), 'newpass12');
      await tester.tap(find.text('Update Password'));
      await settle(tester);

      expect(Get.currentRoute, AppRoutes.changePassword);
      expect(find.text('Incorrect email or password.'), findsOneWidget);
      expect(find.text('Password changed'), findsNothing);
      await endSnackbars(tester);
    });
  });

  // ---------------------------------------------------------- closePage()

  group('closePage', () {
    testWidgets('works in the same step a snackbar is shown', (tester) async {
      await openDetails(tester);

      // The exact moment GetX 4.7.3 makes Get.back() do nothing.
      showSuccess('Done');
      expect(Get.isSnackbarOpen, isTrue);
      closePage();
      await settle(tester);

      expect(Get.currentRoute, AppRoutes.main);
      await endSnackbars(tester);
    });

    testWidgets('never leaves a blank screen if there is no page below', (
      tester,
    ) async {
      await pumpApp(tester); // only the main page is open
      closePage();
      await settle(tester);

      expect(find.text('main page'), findsOneWidget);
    });
  });

  // ----------------------------------------- closing things while a snackbar shows
  //
  // GetX makes a plain Get.back() do nothing while a snackbar is queued or
  // visible. Every close in the app must therefore work in exactly that state.

  group('with a snackbar on screen', () {
    /// Puts a snackbar on screen and checks that GetX counts it as open.
    Future<void> showMessageAndWait(WidgetTester tester) async {
      showInfo('A message');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('A message'), findsOneWidget);
      expect(Get.isSnackbarOpen, isTrue);
    }

    /// Waits up to [seconds] for [text] to appear on screen.
    Future<bool> appears(
      WidgetTester tester,
      String text, {
      int seconds = 12,
    }) async {
      for (var i = 0; i < seconds * 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text(text).evaluate().isNotEmpty) return true;
      }
      return false;
    }

    testWidgets(
      'details: Archive in the options sheet works, and its message appears '
      'after the earlier one',
      (tester) async {
        await openDetails(tester);
        await tester.tap(find.byIcon(Icons.more_vert));
        await settle(tester);
        expect(find.text('Options'), findsOneWidget);

        await showMessageAndWait(tester);
        await tester.tap(find.text('Archive'));
        await settle(tester);

        expect(find.text('Options'), findsNothing);
        expect(Get.currentRoute, AppRoutes.main);
        expect(Get.find<MemoryController>().byId(memoryId)!.isArchived, isTrue);
        // Both messages are shown, one after the other (nothing is dropped).
        expect(await appears(tester, 'Archived'), isTrue);
        await endSnackbars(tester);
      },
    );

    testWidgets('details: Edit in the options sheet opens the edit screen', (
      tester,
    ) async {
      await openDetails(tester);
      await tester.tap(find.byIcon(Icons.more_vert));
      await settle(tester);

      await showMessageAndWait(tester);
      await tester.tap(find.text('Edit'));
      await settle(tester);

      expect(find.text('Options'), findsNothing);
      expect(Get.currentRoute, AppRoutes.editMemory);
      await endSnackbars(tester);
    });

    testWidgets('details: the back arrow works', (tester) async {
      await openDetails(tester);

      await showMessageAndWait(tester);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle(tester);

      expect(Get.currentRoute, AppRoutes.main);
      await endSnackbars(tester);
    });

    testWidgets('details: the delete dialog works and Deleted is shown', (
      tester,
    ) async {
      await openDetails(tester);
      unawaited(details().confirmAndDelete());
      await settle(tester);
      expect(find.text('Delete this item?'), findsOneWidget);

      await showMessageAndWait(tester);
      await tester.tap(find.text('Delete'));
      await settle(tester);

      expect(find.text('Delete this item?'), findsNothing);
      expect(Get.currentRoute, AppRoutes.main);
      expect(Get.find<MemoryController>().byId(memoryId), isNull);
      expect(await appears(tester, 'Deleted'), isTrue);
      await endSnackbars(tester);
    });

    testWidgets('edit: the close button works', (tester) async {
      await openEdit(tester);

      await showMessageAndWait(tester);
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      expect(Get.currentRoute, AppRoutes.memoryDetails);
      await endSnackbars(tester);
    });

    testWidgets('library: the sort sheet closes after choosing an option', (
      tester,
    ) async {
      await pumpApp(tester);
      Get.toNamed('/library-test');
      await settle(tester);

      await tester.tap(find.byIcon(Icons.swap_vert));
      await settle(tester);
      expect(find.text('Sort by'), findsOneWidget);

      await showMessageAndWait(tester);
      await tester.tap(find.text('Oldest first'));
      await settle(tester);

      expect(find.text('Sort by'), findsNothing);
      expect(Get.find<LibraryController>().sort.value, LibrarySort.oldest);
      await endSnackbars(tester);
    });

    testWidgets('library: the intent sheet closes with Done', (tester) async {
      await pumpApp(tester);
      Get.toNamed('/library-test');
      await settle(tester);

      await tester.tap(find.text('Intent'));
      await settle(tester);
      expect(find.text('Filter by intent'), findsOneWidget);

      await showMessageAndWait(tester);
      await tester.tap(find.text('Done'));
      await settle(tester);

      expect(find.text('Filter by intent'), findsNothing);
      await endSnackbars(tester);
    });

    testWidgets('add content: a coming-soon option and its Got it button', (
      tester,
    ) async {
      await pumpApp(tester);
      showAddContentSheet();
      await settle(tester);
      expect(find.text('Add Content'), findsOneWidget);

      await showMessageAndWait(tester);
      await tester.tap(find.text('Add Image'));
      await settle(tester);
      expect(find.text('Add Content'), findsNothing);
      expect(find.text('Image uploads are coming soon'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await settle(tester);
      expect(find.text('Image uploads are coming soon'), findsNothing);
      await endSnackbars(tester);
    });

    testWidgets('add content: Add Note opens the page, and Cancel closes it', (
      tester,
    ) async {
      await pumpApp(tester);
      showAddContentSheet();
      await settle(tester);

      await showMessageAndWait(tester);
      await tester.tap(find.text('Add Note'));
      await settle(tester);
      expect(find.text('Add Content'), findsNothing);
      expect(Get.currentRoute, AppRoutes.addNote);

      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(Get.currentRoute, AppRoutes.main);
      await endSnackbars(tester);
    });

    testWidgets('sign up: the back arrow and the Log in link work', (
      tester,
    ) async {
      await pumpApp(tester);

      Get.toNamed(AppRoutes.signup);
      await settle(tester);
      await showMessageAndWait(tester);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle(tester);
      expect(Get.currentRoute, AppRoutes.main);
      await endSnackbars(tester);

      Get.toNamed(AppRoutes.signup);
      await settle(tester);
      await showMessageAndWait(tester);
      await tester.ensureVisible(find.text('Log in')); // it is below the fold
      await tester.pump();
      await tester.tap(find.text('Log in'));
      await settle(tester);
      expect(Get.currentRoute, AppRoutes.main);
      await endSnackbars(tester);
    });

    testWidgets('forgot password: Back to Log In works', (tester) async {
      await pumpApp(tester);
      Get.toNamed(AppRoutes.forgotPassword);
      await settle(tester);

      await showMessageAndWait(tester);
      await tester.tap(find.text('Back to Log In'));
      await settle(tester);

      expect(Get.currentRoute, AppRoutes.main);
      await endSnackbars(tester);
    });

    testWidgets('search: the back arrow works', (tester) async {
      await pumpApp(tester);
      Get.toNamed(AppRoutes.search);
      await settle(tester);

      await showMessageAndWait(tester);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle(tester);

      expect(Get.currentRoute, AppRoutes.main);
      await endSnackbars(tester);
    });
  });
}
