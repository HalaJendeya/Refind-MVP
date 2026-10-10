import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/screen_header.dart';

/// Plain-language description of how ReFind stores data in this MVP.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _points = [
    (
      'Your memories are private',
      'Everything you save is stored in your own area of Firebase and is protected by '
          'security rules so only your account can read it.',
    ),
    (
      'What we store',
      'Your email, display name, and the links, notes, images and documents you choose to save.',
    ),
    (
      'No automatic analysis',
      'This version does not read, summarise or analyse your content with AI. '
          'Search simply matches the words you type against what you saved.',
    ),
    (
      'Deleting',
      'Deleting a memory removes it (and its uploaded file) from your Library.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenHeader(title: 'Privacy Information'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            for (final point in _points) ...[
              Text(
                point.$1,
                style: AppTheme.text(size: 18, weight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                point.$2,
                style: AppTheme.text(
                  size: 15,
                  color: AppColors.textMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
