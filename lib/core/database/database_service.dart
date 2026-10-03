import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common/utils/utils.dart' as sqflite_utils;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:konfide/core/models/companion.dart';
import 'package:konfide/core/models/deck_progress.dart';
import 'package:konfide/core/models/deck.dart';
import 'package:konfide/core/models/question.dart';
import 'package:konfide/core/services/preset_deck_service.dart';

class DatabaseService {
  final Database _db;

  DatabaseService._(this._db);

  Database get database => _db;

  /// Initializes the SQLite database.
  /// Uses an in-memory database during tests or when [inMemory] is true.
  static Future<DatabaseService> init({
    Database? overrideDatabase,
    bool inMemory = false,
    List<QuestionDeck>? presetDecks,
    AssetBundle? assetBundle,
  }) async {
    if (overrideDatabase != null) {
      return DatabaseService._(overrideDatabase);
    }

    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    final presets = presetDecks ?? await PresetDeckService.loadAllPresetDecks(bundle: assetBundle);

    if (inMemory || isTest) {
      sqfliteFfiInit();
      // ignore: deprecated_member_use
      sqflite_utils.lockWarningDuration = null;
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: _onConfigure,
          onCreate: (db, ver) => _onCreate(db, ver, presets),
        ),
      );
      final service = DatabaseService._(db);
      await service.syncPresetDecks(presets);
      return service;
    }

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, 'konfide.db');

    final db = await openDatabase(
      dbPath,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: (db, ver) => _onCreate(db, ver, presets),
    );

    final service = DatabaseService._(db);
    await service.syncPresetDecks(presets);
    return service;
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database db, int version, List<QuestionDeck> presets) async {
    // 1. Companions table
    await db.execute('''
      CREATE TABLE companions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        color_index INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. Unified Decks table
    await db.execute('''
      CREATE TABLE decks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        accent_color_value INTEGER NOT NULL,
        is_preset INTEGER NOT NULL DEFAULT 0,
        version INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    // 3. Unified Questions table
    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        deck_id TEXT NOT NULL,
        text TEXT NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        is_custom INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE
      )
    ''');

    // 4. Deck Progress table
    await db.execute('''
      CREATE TABLE deck_progress (
        companion_id TEXT NOT NULL,
        deck_id TEXT NOT NULL,
        current_index INTEGER NOT NULL DEFAULT 0,
        seen_question_ids TEXT NOT NULL,
        last_active INTEGER NOT NULL,
        PRIMARY KEY (companion_id, deck_id),
        FOREIGN KEY (companion_id) REFERENCES companions (id) ON DELETE CASCADE,
        FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE
      )
    ''');

    // 5. Favorites table
    await db.execute('''
      CREATE TABLE favorites (
        question_id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL
      )
    ''');

    // 6. Notes table
    await db.execute('''
      CREATE TABLE notes (
        question_id TEXT PRIMARY KEY,
        note TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 7. Hidden Questions table
    await db.execute('''
      CREATE TABLE hidden_questions (
        question_id TEXT PRIMARY KEY
      )
    ''');

    // 8. Hidden Decks table
    await db.execute('''
      CREATE TABLE hidden_decks (
        deck_id TEXT PRIMARY KEY
      )
    ''');

    // Seed default companion
    await db.insert('companions', {
      'id': Companion.defaultId,
      'name': 'General',
      'created_at': 0,
      'color_index': 0,
    });

    // Seed preset decks and questions
    for (final deck in presets) {
      await _insertDeckInternal(db, deck, isPreset: true);
    }
  }

  static Future<void> _insertDeckInternal(
    DatabaseExecutor db,
    QuestionDeck deck, {
    required bool isPreset,
  }) async {
    await db.insert(
      'decks',
      {
        'id': deck.id,
        'title': deck.title,
        'description': deck.description,
        'icon_key': deck.iconKey,
        'accent_color_value': deck.accentColor.toARGB32(),
        'is_preset': isPreset ? 1 : 0,
        'version': deck.version,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.delete('questions', where: 'deck_id = ?', whereArgs: [deck.id]);

    for (var i = 0; i < deck.questions.length; i++) {
      final q = deck.questions[i];
      await db.insert('questions', {
        'id': q.id,
        'deck_id': deck.id,
        'text': q.text,
        'position': i,
        'is_custom': q.isCustom ? 1 : 0,
      });
    }
  }

  // ==================== COMPANIONS ====================

  Future<List<Companion>> getCompanions() async {
    final rows = await _db.query('companions', orderBy: 'created_at ASC');
    final list = rows.map((r) {
      return Companion(
        id: r['id'] as String,
        name: r['name'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
        colorIndex: r['color_index'] as int? ?? 0,
      );
    }).toList();

    if (!list.any((c) => c.id == Companion.defaultId)) {
      list.insert(0, Companion.defaultCompanion);
    }
    return list;
  }

  Future<void> saveCompanion(Companion companion) async {
    await _db.insert(
      'companions',
      {
        'id': companion.id,
        'name': companion.name,
        'created_at': companion.createdAt.millisecondsSinceEpoch,
        'color_index': companion.colorIndex,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCompanion(String id) async {
    if (id == Companion.defaultId) return;
    await _db.delete('companions', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== DECK PROGRESS ====================

  Future<List<DeckProgress>> getAllProgress() async {
    final rows = await _db.query('deck_progress');
    return rows.map((row) {
      final seenRaw = row['seen_question_ids'] as String;
      List<String> seen;
      try {
        seen = (jsonDecode(seenRaw) as List<dynamic>).map((e) => e.toString()).toList();
      } catch (_) {
        seen = [];
      }
      return DeckProgress(
        companionId: row['companion_id'] as String,
        deckId: row['deck_id'] as String,
        currentIndex: row['current_index'] as int,
        seenQuestionIds: seen,
        lastActive: DateTime.fromMillisecondsSinceEpoch(row['last_active'] as int),
      );
    }).toList();
  }

  Future<DeckProgress?> getProgress(String companionId, String deckId) async {
    final rows = await _db.query(
      'deck_progress',
      where: 'companion_id = ? AND deck_id = ?',
      whereArgs: [companionId, deckId],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final seenRaw = row['seen_question_ids'] as String;
    List<String> seen;
    try {
      seen = (jsonDecode(seenRaw) as List<dynamic>).map((e) => e.toString()).toList();
    } catch (_) {
      seen = [];
    }
    return DeckProgress(
      companionId: row['companion_id'] as String,
      deckId: row['deck_id'] as String,
      currentIndex: row['current_index'] as int,
      seenQuestionIds: seen,
      lastActive: DateTime.fromMillisecondsSinceEpoch(row['last_active'] as int),
    );
  }

  Future<void> saveProgress(DeckProgress progress) async {
    await _db.insert(
      'deck_progress',
      {
        'companion_id': progress.companionId,
        'deck_id': progress.deckId,
        'current_index': progress.currentIndex,
        'seen_question_ids': jsonEncode(progress.seenQuestionIds),
        'last_active': progress.lastActive.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteProgress(String companionId, String deckId) async {
    await _db.delete(
      'deck_progress',
      where: 'companion_id = ? AND deck_id = ?',
      whereArgs: [companionId, deckId],
    );
  }

  // ==================== UNIFIED DECKS & QUESTIONS ====================

  Future<List<QuestionDeck>> getDecks({bool? isPreset}) async {
    final List<Map<String, dynamic>> deckRows;
    if (isPreset != null) {
      deckRows = await _db.query(
        'decks',
        where: 'is_preset = ?',
        whereArgs: [isPreset ? 1 : 0],
        orderBy: 'created_at ASC',
      );
    } else {
      deckRows = await _db.query('decks', orderBy: 'is_preset DESC, created_at ASC');
    }

    if (deckRows.isEmpty) return [];

    final questionRows = await _db.query('questions', orderBy: 'position ASC');
    final Map<String, List<Question>> questionsByDeck = {};

    for (final q in questionRows) {
      final deckId = q['deck_id'] as String;
      questionsByDeck.putIfAbsent(deckId, () => []).add(
        Question(
          id: q['id'] as String,
          text: q['text'] as String,
          deckId: deckId,
          isCustom: (q['is_custom'] as int? ?? 0) == 1,
        ),
      );
    }

    return deckRows.map((row) {
      final deckId = row['id'] as String;
      return QuestionDeck(
        id: deckId,
        title: row['title'] as String,
        description: row['description'] as String,
        icon: QuestionDeck.iconFromKey(row['icon_key'] as String),
        accentColor: Color(row['accent_color_value'] as int),
        questions: questionsByDeck[deckId] ?? [],
        isCustom: (row['is_preset'] as int) == 0,
        version: row['version'] as int? ?? 1,
      );
    }).toList();
  }

  Future<QuestionDeck?> getDeckById(String id) async {
    final deckRows = await _db.query(
      'decks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deckRows.isEmpty) return null;

    final row = deckRows.first;
    final questionRows = await _db.query(
      'questions',
      where: 'deck_id = ?',
      whereArgs: [id],
      orderBy: 'position ASC',
    );

    final questions = questionRows.map((q) {
      return Question(
        id: q['id'] as String,
        text: q['text'] as String,
        deckId: id,
        isCustom: (q['is_custom'] as int? ?? 0) == 1,
      );
    }).toList();

    return QuestionDeck(
      id: id,
      title: row['title'] as String,
      description: row['description'] as String,
      icon: QuestionDeck.iconFromKey(row['icon_key'] as String),
      accentColor: Color(row['accent_color_value'] as int),
      questions: questions,
      isCustom: (row['is_preset'] as int) == 0,
      version: row['version'] as int? ?? 1,
    );
  }

  Future<void> saveDeck(QuestionDeck deck, {bool? isPreset}) async {
    await _db.transaction((txn) async {
      await _insertDeckInternal(
        txn,
        deck,
        isPreset: isPreset ?? (!deck.isCustom),
      );
    });
  }

  Future<void> deleteDeck(String deckId) async {
    await _db.delete('decks', where: 'id = ?', whereArgs: [deckId]);
  }

  /// Synchronizes preset decks from assets into SQLite.
  /// - Automatically adds newly introduced preset decks.
  /// - Updates existing preset decks if asset version > db version, updating questions without losing favorites/notes.
  Future<void> syncPresetDecks(List<QuestionDeck> assetPresets) async {
    if (assetPresets.isEmpty) return;

    final existingDecks = await _db.query(
      'decks',
      columns: ['id', 'version'],
      where: 'is_preset = 1',
    );
    final dbDeckVersions = <String, int>{
      for (final r in existingDecks)
        r['id'] as String: (r['version'] as int? ?? 1),
    };

    for (final assetDeck in assetPresets) {
      if (!dbDeckVersions.containsKey(assetDeck.id)) {
        // Newly added preset deck in this app update!
        await _insertDeckInternal(_db, assetDeck, isPreset: true);
      } else {
        final currentDbVersion = dbDeckVersions[assetDeck.id]!;
        if (assetDeck.version > currentDbVersion) {
          // Version bump in asset deck!
          await _updatePresetDeckInternal(_db, assetDeck);
        }
      }
    }
  }

  static Future<void> _updatePresetDeckInternal(
    DatabaseExecutor db,
    QuestionDeck assetDeck,
  ) async {
    // 1. Update deck metadata & version
    await db.update(
      'decks',
      {
        'title': assetDeck.title,
        'description': assetDeck.description,
        'icon_key': assetDeck.iconKey,
        'accent_color_value': assetDeck.accentColor.toARGB32(),
        'version': assetDeck.version,
      },
      where: 'id = ?',
      whereArgs: [assetDeck.id],
    );

    // 2. Fetch existing questions
    final existingQuestionRows = await db.query(
      'questions',
      columns: ['id'],
      where: 'deck_id = ?',
      whereArgs: [assetDeck.id],
    );
    final existingIds = existingQuestionRows.map((r) => r['id'] as String).toSet();
    final assetQuestionIds = assetDeck.questions.map((q) => q.id).toSet();

    // 3. Upsert questions (matching on ID to keep user favorites & notes)
    for (var i = 0; i < assetDeck.questions.length; i++) {
      final q = assetDeck.questions[i];
      if (existingIds.contains(q.id)) {
        await db.update(
          'questions',
          {
            'text': q.text,
            'position': i,
          },
          where: 'id = ?',
          whereArgs: [q.id],
        );
      } else {
        await db.insert('questions', {
          'id': q.id,
          'deck_id': assetDeck.id,
          'text': q.text,
          'position': i,
          'is_custom': 0,
        });
      }
    }

    // 4. Delete questions that were retired in the asset deck
    for (final oldId in existingIds) {
      if (!assetQuestionIds.contains(oldId)) {
        await db.delete('questions', where: 'id = ?', whereArgs: [oldId]);
      }
    }
  }

  /// Restores default curated preset decks from assets.
  Future<void> restorePresetDecks([List<QuestionDeck>? presets]) async {
    final toRestore = presets ?? await PresetDeckService.loadAllPresetDecks();
    for (final deck in toRestore) {
      await saveDeck(deck, isPreset: true);
    }
  }

  // ==================== FAVORITES ====================

  Future<Set<String>> getFavorites() async {
    final rows = await _db.query('favorites');
    return rows.map((r) => r['question_id'] as String).toSet();
  }

  Future<void> addFavorite(String questionId) async {
    await _db.insert(
      'favorites',
      {
        'question_id': questionId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavorite(String questionId) async {
    await _db.delete(
      'favorites',
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
  }

  // ==================== NOTES ====================

  Future<Map<String, String>> getNotes() async {
    final rows = await _db.query('notes');
    return {
      for (final r in rows) r['question_id'] as String: r['note'] as String,
    };
  }

  Future<void> saveNote(String questionId, String note) async {
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      await _db.delete('notes', where: 'question_id = ?', whereArgs: [questionId]);
    } else {
      await _db.insert(
        'notes',
        {
          'question_id': questionId,
          'note': trimmed,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // ==================== HIDDEN QUESTIONS ====================

  Future<Set<String>> getHiddenQuestions() async {
    final rows = await _db.query('hidden_questions');
    return rows.map((r) => r['question_id'] as String).toSet();
  }

  Future<void> hideQuestion(String questionId) async {
    await _db.insert(
      'hidden_questions',
      {'question_id': questionId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> unhideQuestion(String questionId) async {
    await _db.delete(
      'hidden_questions',
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
  }

  Future<void> unhideAllQuestions() async {
    await _db.delete('hidden_questions');
  }

  // ==================== HIDDEN DECKS ====================

  Future<Set<String>> getHiddenDecks() async {
    final rows = await _db.query('hidden_decks');
    return rows.map((r) => r['deck_id'] as String).toSet();
  }

  Future<void> hideDeck(String deckId) async {
    await _db.insert(
      'hidden_decks',
      {'deck_id': deckId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> unhideDeck(String deckId) async {
    await _db.delete(
      'hidden_decks',
      where: 'deck_id = ?',
      whereArgs: [deckId],
    );
  }

  // ==================== LIFECYCLE ====================

  Future<void> close() async {
    await _db.close();
  }
}
