import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:konfide/core/models/deck.dart';
import 'package:konfide/core/models/question.dart';

/// Service responsible for loading and parsing preset question decks from assets.
class PresetDeckService {
  /// List of bundled preset deck asset file paths.
  static const List<String> presetAssetFiles = [
    'assets/decks/getting_to_know_you.json',
    'assets/decks/friends_and_family.json',
    'assets/decks/couples_romance.json',
    'assets/decks/family_generations.json',
    'assets/decks/thought_provoking.json',
    'assets/decks/deeply_personal.json',
  ];

  /// Parses a preset deck JSON string into a [QuestionDeck].
  static QuestionDeck parsePresetDeckJson(String jsonString, {String? defaultId}) {
    if (jsonString.trim().isEmpty) {
      throw const FormatException('Preset deck JSON is empty');
    }

    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Root of preset deck JSON must be an object');
    }

    final id = decoded['id'] as String? ?? defaultId ?? 'preset_${DateTime.now().millisecondsSinceEpoch}';
    final title = (decoded['title'] as String?)?.trim() ?? 'Curated Deck';
    final description = (decoded['description'] as String?)?.trim() ?? '';
    final iconKey = decoded['icon'] as String? ?? decoded['iconKey'] as String? ?? 'chat';
    final version = (decoded['version'] as num?)?.toInt() ?? 1;

    // Parse accent color (hex string or int ARGB value)
    Color accentColor = const Color(0xFFD97736);
    final rawColor = decoded['accentColor'] ?? decoded['accentColorValue'];
    if (rawColor is String) {
      final hex = rawColor.replaceFirst('#', '').trim();
      accentColor = Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
    } else if (rawColor is num) {
      accentColor = Color(rawColor.toInt());
    }

    final rawQuestions = decoded['questions'] as List<dynamic>? ?? [];
    final questions = <Question>[];

    for (var i = 0; i < rawQuestions.length; i++) {
      final item = rawQuestions[i];
      String text = '';
      String questionId = '${id}_${i + 1}';

      if (item is String) {
        text = item.trim();
      } else if (item is Map) {
        text = (item['text'] ?? item['question'] ?? item['q'] ?? '').toString().trim();
        if (item['id'] != null) {
          questionId = item['id'].toString().trim();
        }
      }

      if (text.isNotEmpty) {
        questions.add(
          Question(
            id: questionId,
            text: text,
            deckId: id,
            isCustom: false,
          ),
        );
      }
    }

    return QuestionDeck(
      id: id,
      title: title,
      description: description,
      icon: QuestionDeck.iconFromKey(iconKey),
      accentColor: accentColor,
      questions: questions,
      isCustom: false,
      version: version,
    );
  }

  /// Loads all preset decks configured in [presetAssetFiles].
  /// Uses [bundle] if provided, defaulting to [rootBundle].
  static Future<List<QuestionDeck>> loadAllPresetDecks({AssetBundle? bundle}) async {
    final effectiveBundle = bundle ?? rootBundle;
    final List<QuestionDeck> decks = [];

    for (final assetPath in presetAssetFiles) {
      try {
        final jsonStr = await effectiveBundle.loadString(assetPath);
        final deck = parsePresetDeckJson(jsonStr);
        decks.add(deck);
      } catch (e) {
        debugPrint('Warning: Could not load preset asset "$assetPath": $e');
      }
    }

    return decks;
  }
}
