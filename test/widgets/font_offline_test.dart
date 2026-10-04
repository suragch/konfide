import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konfide/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app theme works completely offline with allowRuntimeFetching disabled',
      (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    for (final preset in AppThemePreset.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.buildTheme(preset),
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Title Newsreader'),
            ),
            body: Center(
              child: Column(
                children: [
                  Text('Headline', style: GoogleFonts.newsreader()),
                  Text('Body', style: GoogleFonts.plusJakartaSans()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Title Newsreader'), findsOneWidget);
      expect(find.text('Headline'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    }
  });
}
