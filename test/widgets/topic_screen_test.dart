import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:konfide/core/models/question.dart';
import 'package:konfide/core/services/storage_service.dart';
import 'package:konfide/core/theme/app_theme.dart';
import 'package:konfide/features/topics/topic_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  testWidgets('Clicking "for General" opens companion switch sheet',
      (WidgetTester tester) async {
    // Set a narrow phone screen size (360x640)
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(AppThemePreset.candlelight),
        home: TopicScreen(onThemeChanged: (_) {}),
      ),
    );

    await tester.pumpAndSettle();

    // Verify "for General" button exists in Conversation Packs header
    final forGeneralFinder = find.text('for General');
    expect(forGeneralFinder, findsWidgets);

    // Tap "for General"
    await tester.tap(forGeneralFinder.first);
    await tester.pumpAndSettle();

    // Verify the companion sheet is shown
    expect(find.text('Conversations With...'), findsOneWidget);
    expect(find.text('Add Person'), findsOneWidget);
  });

  testWidgets('Clicking star on Daily Spark toggles favorite',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(AppThemePreset.candlelight),
        home: TopicScreen(onThemeChanged: (_) {}),
      ),
    );

    await tester.pumpAndSettle();

    // Verify DAILY SPARK card is shown
    expect(find.text('DAILY SPARK'), findsOneWidget);

    // Find star icon button within Daily Spark
    final saveButton = find.byTooltip('Save question');
    expect(saveButton, findsOneWidget);

    // Tap the star button
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Check that storage has favorite and filled star is displayed
    expect(StorageService.instance.getFavorites().isNotEmpty, isTrue);
    expect(find.byTooltip('Remove from saved'), findsOneWidget);
  });

  testWidgets('CompanionSheet does not overflow on a narrow phone screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568); // Very narrow screen (e.g. iPhone SE 1st gen)
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(AppThemePreset.candlelight),
        home: TopicScreen(onThemeChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    // Open companion sheet
    await tester.tap(find.text('for General').first);
    await tester.pumpAndSettle();

    // Verify no overflow exceptions occurred
    expect(tester.takeException(), isNull);
    expect(find.text('Conversations With...'), findsOneWidget);
  });

  testWidgets('AppBar three dot menu opens and displays all action items',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(AppThemePreset.candlelight),
        home: TopicScreen(onThemeChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    // Verify three-dot menu button exists in AppBar
    final menuButton = find.byTooltip('Menu');
    expect(menuButton, findsOneWidget);

    // Tap the three-dot menu
    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    // Verify all menu items appear
    expect(find.text('Saved Questions'), findsOneWidget);
    expect(find.text('Create Pack'), findsOneWidget);
    expect(find.text('Import Pack'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Preset topic card menu displays Customize, Reset progress, and Delete Pack',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(AppThemePreset.candlelight),
        home: TopicScreen(onThemeChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    // Find the more_horiz icon on the first topic card
    final cardMenuFinder = find.byIcon(Icons.more_horiz_rounded);
    expect(cardMenuFinder, findsWidgets);

    // Tap the menu on the first curated deck card
    await tester.tap(cardMenuFinder.first);
    await tester.pumpAndSettle();

    // Verify menu items
    expect(find.text('Customize'), findsOneWidget);
    expect(find.text('Restore to Original'), findsNothing);
    expect(find.text('Reset progress for General'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.text('Delete Pack'), findsOneWidget);
    // Ensure old duplicate & hide are gone
    expect(find.text('Duplicate & Customize'), findsNothing);
    expect(find.text('Hide this pack'), findsNothing);
  });

  testWidgets('Tapping Customize on preset card opens Customize Pack screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(AppThemePreset.candlelight),
        home: TopicScreen(onThemeChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    // Tap popup menu on the first curated deck
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();

    // Tap Customize
    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle();

    // Should open CustomDeckScreen with 'Customize Pack'
    expect(find.text('Customize Pack'), findsOneWidget);
  });

  testWidgets('Deleting a preset pack removes it permanently',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(AppThemePreset.candlelight),
        home: TopicScreen(onThemeChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    final firstPresetTitle = StorageService.instance.getPresetDecks().first.title;
    expect(find.text(firstPresetTitle), findsOneWidget);

    // Tap popup menu on the first curated deck
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();

    // Tap Delete Pack
    await tester.tap(find.text('Delete Pack'));
    await tester.pumpAndSettle();

    // Confirm dialog is shown
    expect(find.text('Delete "$firstPresetTitle"?'), findsOneWidget);
    expect(
      find.text('This will permanently delete this pack and its questions.'),
      findsOneWidget,
    );

    // Tap Delete button in the dialog
    final deleteButton = find.widgetWithText(FilledButton, 'Delete');
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Pack is removed from the visible list
    expect(find.text(firstPresetTitle), findsNothing);
    expect(find.text('Deleted "$firstPresetTitle" pack'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
  });

  group('Daily Spark selection', () {
    final sampleQuestions = List.generate(
      100,
      (i) => Question(
        id: 'q_$i',
        text: 'Question $i',
        deckId: 'deck_1',
      ),
    );

    test('returns consistent question on the same day', () {
      final date = DateTime(2026, 10, 10, 8, 30);
      final laterDate = DateTime(2026, 10, 10, 23, 45);

      final q1 = TopicScreen.computeDailySpark(sampleQuestions, date: date);
      final q2 = TopicScreen.computeDailySpark(sampleQuestions, date: laterDate);

      expect(q1.id, equals(q2.id));
    });

    test('picks pseudo-random questions across days rather than sequential', () {
      final day1 = DateTime(2026, 10, 1);
      final day2 = DateTime(2026, 10, 2);
      final day3 = DateTime(2026, 10, 3);

      final q1 = TopicScreen.computeDailySpark(sampleQuestions, date: day1);
      final q2 = TopicScreen.computeDailySpark(sampleQuestions, date: day2);
      final q3 = TopicScreen.computeDailySpark(sampleQuestions, date: day3);

      final idx1 = int.parse(q1.id.replaceFirst('q_', ''));
      final idx2 = int.parse(q2.id.replaceFirst('q_', ''));
      final idx3 = int.parse(q3.id.replaceFirst('q_', ''));

      // Indices should not simply be idx1 + 1 and idx2 + 1
      expect(idx2 == idx1 + 1 && idx3 == idx2 + 1, isFalse);
    });

    test('avoids consecutive repeats when multiple questions are available', () {
      DateTime current = DateTime(2026, 1, 1);
      String? previousId;

      for (int i = 0; i < 365; i++) {
        final spark = TopicScreen.computeDailySpark(sampleQuestions, date: current);
        if (previousId != null) {
          expect(spark.id, isNot(equals(previousId)));
        }
        previousId = spark.id;
        current = current.add(const Duration(days: 1));
      }
    });

    test('falls back to default question when question list is empty', () {
      final fallback = TopicScreen.computeDailySpark([]);
      expect(fallback.id, equals('spark_default'));
      expect(fallback.text, contains('deeply grateful'));
    });
  });
}

