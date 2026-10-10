import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../onboarding/onboarding_storage.dart';

/// First screen. Shows the logo for a moment, then decides where to go:
///   not seen onboarding -> Onboarding
///   logged in           -> Main app
///   otherwise           -> Login
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final seenOnboarding = await OnboardingStorage.isDone();
    final loggedIn = Get.find<AuthController>().isLoggedIn;

    if (loggedIn) {
      Get.offAllNamed(AppRoutes.main);
    } else if (!seenOnboarding) {
      Get.offAllNamed(AppRoutes.onboarding);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD046E4), AppColors.primary],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'R',
                style: AppTheme.text(
                  size: 52,
                  weight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ReFind',
              style: AppTheme.text(
                size: 40,
                weight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PERSONAL RECALL ASSISTANT',
              style: AppTheme.text(
                size: 13,
                color: const Color(0xCCFFFFFF),
              ).copyWith(letterSpacing: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
