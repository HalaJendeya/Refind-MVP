import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/services/app_binding.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseError = await FirebaseService.initialize();
  if (firebaseError != null) {
    // Without Firebase nothing in the app can work, so explain it clearly.
    runApp(_FirebaseErrorApp(message: firebaseError));
    return;
  }

  runApp(const ReFindApp());
}

class ReFindApp extends StatelessWidget {
  const ReFindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ReFind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialBinding: AppBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}

class _FirebaseErrorApp extends StatelessWidget {
  final String message;

  const _FirebaseErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: SelectableText(message)),
          ),
        ),
      ),
    );
  }
}
