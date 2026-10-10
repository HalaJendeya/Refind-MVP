import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Refind/data/models/memory_model.dart';
import 'package:Refind/shared/widgets/memory_card.dart';
import 'package:Refind/shared/widgets/state_views.dart';

void main() {
  setUpAll(() {
    // Tests have no internet; fall back to the default font.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final now = DateTime.now();
  final memory = Memory(
    id: '1',
    userId: 'u',
    title: 'Flutter Animation Tutorial',
    type: MemoryType.link,
    sourceUrl: 'https://youtube.com/watch',
    createdAt: now,
    updatedAt: now,
  );

  testWidgets(
    'MemoryCard shows title, type badge and website, and is tappable',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemoryCard(memory: memory, onTap: () => tapped = true),
          ),
        ),
      );

      expect(find.text('Flutter Animation Tutorial'), findsOneWidget);
      expect(find.text('LINK'), findsOneWidget);
      expect(find.text('youtube.com'), findsOneWidget);

      await tester.tap(find.byType(MemoryCard));
      expect(tapped, isTrue);
    },
  );

  testWidgets('EmptyState shows its message and runs the button action', (
    tester,
  ) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.bookmark_border,
            title: 'Your Library is empty',
            message: 'Anything you save will show up here.',
            actionLabel: 'Save Something',
            onAction: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Your Library is empty'), findsOneWidget);
    await tester.tap(find.text('Save Something'));
    expect(pressed, isTrue);
  });

  testWidgets('ErrorState has a Try Again button', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorState(
            message: 'Could not load',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Try Again'));
    expect(retried, isTrue);
  });
}
