import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_buttons.dart';
import 'onboarding_storage.dart';

/// The two onboarding pages from the Figma design.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.bookmark_border,
      smallIcons: [Icons.link, Icons.image_outlined],
      title: 'Save Anything',
      text:
          'Easily save links, videos, social posts, screenshots, documents, '
          'and other useful content from anywhere.',
    ),
    _OnboardingPage(
      icon: Icons.search,
      smallIcons: [],
      title: 'Find It Later',
      text:
          "Don't worry about folders or filenames. Just search naturally for "
          'what you remember when you need it.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingStorage.markDone();
    Get.offAllNamed(AppRoutes.login);
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextLinkButton(
                  label: 'Skip',
                  onPressed: _finish,
                  color: AppColors.textMedium,
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _page = index),
                  children: _pages,
                ),
              ),
              _Dots(count: _pages.length, current: _page),
              const SizedBox(height: 28),
              PrimaryButton(
                label: isLast ? 'Get Started' : 'Continue',
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final List<IconData> smallIcons;
  final String title;
  final String text;

  const _OnboardingPage({
    required this.icon,
    required this.smallIcons,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _illustration(),
        const SizedBox(height: 36),
        Text(title, style: AppTheme.text(size: 28, weight: FontWeight.w700)),
        const SizedBox(height: 16),
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppTheme.text(
            size: 16,
            color: AppColors.textMedium,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _illustration() {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF1F3F2),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            margin: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFF9CCFB),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.white, size: 44),
          ),
          if (smallIcons.length > 1) ...[
            Positioned(
              top: 24,
              right: 22,
              child: _SmallBadge(
                icon: smallIcons[0],
                color: const Color(0xFF3B82F6),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 20,
              child: _SmallBadge(
                icon: smallIcons[1],
                color: const Color(0xFFEC4899),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SmallBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int current;

  const _Dots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
