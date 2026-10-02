class Companion {
  final String id;
  final String name;
  final DateTime createdAt;
  final int colorIndex;

  const Companion({
    required this.id,
    required this.name,
    required this.createdAt,
    this.colorIndex = 0,
  });

  static const String defaultId = 'general';

  static Companion defaultCompanion = Companion(
    id: defaultId,
    name: 'General',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    colorIndex: 0,
  );

  bool get isDefault => id == defaultId;

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  Companion copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    int? colorIndex,
  }) {
    return Companion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'colorIndex': colorIndex,
    };
  }

  factory Companion.fromJson(Map<String, dynamic> json) {
    return Companion(
      id: json['id'] as String? ?? defaultId,
      name: json['name'] as String? ?? 'Friend',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Companion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
