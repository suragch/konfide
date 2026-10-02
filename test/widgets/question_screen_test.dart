import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:konfide/core/models/deck.dart';
import 'package:konfide/core/models/question.dart';
import 'package:konfide/core/services/storage_service.dart';
import 'package:konfide/core/theme/app_theme.dart';
import 'package:konfide/features/questions/question_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuestionDeck testDeck;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();

    testDeck = const QuestionDeck(
      id: 'test_deck_1',
      title: 'Deep Connections',
      subtitle: 'Meaningful conversations',
      description: 'Deck for deep talks',
      icon: Icons.favorite_outline,
      accentColor: Color(0xFFD97736),
      questions: [
        Question(id: 'q1', text: 'First question text?', deckId: 'test_deck_1'),
        Question(id: 'q2', text: 'Second question text?', deckId: 'test_deck_1'),
        Question(id: 'q3', text: 'Third question text?', deckId: 'test_deck_1'),
      ],
    );
    await StorageService.instance.saveCustomDeck(testDeck);
  });

  testWidgets('QuestionScreen UI updates: single with Name, no swipe hint, no shuffle button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(AppThemePreset.candlelight),
        home: QuestionScreen(deck: testDeck),
      ),
    );
    await tester.pumpAndSettle();

    // 1. "with General" appears only once on screen (in the AppBar)
    expect(find.text('with General'), findsOneWidget);

    // 2. "Swipe or tap arrows" text is removed
    expect(find.text('Swipe or tap arrows'), findsNothing);

    // 3. Shuffle button is removed
    expect(find.byIcon(Icons.shuffle_rounded), findsNothing);
    expect(find.byTooltip('Shuffle remaining'), findsNothing);

    // 4. Initial card is Card 1
    expect(find.text('Card 1 of 3'), findsOneWidget);
    expect(find.text('First question text?'), findsOneWidget);
  });

  testWidgets('Resetting progress for person resets immediately to Card 1 in the cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(AppThemePreset.candlelight),
        home: QuestionScreen(deck: testDeck),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Card 1 of 3'), findsOneWidget);
    expect(find.text('First question text?'), findsOneWidget);

    // Advance to Card 2 using the next arrow button
    final nextButton = find.byTooltip('Next question');
    expect(nextButton, findsOneWidget);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Verify on Card 2
    expect(find.text('Card 2 of 3'), findsOneWidget);
    expect(find.text('Second question text?'), findsOneWidget);

    // Advance to Card 3
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Verify on Card 3
    expect(find.text('Card 3 of 3'), findsOneWidget);
    expect(find.text('Third question text?'), findsOneWidget);

    // Open more menu
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    // Tap "Reset progress for this person"
    await tester.tap(find.text('Reset progress for this person'));
    await tester.pumpAndSettle();

    // Confirm dialog appears
    expect(find.text('Reset Progress?'), findsOneWidget);

    // Tap 'Reset' button in dialog
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    // Verify IMMEDIATELY back to Card 1
    expect(find.text('Card 1 of 3'), findsOneWidget);
    expect(find.text('First question text?'), findsOneWidget);
  });
}
