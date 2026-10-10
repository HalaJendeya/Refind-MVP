import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Starts Firebase when the app opens.
///
/// `DefaultFirebaseOptions.currentPlatform` (made by `flutterfire configure`)
/// picks the right project settings for Android or iOS, so no
/// GoogleService-Info.plist is needed for Dart code to start Firebase.
class FirebaseService {
  FirebaseService._();

  /// Returns null on success, or a short message describing what went wrong.
  static Future<String?> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return null;
    } catch (error) {
      return 'Firebase could not start. Check your Firebase configuration files.\n\n$error';
    }
  }
}
