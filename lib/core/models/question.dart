class Question {
  final String id;
  final String text;
  final String deckId;
  final bool isCustom;

  const Question({
    required this.id,
    required this.text,
    required this.deckId,
    this.isCustom = false,
  });

  Question copyWith({
    String? id,
    String? text,
    String? deckId,
    bool? isCustom,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      deckId: deckId ?? this.deckId,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'deckId': deckId,
      'isCustom': isCustom,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      deckId: json['deckId'] as String? ?? '',
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
