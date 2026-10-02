import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konfide/core/database/database_service.dart';
import 'package:konfide/core/models/companion.dart';
import 'package:konfide/core/models/deck.dart';
import 'package:konfide/core/models/deck_progress.dart';
import 'package:konfide/core/models/question.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService dbService;

  setUp(() async {
    dbService = await DatabaseService.init(inMemory: true);
  });

  tearDown(() async {
    await dbService.close();
  });

  group('DatabaseService tests', () {
    test('seeds default companion on creation', () async {
      final companions = await dbService.getCompanions();
      expect(companions.length, 1);
      expect(companions.first.id, Companion.defaultId);
      expect(companions.first.name, 'General');
    });

    test('saves, queries, and deletes custom companions', () async {
      final companion = Companion(
        id: 'comp_alice',
        name: 'Alice',
        createdAt: DateTime.now(),
        colorIndex: 3,
      );

      await dbService.saveCompanion(companion);

      final companions = await dbService.getCompanions();
      expect(companions.length, 2);
      expect(companions.any((c) => c.id == 'comp_alice'), isTrue);

      await dbService.deleteCompanion('comp_alice');
      final updated = await dbService.getCompanions();
      expect(updated.length, 1);
      expect(updated.any((c) => c.id == 'comp_alice'), isFalse);
    });

    test('cascades deletion of companion to deck progress', () async {
      final companion = Companion(
        id: 'comp_bob',
        name: 'Bob',
        createdAt: DateTime.now(),
      );
      await dbService.saveCompanion(companion);

      final progress = DeckProgress(
        companionId: 'comp_bob',
        deckId: 'getting_to_know_you',
        currentIndex: 4,
        seenQuestionIds: ['q1', 'q2', 'q3'],
        lastActive: DateTime.now(),
      );
      await dbService.saveProgress(progress);

      final fetched = await dbService.getProgress('comp_bob', 'getting_to_know_you');
      expect(fetched, isNotNull);
      expect(fetched!.currentIndex, 4);

      // Deleting companion cascades and removes progress
      await dbService.deleteCompanion('comp_bob');
      final afterDelete = await dbService.getProgress('comp_bob', 'getting_to_know_you');
      expect(afterDelete, isNull);
    });

    test('seeds 6 default preset decks on creation', () async {
      final presetDecks = await dbService.getDecks(isPreset: true);
      expect(presetDecks.length, 6);
      expect(presetDecks.first.id, 'getting_to_know_you');
    });

    test('custom deck creation and question cascade deletion', () async {
      const customDeck = QuestionDeck(
        id: 'deck_travel',
        title: 'Travel Tales',
        subtitle: 'Adventures',
        description: 'Stories from the road',
        icon: Icons.explore_outlined,
        accentColor: Color(0xFF10B981),
        isCustom: true,
        questions: [
          Question(id: 'q_t1', text: 'Best flight ever?', deckId: 'deck_travel', isCustom: true),
          Question(id: 'q_t2', text: 'Worst hostel stay?', deckId: 'deck_travel', isCustom: true),
        ],
      );

      await dbService.saveDeck(customDeck);

      final decks = await dbService.getDecks(isPreset: false);
      expect(decks.length, 1);
      expect(decks.first.id, 'deck_travel');
      expect(decks.first.questions.length, 2);
      expect(decks.first.questions.first.text, 'Best flight ever?');

      // Delete deck
      await dbService.deleteDeck('deck_travel');
      final afterDelete = await dbService.getDecks(isPreset: false);
      expect(afterDelete, isEmpty);
    });

    test('favorites management', () async {
      expect(await dbService.getFavorites(), isEmpty);

      await dbService.addFavorite('q_fav_1');
      await dbService.addFavorite('q_fav_2');
      expect(await dbService.getFavorites(), {'q_fav_1', 'q_fav_2'});

      await dbService.removeFavorite('q_fav_1');
      expect(await dbService.getFavorites(), {'q_fav_2'});
    });

    test('notes management', () async {
      expect(await dbService.getNotes(), isEmpty);

      await dbService.saveNote('q_note_1', 'Remember this for our anniversary');
      final notes = await dbService.getNotes();
      expect(notes['q_note_1'], 'Remember this for our anniversary');

      // Empty note removes it
      await dbService.saveNote('q_note_1', '   ');
      final notesAfter = await dbService.getNotes();
      expect(notesAfter.containsKey('q_note_1'), isFalse);
    });

    test('hidden questions and hidden decks', () async {
      expect(await dbService.getHiddenQuestions(), isEmpty);
      expect(await dbService.getHiddenDecks(), isEmpty);

      await dbService.hideQuestion('q_skip_1');
      expect(await dbService.getHiddenQuestions(), {'q_skip_1'});

      await dbService.unhideQuestion('q_skip_1');
      expect(await dbService.getHiddenQuestions(), isEmpty);

      await dbService.hideDeck('deck_hide_1');
      expect(await dbService.getHiddenDecks(), {'deck_hide_1'});

      await dbService.unhideDeck('deck_hide_1');
      expect(await dbService.getHiddenDecks(), isEmpty);
    });

    test('syncPresetDecks inserts newly introduced preset decks automatically', () async {
      final initialPresets = await dbService.getDecks(isPreset: true);
      expect(initialPresets.any((d) => d.id == 'brand_new_pack'), isFalse);

      const newPack = QuestionDeck(
        id: 'brand_new_pack',
        title: 'Brand New Pack',
        subtitle: 'New Subtitle',
        description: 'New Description',
        icon: Icons.star,
        accentColor: Colors.amber,
        questions: [
          Question(id: 'new_q_1', text: 'Brand new question 1?', deckId: 'brand_new_pack'),
        ],
        isCustom: false,
        version: 1,
      );

      await dbService.syncPresetDecks([newPack]);

      final updatedPresets = await dbService.getDecks(isPreset: true);
      expect(updatedPresets.any((d) => d.id == 'brand_new_pack'), isTrue);

      final fetched = await dbService.getDeckById('brand_new_pack');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Brand New Pack');
      expect(fetched.questions.first.text, 'Brand new question 1?');
    });

    test('syncPresetDecks updates deck on version bump and preserves favorites/notes', () async {
      // 1. Initial deck version 1
      const initialDeck = QuestionDeck(
        id: 'versioned_deck',
        title: 'Version 1 Title',
        subtitle: 'Sub 1',
        description: 'Desc 1',
        icon: Icons.chat,
        accentColor: Colors.blue,
        questions: [
          Question(id: 'vq_1', text: 'Original question 1', deckId: 'versioned_deck'),
          Question(id: 'vq_2', text: 'Original question 2', deckId: 'versioned_deck'),
        ],
        isCustom: false,
        version: 1,
      );

      await dbService.syncPresetDecks([initialDeck]);

      // User favorites vq_1 and adds a note to vq_1
      await dbService.addFavorite('vq_1');
      await dbService.saveNote('vq_1', 'Loved this answer!');

      expect(await dbService.getFavorites(), contains('vq_1'));
      expect((await dbService.getNotes())['vq_1'], 'Loved this answer!');

      // 2. Version 2 update:
      // - vq_1 has edited text (fixed typo)
      // - vq_2 is retired
      // - vq_3 is newly added
      const updatedDeck = QuestionDeck(
        id: 'versioned_deck',
        title: 'Version 2 Title',
        subtitle: 'Sub 2 Updated',
        description: 'Desc 2 Updated',
        icon: Icons.chat,
        accentColor: Colors.purple,
        questions: [
          Question(id: 'vq_1', text: 'Updated question 1 with typo fixed', deckId: 'versioned_deck'),
          Question(id: 'vq_3', text: 'New question 3', deckId: 'versioned_deck'),
        ],
        isCustom: false,
        version: 2,
      );

      await dbService.syncPresetDecks([updatedDeck]);

      // Verify deck metadata updated
      final fetched = await dbService.getDeckById('versioned_deck');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Version 2 Title');
      expect(fetched.version, 2);
      expect(fetched.questions.length, 2);
      expect(fetched.questions[0].id, 'vq_1');
      expect(fetched.questions[0].text, 'Updated question 1 with typo fixed');
      expect(fetched.questions[1].id, 'vq_3');
      expect(fetched.questions[1].text, 'New question 3');

      // Verify user's favorite and note on vq_1 survived unharmed!
      expect(await dbService.getFavorites(), contains('vq_1'));
      expect((await dbService.getNotes())['vq_1'], 'Loved this answer!');
    });
  });
}
