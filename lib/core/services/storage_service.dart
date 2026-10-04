import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:konfide/core/database/database_service.dart';
import 'package:konfide/core/models/companion.dart';
import 'package:konfide/core/models/deck_progress.dart';
import 'package:konfide/core/models/deck.dart';
import 'package:konfide/core/models/question.dart';
import 'package:konfide/core/services/preset_deck_service.dart';

class StorageService extends ChangeNotifier {
  static late StorageService _instance;
  static StorageService get instance => _instance;

  final SharedPreferences _prefs;
  final DatabaseService _db;

  // In-memory cache for synchronous UI reads
  final List<Companion> _companions = [];
  final Map<String, DeckProgress> _progress = {};
  final List<QuestionDeck> _presetDecks = [];
  final List<QuestionDeck> _customDecks = [];
  final Set<String> _favorites = {};
  final Map<String, String> _notes = {};

  StorageService._(this._prefs, this._db);

  static Future<StorageService> init({
    SharedPreferences? mockPrefs,
    DatabaseService? mockDbService,
    List<QuestionDeck>? presetDecks,
    AssetBundle? assetBundle,
  }) async {
    final prefs = mockPrefs ?? await SharedPreferences.getInstance();
    final db = mockDbService ?? await DatabaseService.init(
      presetDecks: presetDecks,
      assetBundle: assetBundle,
    );
    final service = StorageService._(prefs, db);
    await service._loadFromDatabase();
    _instance = service;
    return _instance;
  }

  Future<void> _loadFromDatabase() async {
    _companions.clear();
    _companions.addAll(await _db.getCompanions());

    _progress.clear();
    final progressList = await _db.getAllProgress();
    for (final p in progressList) {
      _progress[_progressKey(p.companionId, p.deckId)] = p;
    }

    _presetDecks.clear();
    _presetDecks.addAll(await _db.getDecks(isPreset: true));
    _presetDecks.sort(PresetDeckService.comparePresetDecks);

    _customDecks.clear();
    _customDecks.addAll(await _db.getDecks(isPreset: false));

    _favorites.clear();
    _favorites.addAll(await _db.getFavorites());

    _notes.clear();
    _notes.addAll(await _db.getNotes());
  }

  // --- Simple User Settings Keys (SharedPreferences) ---
  static const _keyActiveCompanionId = 'konfide_active_companion_id';
  static const _keyThemePreset = 'konfide_theme_preset';

  // ==================== COMPANIONS (SQLite) ====================

  List<Companion> getCompanions() {
    if (_companions.isEmpty) {
      return [Companion.defaultCompanion];
    }
    return List.unmodifiable(_companions);
  }

  Future<void> addCompanion(Companion companion) async {
    if (!_companions.any((c) => c.id == companion.id)) {
      _companions.add(companion);
      notifyListeners();
      await _db.saveCompanion(companion);
    }
  }

  Future<void> deleteCompanion(String id) async {
    if (id == Companion.defaultId) return; // Cannot delete default companion

    _companions.removeWhere((c) => c.id == id);
    _progress.removeWhere((key, _) => key.startsWith('${id}_'));

    // If active companion was deleted, fall back to default
    if (getActiveCompanionId() == id) {
      await setActiveCompanionId(Companion.defaultId);
    } else {
      notifyListeners();
    }
    await _db.deleteCompanion(id);
  }

  // Active companion setting stored in SharedPreferences
  String getActiveCompanionId() {
    return _prefs.getString(_keyActiveCompanionId) ?? Companion.defaultId;
  }

  Future<void> setActiveCompanionId(String id) async {
    await _prefs.setString(_keyActiveCompanionId, id);
    notifyListeners();
  }

  Companion getActiveCompanion() {
    final activeId = getActiveCompanionId();
    return _companions.firstWhere(
      (c) => c.id == activeId,
      orElse: () => Companion.defaultCompanion,
    );
  }

  // ==================== PER-COMPANION PROGRESS (SQLite) ====================

  String _progressKey(String companionId, String deckId) =>
      '${companionId}_$deckId';

  DeckProgress getProgress(String companionId, String deckId) {
    final key = _progressKey(companionId, deckId);
    return _progress[key] ??
        DeckProgress(
          companionId: companionId,
          deckId: deckId,
          currentIndex: 0,
          seenQuestionIds: const [],
          lastActive: DateTime.now(),
        );
  }

  Future<void> saveProgress(DeckProgress progress) async {
    _progress[_progressKey(progress.companionId, progress.deckId)] = progress;
    notifyListeners();
    await _db.saveProgress(progress);
  }

  Future<void> markQuestionSeen({
    required String companionId,
    required String deckId,
    required String questionId,
    required int newIndex,
  }) async {
    final current = getProgress(companionId, deckId);
    final updatedSeen = List<String>.from(current.seenQuestionIds);
    if (!updatedSeen.contains(questionId)) {
      updatedSeen.add(questionId);
    }
    final updated = current.copyWith(
      currentIndex: newIndex,
      seenQuestionIds: updatedSeen,
      lastActive: DateTime.now(),
    );
    await saveProgress(updated);
  }

  Future<void> resetProgress(String companionId, String deckId) async {
    _progress.remove(_progressKey(companionId, deckId));
    notifyListeners();
    await _db.deleteProgress(companionId, deckId);
  }

  // ==================== DECKS (SQLite) ====================

  List<QuestionDeck> getPresetDecks() {
    return List.unmodifiable(_presetDecks);
  }

  List<QuestionDeck> getCustomDecks() {
    return List.unmodifiable(_customDecks);
  }

  List<QuestionDeck> getAllDecks() {
    return List.unmodifiable([..._presetDecks, ..._customDecks]);
  }

  QuestionDeck? getDeckById(String id) {
    for (final deck in _presetDecks) {
      if (deck.id == id) return deck;
    }
    for (final deck in _customDecks) {
      if (deck.id == id) return deck;
    }
    return null;
  }

  Future<void> saveDeck(QuestionDeck deck) async {
    if (deck.isCustom) {
      await saveCustomDeck(deck);
    } else {
      final index = _presetDecks.indexWhere((d) => d.id == deck.id);
      if (index >= 0) {
        _presetDecks[index] = deck;
      } else {
        _presetDecks.add(deck);
      }
      _presetDecks.sort(PresetDeckService.comparePresetDecks);
      notifyListeners();
      await _db.saveDeck(deck, isPreset: true);
    }
  }

  Future<void> saveCustomDeck(QuestionDeck deck) async {
    final customDeck = deck.copyWith(isCustom: true);
    final index = _customDecks.indexWhere((d) => d.id == customDeck.id);
    if (index >= 0) {
      _customDecks[index] = customDeck;
    } else {
      _customDecks.add(customDeck);
    }
    notifyListeners();
    await _db.saveDeck(customDeck, isPreset: false);
  }

  Future<void> deleteDeck(String deckId) async {
    _customDecks.removeWhere((d) => d.id == deckId);
    _presetDecks.removeWhere((d) => d.id == deckId);
    notifyListeners();
    await _db.deleteDeck(deckId);
  }

  Future<void> deleteCustomDeck(String deckId) => deleteDeck(deckId);

  /// Duplicates any deck (preset or custom) into a new, editable custom deck.
  Future<QuestionDeck> duplicateDeck(
    QuestionDeck originalDeck, {
    String? titleOverride,
  }) async {
    final newDeckId = 'custom_${const Uuid().v4()}';
    final newQuestions = originalDeck.questions.map((q) {
      return Question(
        id: 'custom_${const Uuid().v4()}',
        deckId: newDeckId,
        text: q.text,
        isCustom: true,
      );
    }).toList();

    final duplicated = QuestionDeck(
      id: newDeckId,
      title: titleOverride ?? '${originalDeck.title} (Copy)',
      description: originalDeck.description,
      icon: originalDeck.icon,
      accentColor: originalDeck.accentColor,
      questions: newQuestions,
      isCustom: true,
    );

    await saveCustomDeck(duplicated);
    return duplicated;
  }

  /// Imports an external question deck as a custom deck.
  Future<void> importDeck(QuestionDeck deck) async {
    await saveCustomDeck(deck);
  }

  // ==================== DELETE QUESTION (SQLite) ====================

  /// Permanently deletes a question from its deck.
  Future<void> deleteQuestion(String questionId) async {
    _favorites.remove(questionId);
    _notes.remove(questionId);
    for (var i = 0; i < _presetDecks.length; i++) {
      final d = _presetDecks[i];
      if (d.questions.any((q) => q.id == questionId)) {
        _presetDecks[i] = d.copyWith(
          questions: d.questions.where((q) => q.id != questionId).toList(),
        );
      }
    }
    for (var i = 0; i < _customDecks.length; i++) {
      final d = _customDecks[i];
      if (d.questions.any((q) => q.id == questionId)) {
        _customDecks[i] = d.copyWith(
          questions: d.questions.where((q) => q.id != questionId).toList(),
        );
      }
    }
    notifyListeners();
    await _db.deleteQuestion(questionId);
  }

  // ==================== FAVORITES & NOTES (SQLite) ====================

  Set<String> getFavorites() {
    return Set.unmodifiable(_favorites);
  }

  bool isFavorite(String questionId) {
    return _favorites.contains(questionId);
  }

  Future<void> toggleFavorite(String questionId) async {
    if (_favorites.contains(questionId)) {
      _favorites.remove(questionId);
      notifyListeners();
      await _db.removeFavorite(questionId);
    } else {
      _favorites.add(questionId);
      notifyListeners();
      await _db.addFavorite(questionId);
    }
  }

  String? getNote(String questionId) {
    return _notes[questionId];
  }

  Future<void> saveNote(String questionId, String note) async {
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      _notes.remove(questionId);
    } else {
      _notes[questionId] = trimmed;
    }
    notifyListeners();
    await _db.saveNote(questionId, note);
  }

  // ==================== THEME PRESET (SharedPreferences) ====================

  String getThemePreset() {
    return _prefs.getString(_keyThemePreset) ?? 'candlelight';
  }

  Future<void> setThemePreset(String preset) async {
    await _prefs.setString(_keyThemePreset, preset);
    notifyListeners();
  }

  // ==================== LIFECYCLE ====================

  Future<void> close() async {
    await _db.close();
  }
}

