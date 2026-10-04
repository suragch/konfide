import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:konfide/core/models/companion.dart';
import 'package:konfide/core/models/deck.dart';
import 'package:konfide/core/models/question.dart';
import 'package:konfide/core/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.init();
  });

  group('StorageService tests', () {
    test('default companion exists on launch', () {
      final companions = storage.getCompanions();
      expect(companions.length, 1);
      expect(companions.first.id, Companion.defaultId);
      expect(storage.getActiveCompanionId(), Companion.defaultId);
    });

    test('add custom companions and switch active', () async {
      final joe = Companion(
        id: 'comp_joe',
        name: 'Joe',
        createdAt: DateTime.now(),
      );
      final mary = Companion(
        id: 'comp_mary',
        name: 'Mary',
        createdAt: DateTime.now(),
      );

      await storage.addCompanion(joe);
      await storage.addCompanion(mary);

      expect(storage.getCompanions().length, 3);

      await storage.setActiveCompanionId(joe.id);
      expect(storage.getActiveCompanion().name, 'Joe');

      await storage.setActiveCompanionId(mary.id);
      expect(storage.getActiveCompanion().name, 'Mary');
    });

    test('per-companion progress isolation between Joe and Mary', () async {
      const deckId = 'getting_to_know_you';

      // Record progress with Joe: Card index 5, seen q1..q5
      await storage.markQuestionSeen(
        companionId: 'comp_joe',
        deckId: deckId,
        questionId: 'q1',
        newIndex: 1,
      );
      await storage.markQuestionSeen(
        companionId: 'comp_joe',
        deckId: deckId,
        questionId: 'q2',
        newIndex: 2,
      );

      // Verify Mary starts fresh at 0
      final maryProgress = storage.getProgress('comp_mary', deckId);
      expect(maryProgress.currentIndex, 0);
      expect(maryProgress.seenQuestionIds, isEmpty);

      // Record progress with Mary: Card index 1, seen q10
      await storage.markQuestionSeen(
        companionId: 'comp_mary',
        deckId: deckId,
        questionId: 'q10',
        newIndex: 1,
      );

      // Verify Joe's progress is preserved
      final joeProgress = storage.getProgress('comp_joe', deckId);
      expect(joeProgress.currentIndex, 2);
      expect(joeProgress.seenQuestionIds, ['q1', 'q2']);

      // Mary's progress remains distinct
      final maryProgressUpdated = storage.getProgress('comp_mary', deckId);
      expect(maryProgressUpdated.currentIndex, 1);
      expect(maryProgressUpdated.seenQuestionIds, ['q10']);
    });

    test('deleteQuestion removes question from deck and favorites/notes', () async {
      final deck = storage.getPresetDecks().first;
      final qId = deck.questions.first.id;

      await storage.toggleFavorite(qId);
      await storage.saveNote(qId, 'Nice memory');
      expect(storage.isFavorite(qId), isTrue);

      await storage.deleteQuestion(qId);

      final updatedDeck = storage.getPresetDecks().firstWhere((d) => d.id == deck.id);
      expect(updatedDeck.questions.any((q) => q.id == qId), isFalse);
      expect(storage.isFavorite(qId), isFalse);
      expect(storage.getNote(qId), isNull);
    });

    test('favorites and personal reflection notes', () async {
      expect(storage.isFavorite('q_fav'), isFalse);

      await storage.toggleFavorite('q_fav');
      expect(storage.isFavorite('q_fav'), isTrue);

      await storage.saveNote('q_fav', 'Joe told an amazing story here');
      expect(storage.getNote('q_fav'), 'Joe told an amazing story here');

      await storage.toggleFavorite('q_fav');
      expect(storage.isFavorite('q_fav'), isFalse);
    });

    test('custom decks persistence and deletion', () async {
      expect(storage.getCustomDecks(), isEmpty);

      const deck = QuestionDeck(
        id: 'deck_custom_1',
        title: 'Roadtrip Questions',
        description: 'Questions to ask on long drives',
        icon: Icons.explore_outlined,
        accentColor: Color(0xFFD97736),
        isCustom: true,
        questions: [
          Question(id: 'q_c1', text: 'Where to next?', deckId: 'deck_custom_1', isCustom: true),
        ],
      );

      await storage.saveCustomDeck(deck);
      expect(storage.getCustomDecks().length, 1);
      expect(storage.getCustomDecks().first.title, 'Roadtrip Questions');

      await storage.deleteCustomDeck('deck_custom_1');
      expect(storage.getCustomDecks(), isEmpty);
    });

    test('simple user settings persist to shared preferences', () async {
      expect(storage.getThemePreset(), 'candlelight');
      await storage.setThemePreset('ember');
      expect(storage.getThemePreset(), 'ember');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('konfide_theme_preset'), 'ember');
    });

    test('deleting companion cleans up progress', () async {
      final companion = Companion(
        id: 'comp_temp',
        name: 'Temp Person',
        createdAt: DateTime.now(),
      );
      await storage.addCompanion(companion);
      await storage.markQuestionSeen(
        companionId: 'comp_temp',
        deckId: 'getting_to_know_you',
        questionId: 'getting_to_know_you_1',
        newIndex: 1,
      );

      expect(storage.getProgress('comp_temp', 'getting_to_know_you').currentIndex, 1);

      await storage.deleteCompanion('comp_temp');
      expect(storage.getCompanions().any((c) => c.id == 'comp_temp'), isFalse);
      expect(storage.getProgress('comp_temp', 'getting_to_know_you').currentIndex, 0);
    });

    test('preset decks are loaded and can be duplicated', () async {
      final presetDecks = storage.getPresetDecks();
      expect(presetDecks.length, 6);
      expect(presetDecks.first.id, 'getting_to_know_you');

      // Duplicate preset deck into custom pack
      final duplicated = await storage.duplicateDeck(presetDecks.first);
      expect(duplicated.isCustom, isTrue);
      expect(duplicated.title, 'Getting to Know You (Copy)');
      expect(duplicated.questions.length, presetDecks.first.questions.length);
      expect(storage.getCustomDecks().length, 1);

      // Clean up
      await storage.deleteCustomDeck(duplicated.id);
      expect(storage.getCustomDecks(), isEmpty);
    });

    test('importDeck persists external pack as custom', () async {
      const externalPack = QuestionDeck(
        id: 'deck_external',
        title: 'Deep Intimacy',
        description: 'Brought from friend',
        icon: Icons.favorite,
        accentColor: Color(0xFFE11D48),
        isCustom: true,
        questions: [
          Question(id: 'q_ext_1', text: 'What is your best memory of us?', deckId: 'deck_external', isCustom: true),
        ],
      );

      await storage.importDeck(externalPack);
      expect(storage.getCustomDecks().length, 1);
      expect(storage.getCustomDecks().first.title, 'Deep Intimacy');
      expect(storage.getCustomDecks().first.questions.first.text, 'What is your best memory of us?');
    });

    test('saveDeck allows customizing preset deck in place', () async {
      final original = storage.getPresetDecks().firstWhere((d) => d.id == 'getting_to_know_you');
      final customized = original.copyWith(
        title: 'Customized Getting to Know You',
        questions: [
          const Question(id: 'q_custom_1', text: 'Custom first question?', deckId: 'getting_to_know_you'),
        ],
      );

      await storage.saveDeck(customized);

      final updated = storage.getPresetDecks().firstWhere((d) => d.id == 'getting_to_know_you');
      expect(updated.title, 'Customized Getting to Know You');
      expect(updated.questions.length, 1);
      expect(updated.questions.first.text, 'Custom first question?');
      expect(updated.isCustom, isFalse);
    });

    test('deleteDeck permanently removes preset deck', () async {
      final initialPresets = storage.getPresetDecks();
      expect(initialPresets.length, 6);
      expect(initialPresets.any((d) => d.id == 'getting_to_know_you'), isTrue);

      await storage.deleteDeck('getting_to_know_you');
      expect(storage.getPresetDecks().length, 5);
      expect(storage.getPresetDecks().any((d) => d.id == 'getting_to_know_you'), isFalse);
    });

  });
}

