import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:konfide/core/models/deck.dart';
import 'package:konfide/core/models/question.dart';

class DeckExchangeService {
  static const String formatIdentifier = 'konfide_deck';
  static const int currentVersion = 1;

  /// Serializes a [QuestionDeck] into formatted, human-readable JSON.
  static String exportDeckToJson(QuestionDeck deck) {
    final hexColor = '#${deck.accentColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    final map = <String, dynamic>{
      'format': formatIdentifier,
      'version': currentVersion,
      'title': deck.title,
      'description': deck.description,
      'icon': deck.iconKey,
      'accentColor': hexColor,
      'questions': deck.questions.map((q) => q.text).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Parses and validates a JSON string into a [QuestionDeck].
  /// Supports both standard Konfide format and generic question list formats.
  /// Throws [FormatException] if the JSON cannot be parsed or lacks required fields.
  static QuestionDeck parseAndValidateDeckJson(String jsonString) {
    if (jsonString.trim().isEmpty) {
      throw const FormatException('JSON content is empty.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      throw FormatException('Invalid JSON syntax: ${e.toString()}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Root JSON must be an object representing a pack.');
    }

    final title = (decoded['title'] as String?)?.trim();
    if (title == null || title.isEmpty) {
      throw const FormatException('Pack is missing a valid "title" field.');
    }

    final rawQuestions = decoded['questions'];
    if (rawQuestions is! List || rawQuestions.isEmpty) {
      throw const FormatException('Pack must contain a non-empty "questions" list.');
    }

    final deckId = 'custom_${const Uuid().v4()}';
    final questions = <Question>[];

    for (var i = 0; i < rawQuestions.length; i++) {
      final item = rawQuestions[i];
      String text = '';

      if (item is String) {
        text = item.trim();
      } else if (item is Map) {
        final qText = item['text'] ?? item['question'] ?? item['q'];
        if (qText is String) {
          text = qText.trim();
        }
      }

      if (text.isNotEmpty) {
        questions.add(
          Question(
            id: 'custom_${const Uuid().v4()}',
            deckId: deckId,
            text: text,
            isCustom: true,
          ),
        );
      }
    }

    if (questions.isEmpty) {
      throw const FormatException('Pack contains no valid questions.');
    }

    final description = (decoded['description'] as String?)?.trim() ??
        'Imported pack with ${questions.length} questions.';
    final iconKey = (decoded['icon'] as String?)?.trim() ?? 'chat';
    final icon = QuestionDeck.iconFromKey(iconKey);

    Color accentColor = const Color(0xFFD97736);
    final rawColor = decoded['accentColor'];
    if (rawColor is String) {
      final clean = rawColor.replaceFirst('#', '').trim();
      if (clean.length == 6) {
        final val = int.tryParse('FF$clean', radix: 16);
        if (val != null) accentColor = Color(val);
      } else if (clean.length == 8) {
        final val = int.tryParse(clean, radix: 16);
        if (val != null) accentColor = Color(val);
      }
    } else if (rawColor is num) {
      accentColor = Color(rawColor.toInt());
    }

    return QuestionDeck(
      id: deckId,
      title: title,
      description: description,
      icon: icon,
      accentColor: accentColor,
      questions: questions,
      isCustom: true,
    );
  }

  /// Copies deck JSON to the clipboard.
  static Future<void> copyDeckToClipboard(QuestionDeck deck) async {
    final json = exportDeckToJson(deck);
    await Clipboard.setData(ClipboardData(text: json));
  }

  /// Writes the deck to a temporary .json file and triggers the system share sheet.
  static Future<void> shareDeckFile(
    BuildContext context,
    QuestionDeck deck,
  ) async {
    final json = exportDeckToJson(deck);
    final tempDir = await getTemporaryDirectory();

    final safeTitle = deck.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    final filename = '${safeTitle.isEmpty ? "pack" : safeTitle}.json';
    final file = File(p.join(tempDir.path, filename));
    await file.writeAsString(json);

    if (!context.mounted) return;

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json', name: filename)],
        subject: 'Konfide Pack: ${deck.title}',
        text: 'Here is "${deck.title}", a conversation starter pack for Konfide.',
        sharePositionOrigin: origin,
      ),
    );
  }
}
