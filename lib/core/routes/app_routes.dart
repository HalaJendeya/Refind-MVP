/// Names of all screens. Use these with `Get.toNamed(AppRoutes.login)`.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';

  /// The main app: bottom navigation with Home, Library, Favorites, Profile.
  static const main = '/main';

  static const addLink = '/save/link';
  static const addNote = '/save/note';

  static const memoryDetails = '/memory';
  static const editMemory = '/memory/edit';
  static const search = '/search';

  static const editProfile = '/profile/edit';
  static const settings = '/settings';
  static const changePassword = '/settings/password';
  static const privacy = '/settings/privacy';
  static const archived = '/archived';
}
