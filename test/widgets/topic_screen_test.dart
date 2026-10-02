import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
}
