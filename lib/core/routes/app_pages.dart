import 'package:get/get.dart';

import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/library/library_controller.dart';
import '../../features/main/main_controller.dart';
import '../../features/main/main_screen.dart';
import '../../features/memory_details/edit_memory_screen.dart';
import '../../features/memory_details/memory_details_controller.dart';
import '../../features/memory_details/memory_details_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/archived_screen.dart';
import '../../features/profile/change_password_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/privacy_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/save/save_controller.dart';
import '../../features/save/screens/add_link_screen.dart';
import '../../features/save/screens/add_note_screen.dart';
import '../../features/search/search_controller.dart';
import '../../features/search/search_screen.dart';
import '../../features/splash/splash_screen.dart';
import 'app_routes.dart';

/// Every screen and the controllers it needs.
///
/// A "binding" creates a screen's controllers when the screen opens and
/// removes them when it closes, so we never keep unused controllers alive.
class AppPages {
  AppPages._();

  static final List<GetPage> pages = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.signup, page: () => const SignupScreen()),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => const MainScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MainController());
        Get.lazyPut(() => LibraryController());
      }),
    ),
    GetPage(
      name: AppRoutes.addLink,
      page: () => const AddLinkScreen(),
      binding: _saveBinding,
    ),
    GetPage(
      name: AppRoutes.addNote,
      page: () => const AddNoteScreen(),
      binding: _saveBinding,
    ),
    GetPage(
      name: AppRoutes.memoryDetails,
      page: () => const MemoryDetailsScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => MemoryDetailsController()),
      ),
    ),
    GetPage(name: AppRoutes.editMemory, page: () => const EditMemoryScreen()),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => MemorySearchController()),
      ),
    ),
    GetPage(name: AppRoutes.editProfile, page: () => const EditProfileScreen()),
    GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordScreen(),
    ),
    GetPage(name: AppRoutes.privacy, page: () => const PrivacyScreen()),
    GetPage(name: AppRoutes.archived, page: () => const ArchivedScreen()),
  ];

  static final Bindings _saveBinding = BindingsBuilder(
    () => Get.lazyPut(() => SaveController()),
  );
}
