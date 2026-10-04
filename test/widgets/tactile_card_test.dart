import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:konfide/core/models/question.dart';
import 'package:konfide/core/services/storage_service.dart';
import 'package:konfide/core/theme/app_theme.dart';
import 'package:konfide/features/cards/widgets/tactile_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  testWidgets('TactileCard displays text and triggers actions',
      (WidgetTester tester) async {
    const question = Question(
      id: 'q_test_1',
      text: 'What place on earth feels most like home to you?',
      deckId: 'getting_to_know_you',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(AppThemePreset.candlelight),
        home: const Scaffold(
          body: Center(
            child: TactileCard(
              question: question,
              deckTitle: 'Getting to Know You',
              accentColor: Color(0xFFD97736),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify question text appears
    expect(find.text('What place on earth feels most like home to you?'),
        findsOneWidget);

    // Verify deck title badge appears
    expect(find.text('Getting to Know You'), findsOneWidget);

    // Verify Favorite button is present
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);

    // Verify Note icon is present
    expect(find.byIcon(Icons.note_add_outlined), findsOneWidget);

    // Verify Share icon is present
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);

    // Tap the Favorite button
    await tester.tap(find.byIcon(Icons.star_outline_rounded));
    await tester.pumpAndSettle();

    // Verify star is now filled
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_outline_rounded), findsNothing);

    // Tap again to un-favorite
    await tester.tap(find.byIcon(Icons.star_rounded));
    await tester.pumpAndSettle();

    // Verify star is back to outline
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('TactileCard delete button shows confirmation and calls onDeleteQuestion',
      (WidgetTester tester) async {
    bool deleted = false;
    const question = Question(
      id: 'q_test_del',
      text: 'Question to delete',
      deckId: 'getting_to_know_you',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(AppThemePreset.candlelight),
        home: Scaffold(
          body: Center(
            child: TactileCard(
              question: question,
              deckTitle: 'Getting to Know You',
              accentColor: const Color(0xFFD97736),
              onDeleteQuestion: () {
                deleted = true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap delete icon
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    // Verify dialog
    expect(find.text('Delete Question?'), findsOneWidget);
    expect(find.text('This question will be permanently deleted from this pack.'), findsOneWidget);

    // Tap Delete Question
    await tester.tap(find.widgetWithText(FilledButton, 'Delete Question'));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });
}
