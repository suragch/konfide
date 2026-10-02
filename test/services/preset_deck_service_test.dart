import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konfide/core/services/preset_deck_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PresetDeckService tests', () {
    test('parses valid preset JSON with strings and metadata', () {
      const jsonStr = '''
      {
        "id": "sample_preset",
        "version": 2,
        "title": "Sample Title",
        "subtitle": "Sample Subtitle",
        "description": "Sample Description",
        "icon": "sparkles",
        "accentColor": "#FF5722",
        "questions": [
          "First question?",
          "Second question?"
        ]
      }
      ''';

      final deck = PresetDeckService.parsePresetDeckJson(jsonStr);

      expect(deck.id, 'sample_preset');
      expect(deck.version, 2);
      expect(deck.title, 'Sample Title');
      expect(deck.subtitle, 'Sample Subtitle');
      expect(deck.description, 'Sample Description');
      expect(deck.icon, Icons.auto_awesome);
      expect(deck.accentColor, const Color(0xFFFF5722));
      expect(deck.isCustom, isFalse);
      expect(deck.questions.length, 2);
      expect(deck.questions[0].id, 'sample_preset_1');
      expect(deck.questions[0].text, 'First question?');
      expect(deck.questions[1].id, 'sample_preset_2');
      expect(deck.questions[1].text, 'Second question?');
    });

    test('parses preset JSON with structured question objects and custom IDs', () {
      const jsonStr = '''
      {
        "id": "structured_preset",
        "version": 1,
        "title": "Structured Deck",
        "questions": [
          {"id": "custom_q_1", "text": "Structured question 1?"},
          {"text": "Structured question 2?"}
        ]
      }
      ''';

      final deck = PresetDeckService.parsePresetDeckJson(jsonStr);

      expect(deck.id, 'structured_preset');
      expect(deck.questions.length, 2);
      expect(deck.questions[0].id, 'custom_q_1');
      expect(deck.questions[0].text, 'Structured question 1?');
      expect(deck.questions[1].id, 'structured_preset_2');
      expect(deck.questions[1].text, 'Structured question 2?');
    });

    test('loads all 6 bundled preset decks from assets/decks', () async {
      final decks = await PresetDeckService.loadAllPresetDecks();

      expect(decks.length, 6);
      final ids = decks.map((d) => d.id).toSet();
      expect(ids, containsAll([
        'getting_to_know_you',
        'friends_and_family',
        'couples_romance',
        'family_generations',
        'thought_provoking',
        'deeply_personal',
      ]));

      for (final deck in decks) {
        expect(deck.version, greaterThanOrEqualTo(1));
        expect(deck.title, isNotEmpty);
        expect(deck.questions, isNotEmpty);
        expect(deck.isCustom, isFalse);
      }
    });

    test('throws FormatException for invalid preset JSON', () {
      expect(() => PresetDeckService.parsePresetDeckJson(''), throwsA(isA<FormatException>()));
      expect(() => PresetDeckService.parsePresetDeckJson('["not an object"]'), throwsA(isA<FormatException>()));
    });
  });
}
