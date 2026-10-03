import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konfide/core/models/deck.dart';
import 'package:konfide/core/models/question.dart';
import 'package:konfide/core/services/preset_deck_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Question and Deck domain tests', () {
    test('Question serialization', () {
      const q = Question(
        id: 'test_q_1',
        text: 'What brings you peace?',
        deckId: 'test_deck',
        isCustom: false,
      );

      final json = q.toJson();
      final restored = Question.fromJson(json);

      expect(restored.id, q.id);
      expect(restored.text, q.text);
      expect(restored.deckId, q.deckId);
      expect(restored.isCustom, q.isCustom);
      expect(restored, q);
    });

    test('QuestionDeck filters hidden questions', () {
      const deck = QuestionDeck(
        id: 'test_deck',
        title: 'Test Deck',
        description: 'Description',
        icon: Icons.chat_bubble_outline,
        accentColor: Colors.brown,
        questions: [
          Question(id: 'q1', text: 'Text 1', deckId: 'test_deck'),
          Question(id: 'q2', text: 'Text 2', deckId: 'test_deck'),
          Question(id: 'q3', text: 'Text 3', deckId: 'test_deck'),
        ],
      );

      final visible = deck.visibleQuestions({'q2'});
      expect(visible.length, 2);
      expect(visible.map((q) => q.id), ['q1', 'q3']);
    });

    test('Curated decks loaded from assets has 6 rich packs with > 300 questions total', () async {
      final decks = await PresetDeckService.loadAllPresetDecks();
      expect(decks.length, 6);

      int totalQuestions = 0;
      for (final deck in decks) {
        expect(deck.questions.length, greaterThanOrEqualTo(45),
            reason: '${deck.title} should have at least 45 questions');
        expect(deck.version, greaterThanOrEqualTo(1));
        expect(deck.isCustom, isFalse);
        totalQuestions += deck.questions.length;
      }

      expect(totalQuestions, greaterThanOrEqualTo(300));
    });
  });
}
