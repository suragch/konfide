import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:konfide/core/services/storage_service.dart';
import 'package:konfide/core/theme/app_theme.dart';
import 'package:konfide/features/custom_decks/import_deck_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.init();
  });

  testWidgets('ImportDeckSheet parses JSON and imports pack',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(AppThemePreset.candlelight),
        home: const Scaffold(
          body: ImportDeckSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial elements
    expect(find.text('Import Question Pack'), findsOneWidget);
    expect(find.text('Pick .json File'), findsOneWidget);
    expect(find.text('Paste JSON'), findsOneWidget);

    // Expand the raw JSON text field
    await tester.tap(find.text('Or type / edit raw JSON'));
    await tester.pumpAndSettle();

    // Enter a valid pack JSON
    const validJson = '''
    {
      "format": "konfide_deck",
      "version": 1,
      "title": "Weekend Escapes",
      "subtitle": "Getaway Talk",
      "description": "Fun weekend conversation.",
      "icon": "explore",
      "accentColor": "#10B981",
      "questions": [
        "Where is your favorite weekend getaway?",
        "What is your dream cabin in the woods like?"
      ]
    }
    ''';

    await tester.enterText(find.byType(TextField), validJson);
    await tester.pumpAndSettle();

    // Verify preview card appears
    expect(find.text('Pack Preview'), findsOneWidget);
    expect(find.text('Weekend Escapes'), findsOneWidget);
    expect(find.text('Getaway Talk'), findsOneWidget);
    expect(find.text('2 questions included'), findsOneWidget);

    // Tap the import button
    final importButton = find.text('Import "Weekend Escapes"');
    expect(importButton, findsOneWidget);
    await tester.ensureVisible(importButton);
    await tester.tap(importButton);
    await tester.pumpAndSettle();

    // Verify deck was imported into storage
    final customDecks = storage.getCustomDecks();
    expect(customDecks.any((d) => d.title == 'Weekend Escapes'), isTrue);
    expect(customDecks.firstWhere((d) => d.title == 'Weekend Escapes').questions.length, 2);
  });
}
