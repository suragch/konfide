class DeckProgress {
  final String companionId;
  final String deckId;
  final int currentIndex;
  final List<String> seenQuestionIds;
  final DateTime lastActive;

  const DeckProgress({
    required this.companionId,
    required this.deckId,
    this.currentIndex = 0,
    this.seenQuestionIds = const [],
    required this.lastActive,
  });

  bool isSeen(String questionId) => seenQuestionIds.contains(questionId);

  DeckProgress copyWith({
    String? companionId,
    String? deckId,
    int? currentIndex,
    List<String>? seenQuestionIds,
    DateTime? lastActive,
  }) {
    return DeckProgress(
      companionId: companionId ?? this.companionId,
      deckId: deckId ?? this.deckId,
      currentIndex: currentIndex ?? this.currentIndex,
      seenQuestionIds: seenQuestionIds ?? this.seenQuestionIds,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companionId': companionId,
      'deckId': deckId,
      'currentIndex': currentIndex,
      'seenQuestionIds': seenQuestionIds,
      'lastActive': lastActive.toIso8601String(),
    };
  }

  factory DeckProgress.fromJson(Map<String, dynamic> json) {
    final seen = (json['seenQuestionIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    return DeckProgress(
      companionId: json['companionId'] as String? ?? 'general',
      deckId: json['deckId'] as String? ?? '',
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
      seenQuestionIds: seen,
      lastActive: json['lastActive'] != null
          ? DateTime.tryParse(json['lastActive'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
