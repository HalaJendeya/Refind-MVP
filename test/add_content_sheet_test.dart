import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refind/features/save/widgets/add_content_sheet.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: showAddContentSheet,
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('Add Content shows all four options', (tester) async {
    await openSheet(tester);

    expect(find.text('Add Link'), findsOneWidget);
    expect(find.text('Add Image'), findsOneWidget);
    expect(find.text('Add Document'), findsOneWidget);
    expect(find.text('Add Note'), findsOneWidget);
  });

  testWidgets('Add Image shows a coming soon message', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Add Image'));
    await tester.pumpAndSettle();

    expect(find.text('Image uploads are coming soon'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Image uploads are coming soon'), findsNothing);
  });

  testWidgets('Add Document shows a coming soon message', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Add Document'));
    await tester.pumpAndSettle();

    expect(find.text('Document uploads are coming soon'), findsOneWidget);
  });
}
