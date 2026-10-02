import 'package:flutter/material.dart';
import 'package:konfide/core/models/question.dart';

class QuestionDeck {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<Question> questions;
  final bool isCustom;
  final int version;

  const QuestionDeck({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.questions,
    this.isCustom = false,
    this.version = 1,
  });

  /// Returns questions filtering out any that the user has hidden/deleted.
  List<Question> visibleQuestions(Set<String> hiddenQuestionIds) {
    return questions
        .where((q) => !hiddenQuestionIds.contains(q.id))
        .toList();
  }

  QuestionDeck copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    IconData? icon,
    Color? accentColor,
    List<Question>? questions,
    bool? isCustom,
    int? version,
  }) {
    return QuestionDeck(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      questions: questions ?? this.questions,
      isCustom: isCustom ?? this.isCustom,
      version: version ?? this.version,
    );
  }

  String get iconKey {
    return _iconToKey(icon);
  }

  static String _iconToKey(IconData icon) {
    if (icon == Icons.favorite || icon == Icons.favorite_outline) return 'heart';
    if (icon == Icons.people || icon == Icons.people_outline) return 'people';
    if (icon == Icons.home || icon == Icons.home_outlined) return 'home';
    if (icon == Icons.lightbulb || icon == Icons.lightbulb_outline) return 'lightbulb';
    if (icon == Icons.psychology || icon == Icons.psychology_outlined) return 'mind';
    if (icon == Icons.auto_awesome) return 'sparkles';
    if (icon == Icons.local_fire_department) return 'fire';
    if (icon == Icons.explore) return 'explore';
    return 'chat';
  }

  static IconData iconFromKey(String key) {
    switch (key) {
      case 'heart':
        return Icons.favorite_outline;
      case 'people':
        return Icons.people_outline;
      case 'home':
        return Icons.home_outlined;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      case 'mind':
        return Icons.psychology_outlined;
      case 'sparkles':
        return Icons.auto_awesome;
      case 'fire':
        return Icons.local_fire_department;
      case 'explore':
        return Icons.explore_outlined;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'iconKey': iconKey,
      'accentColorValue': accentColor.toARGB32(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'isCustom': isCustom,
      'version': version,
    };
  }

  factory QuestionDeck.fromJson(Map<String, dynamic> json) {
    final rawQuestions = (json['questions'] as List<dynamic>?)
            ?.map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <Question>[];

    final iconKey = json['iconKey'] as String? ?? 'chat';
    final colorValue = (json['accentColorValue'] as num?)?.toInt() ?? 0xFF8D6E63;
    final version = (json['version'] as num?)?.toInt() ?? 1;

    return QuestionDeck(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Custom Deck',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: iconFromKey(iconKey),
      accentColor: Color(colorValue),
      questions: rawQuestions,
      isCustom: json['isCustom'] as bool? ?? true,
      version: version,
    );
  }
}
