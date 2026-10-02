import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konfide/core/models/deck.dart';
import 'package:konfide/core/models/question.dart';
import 'package:konfide/core/services/deck_exchange_service.dart';

void main() {
  group('DeckExchangeService tests', () {
    test('exportDeckToJson produces valid formatted JSON', () {
      const deck = QuestionDeck(
        id: 'deck_sample',
        title: 'Campfire Stories',
        subtitle: 'Night vibes',
        description: 'Deep questions around the fire.',
        icon: Icons.local_fire_department,
        accentColor: Color(0xFFC2410C),
        questions: [
          Question(id: 'q1', text: 'Scariest ghost story?', deckId: 'deck_sample'),
          Question(id: 'q2', text: 'Favorite night sky memory?', deckId: 'deck_sample'),
        ],
      );

      final jsonString = DeckExchangeService.exportDeckToJson(deck);
      expect(jsonString.contains('"format": "konfide_deck"'), isTrue);
      expect(jsonString.contains('"title": "Campfire Stories"'), isTrue);
      expect(jsonString.contains('"Scariest ghost story?"'), isTrue);
      expect(jsonString.contains('"Favorite night sky memory?"'), isTrue);
    });

    test('parseAndValidateDeckJson successfully parses string question arrays', () {
      const validJson = '''
      {
        "format": "konfide_deck",
        "version": 1,
        "title": "Roadtrip Confessions",
        "subtitle": "Highway & Backroads",
        "description": "Fun questions for long drives.",
        "icon": "explore",
        "accentColor": "#10B981",
        "questions": [
          "What is the most scenic road you've ever driven on?",
          "If we could take an unplanned detour right now, where would we go?"
        ]
      }
      ''';

      final deck = DeckExchangeService.parseAndValidateDeckJson(validJson);
      expect(deck.title, 'Roadtrip Confessions');
      expect(deck.subtitle, 'Highway & Backroads');
      expect(deck.description, 'Fun questions for long drives.');
      expect(deck.icon, Icons.explore_outlined);
      expect(deck.accentColor, const Color(0xFF10B981));
      expect(deck.questions.length, 2);
      expect(deck.questions[0].text, "What is the most scenic road you've ever driven on?");
      expect(deck.questions[1].text, "If we could take an unplanned detour right now, where would we go?");
      expect(deck.isCustom, isTrue);
    });

    test('parseAndValidateDeckJson parses structured question objects', () {
      const objectJson = '''
      {
        "title": "Object Questions",
        "questions": [
          {"text": "First question"},
          {"question": "Second question"},
          {"q": "Third question"}
        ]
      }
      ''';

      final deck = DeckExchangeService.parseAndValidateDeckJson(objectJson);
      expect(deck.title, 'Object Questions');
      expect(deck.questions.length, 3);
      expect(deck.questions[0].text, 'First question');
      expect(deck.questions[1].text, 'Second question');
      expect(deck.questions[2].text, 'Third question');
    });

    test('parseAndValidateDeckJson throws FormatException for invalid inputs', () {
      // Empty input
      expect(
        () => DeckExchangeService.parseAndValidateDeckJson(''),
        throwsA(isA<FormatException>()),
      );

      // Malformed JSON
      expect(
        () => DeckExchangeService.parseAndValidateDeckJson('{invalid json}'),
        throwsA(isA<FormatException>()),
      );

      // Missing title
      expect(
        () => DeckExchangeService.parseAndValidateDeckJson('{"questions": ["Q1"]}'),
        throwsA(isA<FormatException>()),
      );

      // Missing questions
      expect(
        () => DeckExchangeService.parseAndValidateDeckJson('{"title": "My Deck"}'),
        throwsA(isA<FormatException>()),
      );

      // Empty questions list
      expect(
        () => DeckExchangeService.parseAndValidateDeckJson('{"title": "My Deck", "questions": []}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('round-trip export and import preserves content', () {
      const original = QuestionDeck(
        id: 'deck_orig',
        title: 'Deep Soul',
        subtitle: 'Intimacy',
        description: 'Vulnerable thoughts.',
        icon: Icons.favorite_outline,
        accentColor: Color(0xFFE11D48),
        questions: [
          Question(id: 'q1', text: 'When did you last cry?', deckId: 'deck_orig'),
          Question(id: 'q2', text: 'What makes you feel loved?', deckId: 'deck_orig'),
        ],
      );

      final json = DeckExchangeService.exportDeckToJson(original);
      final imported = DeckExchangeService.parseAndValidateDeckJson(json);

      expect(imported.title, original.title);
      expect(imported.subtitle, original.subtitle);
      expect(imported.description, original.description);
      expect(imported.questions.length, original.questions.length);
      expect(imported.questions[0].text, original.questions[0].text);
      expect(imported.questions[1].text, original.questions[1].text);
    });
  });
}
