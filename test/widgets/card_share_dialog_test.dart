import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konfide/core/models/question.dart';
import 'package:konfide/features/cards/widgets/card_share_dialog.dart';

void main() {
  testWidgets('CardShareDialog renders without overflow on narrow phone',
      (WidgetTester tester) async {
    // 320px width (iPhone SE 1st gen / narrow Android)
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const question = Question(
      id: 'test_share_q',
      text: 'What is a memory from your childhood that still brings a warm smile to your face today?',
      deckId: 'test_deck',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  CardShareDialog.show(
                    context,
                    question: question,
                    deckTitle: 'Deep & Meaningful Conversations',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Share Card Image'), findsOneWidget);
    expect(find.text('Share Text'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
